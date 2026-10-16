import XCTest
@testable import AutoLinkyCore

private final class StubProtocol: URLProtocol {
    static var handler: ((URLRequest) async throws -> (Int, Data))?
    private var work: Task<Void, Never>?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        work = Task {
            do { let result = try await Self.handler!(request); try Task.checkCancellation(); client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: result.0, httpVersion: nil, headerFields: [:])!, cacheStoragePolicy: .notAllowed); client?.urlProtocol(self, didLoad: result.1); client?.urlProtocolDidFinishLoading(self) }
            catch { client?.urlProtocol(self, didFailWithError: error) }
        }
    }
    override func stopLoading() { work?.cancel() }
}
private actor SessionState {
    var uid = "A"
    var refreshes = 0
    var fresh = false
    func identity() -> String? { uid }
    func switchUser() { uid = "B" }
    func token(_ force: Bool) async -> SessionCredential { if force { refreshes += 1; try? await Task.sleep(for: .milliseconds(20)); fresh = true }; return SessionCredential(uid: uid, token: fresh ? "fresh" : "old") }
    func count() -> Int { refreshes }
}
final class NetworkingTests: XCTestCase {
    private func api(_ state: SessionState, owner: String = "A") -> APIClient {
        let configuration = URLSessionConfiguration.ephemeral; configuration.protocolClasses = [StubProtocol.self]
        return APIClient(base: URL(string: "https://api.example.com")!, version: "1.1.0+2000", owner: owner, session: URLSession(configuration: configuration), credential: { await state.token($0) }, identity: { await state.identity() })
    }
    func testExplicit401RefreshesOnceAndPreservesRequestBody() async throws {
        let state = SessionState(); var requests = 0
        StubProtocol.handler = { request in
            requests += 1
            XCTAssertEqual(request.httpMethod, "POST")
            let body: Data
            if let bytes = request.httpBody { body = bytes }
            else if let stream = request.httpBodyStream {
                stream.open(); defer { stream.close() }; var bytes = [UInt8](repeating: 0, count: 1024); var output = Data()
                while stream.hasBytesAvailable { let read = stream.read(&bytes, maxLength: bytes.count); if read <= 0 { break }; output.append(contentsOf: bytes.prefix(read)) }; body = output
            } else { body = Data() }
            XCTAssertEqual((try? JSONDecoder().decode(JSON.self, from: body))?["job_id"].text, "id")
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-Autolinky-Client-Version"), "1.1.0+2000")
            return (request.value(forHTTPHeaderField: "Authorization") == "Bearer fresh" ? 201 : 401, Data(#"{"status":"queued"}"#.utf8))
        }
        let result = try await api(state).request("/v1/applications", method: "POST", json: .object(["job_id": .string("id")]))
        XCTAssertEqual(result["status"].text, "queued"); XCTAssertEqual(requests, 2)
        let count = await state.count(); XCTAssertEqual(count, 1)
    }
    func testTransportUncertaintyIsNeverAutomaticallyResubmitted() async {
        let state = SessionState(); var requests = 0
        StubProtocol.handler = { _ in requests += 1; throw URLError(.networkConnectionLost) }
        do { _ = try await api(state).request("/v1/applications", method: "POST"); XCTFail("Expected uncertainty") } catch { }
        XCTAssertEqual(requests, 1); let count = await state.count(); XCTAssertEqual(count, 0)
    }
    func testOldClientCannotSendAfterAccountSwitch() async {
        let state = SessionState(); let client = api(state); await state.switchUser()
        var requests = 0; StubProtocol.handler = { _ in requests += 1; return (200, Data("{}".utf8)) }
        do { _ = try await client.request("/v1/me", method: "DELETE"); XCTFail("Old account scope accepted") } catch let e as APIError { XCTAssertEqual(e.status, 401) } catch { XCTFail("Wrong error") }
        XCTAssertEqual(requests, 0)
    }
    func testResponseFromOldAccountIsDiscarded() async {
        let state = SessionState(); let client = api(state)
        StubProtocol.handler = { _ in await state.switchUser(); return (200, Data(#"{"private":"old-user-data"}"#.utf8)) }
        do { _ = try await client.request("/v1/profile"); XCTFail("Stale private response accepted") } catch let e as APIError { XCTAssertEqual(e.status, 401) } catch { XCTFail("Wrong error") }
    }
    func testConcurrent401ResponsesShareTokenRefresh() async throws {
        let state = SessionState(); let client = api(state)
        StubProtocol.handler = { request in (request.value(forHTTPHeaderField: "Authorization") == "Bearer fresh" ? 200 : 401, Data("{}".utf8)) }
        async let one = client.request("/v1/me")
        async let two = client.request("/v1/profile")
        _ = try await (one, two)
        let count = await state.count(); XCTAssertEqual(count, 1)
    }
    func testSecond401StopsAnd503IsNotRetried() async {
        for status in [401, 503] {
            let state = SessionState(); var requests = 0
            StubProtocol.handler = { _ in requests += 1; return (status, Data(#"{"detail":"service_unavailable","request_id":"trace"}"#.utf8)) }
            do { _ = try await api(state).request("/v1/me"); XCTFail("Expected refusal") } catch let e as APIError { XCTAssertEqual(e.status, status); XCTAssertEqual(e.requestID, "trace") } catch { XCTFail("Wrong error") }
            XCTAssertEqual(requests, status == 401 ? 2 : 1)
        }
    }
}

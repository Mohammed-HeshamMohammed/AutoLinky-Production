#if DEBUG
// Simulator UI test transport. This entire file is excluded by Release compilation.
import Foundation
import AutoLinkyCore
enum DebugFixtures {
    static var enabled: Bool { ProcessInfo.processInfo.environment["AUTOLINKY_UI_TEST"] == "1" }
    static func session() -> URLSession { let config = URLSessionConfiguration.ephemeral; config.protocolClasses = [FixtureProtocol.self]; return URLSession(configuration: config) }
}
private final class FixtureProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { request.url?.host == "native-fixture.invalid" }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let job: JSON = .object(["id": .string("00000000-0000-4000-8000-000000000001"), "title": .string("UI test opportunity"), "company": .string("Test fixture"), "city": .string("Cairo"), "country": .string("Egypt"), "apply_methods": .strings(["link"]), "url": .string("https://example.com/job"), "description": .string("Deterministic simulator fixture. No collection or mail is performed."), "skills": .strings(["swift"]), "match_percent": .number(85)])
        let result: JSON
        switch request.url?.path {
        case "/v1/me": result = .object(["user_id": .string("fixture-user"), "email": .string("ui-test@example.com")])
        case "/v1/profile": result = .object(["headline": .string("UI test profile"), "search_scope": .string("egypt"), "skills": .strings(["swift"]), "languages": .strings(["en", "ar"])])
        case "/v1/cv": result = .object(["cv": .null])
        case "/v1/taxonomy": result = .object(["roles": .array([]), "fields": .array([]), "skills": .array([])])
        case "/v1/auto-apply": result = .object(["enabled": .bool(false), "email_connected": .bool(false), "plan": .string("free"), "min_match": .number(70), "daily_limit": .number(20), "gap_minutes": .number(5)])
        case "/v1/jobs/matched", "/v1/jobs": result = .object(["items": .array([job]), "next_cursor": .null])
        case "/v1/applications": result = .object(["items": .array([]), "next_cursor": .null])
        default: result = request.url?.path.hasPrefix("/v1/jobs/") == true ? job : .object([:])
        }
        client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: (try? JSONEncoder().encode(result)) ?? Data())
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
#endif

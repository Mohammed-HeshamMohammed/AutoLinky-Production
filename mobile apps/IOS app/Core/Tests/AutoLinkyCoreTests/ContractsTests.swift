import XCTest
@testable import AutoLinkyCore

final class ContractsTests: XCTestCase {
    func testAPIOriginAndPathPreventTokenExfiltration() throws {
        for bad in ["http://api.example.com", "https://u:p@api.example.com", "https://api.example.com?q=1", "file:///tmp/file", "//evil.test"] { XCTAssertNil(Security.apiBase(bad)) }
        XCTAssertNotNil(Security.apiBase("http://localhost:4100", allowLocal: true))
        XCTAssertNil(Security.apiBase("http://192.168.1.2:4100", allowLocal: true))
        let base = try XCTUnwrap(Security.apiBase("https://api.example.com/root"))
        for bad in ["https://evil.test/v1/me", "/v1/../me", "/v1/%2e%2e/me", "/v1/me?secret=1"] { XCTAssertThrowsError(try Security.endpoint(base: base, path: bad)) }
        let url = try Security.endpoint(base: base, path: "/v1/jobs", query: [URLQueryItem(name: "cursor", value: "a+b/= العربية")])
        XCTAssertEqual(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first?.value, "a+b/= العربية")
        XCTAssertEqual(url.path, "/root/v1/jobs")
    }
    func testDTOUnknownFieldsNullAndMicrosecondCursorSurvive() throws {
        let raw = try JSONDecoder().decode(JSON.self, from: Data(#"{"items":[{"id":"id","title":"Developer","company":null,"match_percent":120,"application":{"status":"queued"}}],"next_cursor":"2026-10-16T00:00:00.123456+00:00|id"}"#.utf8))
        let page = JobPage(raw)
        XCTAssertEqual(page.jobs.first?.matchPercent, 100)
        XCTAssertEqual(page.jobs.first?.company, "")
        XCTAssertEqual(page.jobs.first?.application["status"].text, "queued")
        XCTAssertEqual(page.cursor, "2026-10-16T00:00:00.123456+00:00|id")
        XCTAssertEqual(try JSONDecoder().decode(JSON.self, from: JSONEncoder().encode(raw)), raw)
    }
    func testCVLimitsAndExternalSchemes() throws {
        XCTAssertEqual(try CVUpload.contentType(name: "CV.PDF", bytes: CVUpload.maximumBytes), "application/pdf")
        for (name, size) in [("cv.pdf", 0), ("cv.pdf", CVUpload.maximumBytes + 1), ("cv.exe", 12)] { XCTAssertThrowsError(try CVUpload.contentType(name: name, bytes: size)) }
        XCTAssertNil(Security.webURL("javascript:alert(1)")); XCTAssertNil(Security.webURL("https://user:password@example.com"))
        let job = Job(.object(["contacts": .array([.object(["type": .string("whatsapp"), "value": .string("+20 123 456 7890")])])]))
        XCTAssertEqual(job.destination(for: "whatsapp")?.absoluteString, "https://wa.me/201234567890")
    }
    func testReleaseFeedRejectsForeignOrIncompleteArtifacts() {
        let source = ReleaseSource(repository: "owner/repo", channel: "development")
        XCTAssertNil(source.trustedAsset("https://evil.test/owner/repo/releases/download/v1/a.ipa"))
        XCTAssertNil(source.trustedAsset("https://github.com/other/repo/releases/download/v1/a.ipa"))
        XCTAssertNil(BinaryRelease(manifest: .object([:]), assetURL: "https://github.com/owner/repo/releases/download/v1/a.ipa", source: source, platform: "ios"))
    }
}

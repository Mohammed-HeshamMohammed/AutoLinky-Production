import Foundation

public enum Security {
    public static func apiBase(_ text: String, allowLocal: Bool = false) -> URL? {
        guard let c = URLComponents(string: text.trimmingCharacters(in: .whitespacesAndNewlines)),
              let host = c.host, !host.isEmpty, c.user == nil, c.password == nil, c.query == nil, c.fragment == nil,
              c.scheme == "https" || (allowLocal && c.scheme == "http" && ["localhost", "127.0.0.1", "::1"].contains(host)) else { return nil }
        return c.url
    }
    public static func webURL(_ text: String) -> URL? {
        guard let c = URLComponents(string: text), ["https", "http"].contains(c.scheme ?? ""), c.host?.isEmpty == false, c.user == nil, c.password == nil else { return nil }
        return c.url
    }
    public static func endpoint(base: URL, path: String, query: [URLQueryItem] = []) throws -> URL {
        guard path.hasPrefix("/v1/"), !path.contains(".."), !path.contains("?"), !path.contains("#"), !path.contains("%"), !path.contains("\\") else { throw APIError(status: 0, code: "invalid_endpoint") }
        guard var c = URLComponents(url: base, resolvingAgainstBaseURL: false) else { throw APIError(status: 0, code: "invalid_api") }
        c.path = c.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).isEmpty ? path : c.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).withLeadingSlash + path
        c.queryItems = query.isEmpty ? nil : query
        guard let result = c.url else { throw APIError(status: 0, code: "invalid_endpoint") }
        return result
    }
}
private extension String { var withLeadingSlash: String { "/" + self } }

public struct ReleaseSource: Codable, Sendable, Equatable {
    public let repository: String
    public let channel: String
    public let manifest: String
    public init(repository: String, channel: String, manifest: String = "autolinky-release.json") { self.repository = repository; self.channel = channel; self.manifest = manifest }
    public var feedURL: URL { URL(string: "https://api.github.com/repos/\(repository)/releases?per_page=10")! }
    public func trustedAsset(_ text: String) -> URL? {
        guard let url = Security.webURL(text), url.scheme == "https", url.host == "github.com", url.path.hasPrefix("/\(repository)/releases/download/") else { return nil }; return url
    }
}

public struct BinaryRelease: Sendable {
    public let version: String
    public let build: Int
    public let downloadURL: URL
    public let sha256: String
    public init?(manifest: JSON, assetURL: String, source: ReleaseSource, platform: String) {
        let artifact = manifest["artifacts"][platform]
        guard manifest["repository"].text == source.repository, manifest["channel"].text == source.channel,
              manifest["build_number"].integer > 0,
              let url = source.trustedAsset(assetURL), url.lastPathComponent == artifact["file"].text,
              artifact["sha256"].text.range(of: "^[a-f0-9]{64}$", options: .regularExpression) != nil else { return nil }
        version = manifest["version"].text; build = manifest["build_number"].integer; downloadURL = url; sha256 = artifact["sha256"].text
    }
}

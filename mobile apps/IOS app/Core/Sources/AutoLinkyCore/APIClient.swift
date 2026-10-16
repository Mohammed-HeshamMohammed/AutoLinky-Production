import Foundation

public struct SessionCredential: Sendable {
    public let uid: String
    public let token: String
    public init(uid: String, token: String) { self.uid = uid; self.token = token }
}

/// One authenticated origin. Retries only an explicit 401, never transport/SMTP uncertainty.
public actor APIClient {
    private let base: URL
    private let session: URLSession
    private let credential: @Sendable (Bool) async throws -> SessionCredential
    private let identity: @Sendable () async -> String?
    private var refresh: (String, Task<SessionCredential, Error>)?
    private let version: String
    private let owner: String?
    public init(base: URL, version: String, owner: String? = nil, session: URLSession = .shared,
                credential: @escaping @Sendable (Bool) async throws -> SessionCredential,
                identity: @escaping @Sendable () async -> String?) {
        self.base = base; self.version = version; self.owner = owner; self.session = session; self.credential = credential; self.identity = identity
    }
    private func refreshed(_ uid: String, rejectedToken: String) async throws -> SessionCredential {
        let current = try await credential(false)
        guard current.uid == uid else { throw APIError(status: 401, code: "session_expired") }
        if current.token != rejectedToken { return current }
        if let pending = refresh, pending.0 == uid { return try await pending.1.value }
        let task = Task { try await credential(true) }; refresh = (uid, task)
        defer { refresh = nil }
        return try await task.value
    }
    public func request(_ path: String, method: String = "GET", json: JSON? = nil, data: Data? = nil, type: String = "application/json", query: [URLQueryItem] = []) async throws -> JSON {
        try Task.checkCancellation()
        let initial = try await credential(false)
        guard (owner == nil || owner == initial.uid), await identity() == initial.uid else { throw APIError(status: 401, code: "session_expired") }
        var request = URLRequest(url: try Security.endpoint(base: base, path: path, query: query), cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 90)
        request.httpMethod = method
        request.httpBody = try data ?? json.map { try JSONEncoder().encode($0) }
        request.setValue(type, forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(version, forHTTPHeaderField: "X-Autolinky-Client-Version")
        var token = initial
        for attempt in 0...1 {
            try Task.checkCancellation()
            guard token.uid == initial.uid, await identity() == initial.uid else { throw APIError(status: 401, code: "session_expired") }
            request.setValue("Bearer \(token.token)", forHTTPHeaderField: "Authorization")
            let (bytes, response) = try await session.data(for: request)
            guard await identity() == initial.uid else { throw APIError(status: 401, code: "session_expired") }
            guard let http = response as? HTTPURLResponse, bytes.count <= 16 * 1024 * 1024 else { throw APIError(status: 0, code: "invalid_response") }
            if http.statusCode == 401 && attempt == 0 { token = try await refreshed(initial.uid, rejectedToken: token.token); continue }
            let body = bytes.isEmpty ? JSON.null : (try? JSONDecoder().decode(JSON.self, from: bytes)) ?? .null
            guard (200...299).contains(http.statusCode) else {
                let detail = body["detail"]
                throw APIError(status: http.statusCode, code: detail.text.isEmpty ? (detail["code"].text.isEmpty ? "request_failed" : detail["code"].text) : detail.text,
                               requestID: body["request_id"].text.isEmpty ? nil : body["request_id"].text, retryAfter: Int(http.value(forHTTPHeaderField: "Retry-After") ?? ""))
            }
            if !bytes.isEmpty && body.isNull { throw APIError(status: 0, code: "invalid_response") }
            return body
        }
        throw APIError(status: 401, code: "session_expired")
    }
}

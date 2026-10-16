import SwiftUI
import AutoLinkyCore

@MainActor final class AppStore: ObservableObject {
    let auth: Authentication
    let api: APIClient
    @Published var profile: JSON = .null
    @Published var cv: JSON = .null
    @Published var account: JSON = .null
    @Published var taxonomy: JSON = .null
    @Published var autoApply: JSON = .null
    @Published var searchStatus: JSON = .null
    @Published var error: String?
    @Published var loading = true
    @Published var working = false
    @Published var showOnboarding = false
    @Published var revision = 0
    private let owner: String
    init(auth: Authentication, api: APIClient? = nil, owner: String) {
        self.auth = auth; self.owner = owner
        var session = IsolatedSession.make()
        #if DEBUG
        if DebugFixtures.enabled { session = DebugFixtures.session() }
        #endif
        self.api = api ?? APIClient(base: auth.configuration.api!, version: "\(auth.configuration.version)+\(auth.configuration.build)", owner: owner, session: session, credential: { [weak auth] refresh in
            guard let auth else { throw APIError(status: 401, code: "session_expired") }; return try await auth.credential(refresh: refresh)
        }, identity: { [weak auth] in await auth?.uid })
    }
    func load() async {
        loading = true
        defer { loading = false }
        await perform {
            let me = try await self.api.request("/v1/me")
            async let profile = self.optional("/v1/profile")
            async let cv = self.optional("/v1/cv")
            async let tax = self.api.request("/v1/taxonomy")
            async let auto = self.api.request("/v1/auto-apply")
            let data = try await (profile, cv, tax, auto)
            try self.validateOwner()
            self.account = me; self.profile = data.0; self.cv = data.1["cv"]; self.taxonomy = data.2; self.autoApply = data.3
            self.showOnboarding = self.profile["search_scope"].text.isEmpty
        }
    }
    func validateOwner() throws {
        try Task.checkCancellation()
        guard auth.uid == owner else { throw APIError(status: 401, code: "session_expired") }
    }
    func optional(_ path: String) async throws -> JSON {
        do { return try await api.request(path) } catch let e as APIError where e.status == 404 { return .null }
    }
    func perform(_ operation: () async throws -> Void) async {
        do { try await operation() } catch is CancellationError { } catch {
            guard auth.uid == owner else { return }
            if let failure = error as? APIError, failure.status == 401 { try? auth.signOut(); return }
            self.error = Self.message(error)
        }
    }
    static func message(_ error: Error) -> String {
        if let e = error as? APIError {
            if e.status == 429 { return "rate_limited" }; if e.status >= 500 { return "service_unavailable" }; if e.status == 403 { return "account_blocked" }
            let known = Set(["cv_empty", "cv_too_large", "cv_bad_type", "cv_unreadable", "cv_needed", "email_not_connected", "email_invalid", "free_limit", "gmail_limit", "gmail_busy", "sender_offline", "gmail_not_account", "wrong_app_password", "not_app_password", "invalid_app_password", "app_password_needed", "invalid_address", "invalid_name", "unknown_values", "mail_unavailable", "already_sent", "secure_storage", "invalid_link", "google_configuration", "email_configuration", "sign_in_failed", "session_expired", "apple_reauthentication", "notification_permission"])
            return known.contains(e.code) ? e.code : "request_failed"
        }
        if let error = error as? URLError { return error.code == .timedOut ? "request_timeout" : "network_error" }
        let code = (error as NSError).code
        return [17014].contains(code) ? "reauthentication" : "request_failed"
    }
    func saveProfile(_ fields: [String: JSON]) async throws {
        let result = try await api.request("/v1/profile", method: "PUT", json: .object(fields))
        try validateOwner(); profile = result; showOnboarding = false; revision += 1
        searchStatus = try await api.request("/v1/profile/search-now", method: "POST")
    }
    func upload(_ url: URL) async throws {
        let scoped = url.startAccessingSecurityScopedResource(); defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let attributes = try url.resourceValues(forKeys: [.fileSizeKey])
        let type = try CVUpload.contentType(name: url.lastPathComponent, bytes: attributes.fileSize ?? 0)
        let bytes = try Data(contentsOf: url, options: .mappedIfSafe)
        _ = try CVUpload.contentType(name: url.lastPathComponent, bytes: bytes.count)
        let result = try await api.request("/v1/cv", method: "POST", data: bytes, type: type, query: [.init(name: "name", value: url.lastPathComponent)])
        try validateOwner(); cv = result["cv"]; profile = result["profile"]; revision += 1
    }
    func reanalyze() async throws {
        let result = try await api.request("/v1/cv/reanalyze", method: "POST")
        try validateOwner(); cv = result["cv"]; profile = result["profile"]; revision += 1
    }
    func refreshAuto() async throws { let result = try await api.request("/v1/auto-apply"); try validateOwner(); autoApply = result }
    func setAuto(_ fields: [String: JSON]) async throws { let result = try await api.request("/v1/auto-apply", method: "PUT", json: .object(fields)); try validateOwner(); autoApply = result }
}

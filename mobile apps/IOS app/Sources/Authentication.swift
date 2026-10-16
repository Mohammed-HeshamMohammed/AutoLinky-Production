import SwiftUI
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import AuthenticationServices
import CryptoKit
import Security
import AutoLinkyCore

enum Keychain {
    static func read(_ key: String) -> String? {
        var output: CFTypeRef?
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "com.autolinky.ios", kSecAttrAccount as String: key, kSecReturnData as String: true]
        guard SecItemCopyMatching(query as CFDictionary, &output) == errSecSuccess, let data = output as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    static func save(_ key: String, _ value: String?) throws {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "com.autolinky.ios", kSecAttrAccount as String: key]
        SecItemDelete(query as CFDictionary)
        if let value {
            var item = query; item[kSecValueData as String] = Data(value.utf8); item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else { throw APIError(status: 0, code: "secure_storage") }
        }
    }
}

@MainActor final class Authentication: ObservableObject {
    @Published private(set) var uid: String?
    @Published private(set) var email: String = ""
    @Published var busy = false
    @Published var message: String?
    @Published var incomingLink: String?
    private var listener: AuthStateDidChangeListenerHandle?
    private var nonce: String?
    let configuration: Configuration
    init(configuration: Configuration) {
        self.configuration = configuration
        #if DEBUG
        if DebugFixtures.enabled { uid = "fixture-user"; email = "ui-test@example.com"; return }
        #endif
        listener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in self?.uid = user?.uid; self?.email = user?.email ?? "" }
        }
    }
    func credential(refresh: Bool) async throws -> SessionCredential {
        #if DEBUG
        if DebugFixtures.enabled { return SessionCredential(uid: "fixture-user", token: "fixture-token") }
        #endif
        guard let user = Auth.auth().currentUser else { throw APIError(status: 401, code: "session_expired") }
        let uid = user.uid
        let token = try await user.getIDTokenForcingRefresh(refresh)
        guard Auth.auth().currentUser?.uid == uid else { throw APIError(status: 401, code: "session_expired") }
        return SessionCredential(uid: uid, token: token)
    }
    func signOut() throws {
        GIDSignIn.sharedInstance.signOut()
        try Auth.auth().signOut()
        try Keychain.save("pending-email", nil)
        incomingLink = nil; appleAuthorizationCode = nil; uid = nil; email = ""
    }
    func google() async throws {
        guard configuration.googleEnabled, let window = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).flatMap(\.windows).first(where: \.isKeyWindow), var presenter = window.rootViewController else { throw APIError(status: 0, code: "google_configuration") }
        while let presented = presenter.presentedViewController { presenter = presented }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: configuration.googleID, serverClientID: configuration.values["GOOGLE_WEB_CLIENT_ID"].flatMap { $0.isEmpty ? nil : $0 })
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
        guard let id = result.user.idToken?.tokenString else { throw APIError(status: 0, code: "sign_in_failed") }
        let credential = GoogleAuthProvider.credential(withIDToken: id, accessToken: result.user.accessToken.tokenString)
        if let user = Auth.auth().currentUser { _ = try await user.reauthenticate(with: credential) }
        else { _ = try await Auth.auth().signIn(with: credential) }
    }
    func appleRequest(_ request: ASAuthorizationAppleIDRequest) {
        var bytes = [UInt8](repeating: 0, count: 32)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else { message = "secure_storage"; return }
        let raw = bytes.map { String(format: "%02x", $0) }.joined(); nonce = raw
        request.requestedScopes = [.fullName, .email]
        request.nonce = SHA256.hash(data: Data(raw.utf8)).map { String(format: "%02x", $0) }.joined()
    }
    func appleComplete(_ result: Result<ASAuthorization, Error>) async throws {
        defer { nonce = nil }
        guard let credential = try result.get().credential as? ASAuthorizationAppleIDCredential, let raw = nonce,
              let data = credential.identityToken, let token = String(data: data, encoding: .utf8) else { throw APIError(status: 0, code: "sign_in_failed") }
        let firebase = OAuthProvider.appleCredential(withIDToken: token, rawNonce: raw, fullName: credential.fullName)
        if let user = Auth.auth().currentUser { _ = try await user.reauthenticate(with: firebase) }
        else { _ = try await Auth.auth().signIn(with: firebase) }
        if let code = credential.authorizationCode.flatMap({ String(data: $0, encoding: .utf8) }) {
            // Retain only in memory for the immediate account-deletion/revocation flow.
            appleAuthorizationCode = code
        }
    }
    private(set) var appleAuthorizationCode: String?
    func revokeApple() async throws {
        guard Auth.auth().currentUser?.providerData.contains(where: { $0.providerID == "apple.com" }) == true else { return }
        guard let code = appleAuthorizationCode else { throw APIError(status: 0, code: "apple_reauthentication") }
        try await Auth.auth().revokeToken(withAuthorizationCode: code)
        appleAuthorizationCode = nil
    }
    func sendEmail(_ email: String) async throws {
        guard configuration.emailEnabled else { throw APIError(status: 0, code: "email_configuration") }
        let settings = ActionCodeSettings()
        settings.url = URL(string: configuration.values["EMAIL_LINK_CONTINUE_URL"] ?? "")
        settings.handleCodeInApp = true; settings.setIOSBundleID("com.autolinky.ios")
        if let host = configuration.values["EMAIL_LINK_CUSTOM_DOMAIN"], !host.isEmpty { settings.linkDomain = host }
        try await Auth.auth().sendSignInLink(toEmail: email, actionCodeSettings: settings)
        try Keychain.save("pending-email", email)
    }
    func receive(_ url: URL) {
        if GIDSignIn.sharedInstance.handle(url) { return }
        if Auth.auth().isSignIn(withEmailLink: url.absoluteString) { incomingLink = url.absoluteString }
    }
    func completeEmail(_ email: String) async throws {
        guard let link = incomingLink, Auth.auth().isSignIn(withEmailLink: link) else { throw APIError(status: 0, code: "invalid_link") }
        if let user = Auth.auth().currentUser {
            _ = try await user.reauthenticate(with: EmailAuthProvider.credential(withEmail: email, link: link))
        } else { _ = try await Auth.auth().signIn(withEmail: email, link: link) }
        incomingLink = nil; try Keychain.save("pending-email", nil)
    }
}

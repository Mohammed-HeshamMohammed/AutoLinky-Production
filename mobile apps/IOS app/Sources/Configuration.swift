import Foundation
import AutoLinkyCore

struct Configuration {
    let values: [String: String]
    init(bundle: Bundle = .main) {
        let data = bundle.url(forResource: "PublicSettings", withExtension: "json").flatMap { try? Data(contentsOf: $0) }
        values = data.flatMap { try? JSONDecoder().decode([String: String].self, from: $0) } ?? [:]
    }
    var version: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "" }
    var build: Int { Int(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "") ?? 0 }
    var configuredAPI: String { UserDefaults.standard.string(forKey: "development.api") ?? values["API_BASE_URL"] ?? "" }
    var api: URL? {
        #if targetEnvironment(simulator) && DEBUG
        return Security.apiBase(configuredAPI, allowLocal: true)
        #else
        return Security.apiBase(configuredAPI)
        #endif
    }
    var emailEnabled: Bool { values["EMAIL_SIGN_IN"] == "true" && Security.webURL(values["EMAIL_LINK_CONTINUE_URL"] ?? "")?.scheme == "https" }
    var appleEnabled: Bool { values["APPLE_SIGN_IN"] == "true" }
    var googleID: String { values["GOOGLE_IOS_CLIENT_ID"] ?? "" }
    var googleEnabled: Bool { !googleID.isEmpty }
    func legal(_ page: String) -> URL { Security.webURL(values[page == "privacy" ? "PRIVACY_URL" : "TERMS_URL"] ?? "") ?? URL(string: "https://auto-linky.com/\(page)/")! }
}

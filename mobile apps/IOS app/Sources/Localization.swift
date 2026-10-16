import Foundation
func t(_ key: String) -> String {
    let language = UserDefaults.standard.string(forKey: "language") ?? (Locale.current.language.languageCode?.identifier == "ar" ? "ar" : "en")
    guard let path = Bundle.main.path(forResource: language, ofType: "lproj"), let bundle = Bundle(path: path) else { return key }
    return bundle.localizedString(forKey: key, value: key, table: nil)
}

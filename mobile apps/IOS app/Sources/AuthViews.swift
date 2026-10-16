import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @EnvironmentObject private var auth: Authentication
    @State private var emailSheet = false
    @State private var error: String?
    @State private var busy = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    BrandMark().padding(.top, 48)
                    Text(t("Your next opportunity starts here.")).font(.largeTitle.bold()).multilineTextAlignment(.center)
                    Text(t("Find jobs matched to your skills. Keep your CV and applications together.")).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    VStack(spacing: 14) {
                        if auth.configuration.googleEnabled { Button { run { try await auth.google() } } label: { Label(t("Continue with Google"), systemImage: "person.crop.circle.badge.checkmark").frame(maxWidth: .infinity) }.buttonStyle(.borderedProminent).controlSize(.large) }
                        if auth.configuration.appleEnabled {
                            SignInWithAppleButton(.continue, onRequest: auth.appleRequest) { result in run { try await auth.appleComplete(result) } }.frame(height: 50).clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        if auth.configuration.emailEnabled { Button(t("Continue with email")) { emailSheet = true }.buttonStyle(.bordered).controlSize(.large) }
                        if !auth.configuration.googleEnabled && !auth.configuration.appleEnabled && !auth.configuration.emailEnabled { Text(t("Sign-in providers are awaiting configuration for this development build.")).foregroundStyle(.secondary) }
                        if busy { ProgressView() }
                    }.disabled(busy)
                    HStack {
                        if let terms = auth.configuration.legal("terms") { Link(t("Terms"), destination: terms) }
                        if let privacy = auth.configuration.legal("privacy") { Link(t("Privacy"), destination: privacy) }
                    }.font(.footnote)
                    LanguagePicker().padding(.top)
                }.padding(28).frame(maxWidth: 560).frame(maxWidth: .infinity)
            }.navigationTitle("AutoLinky").navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $emailSheet) { EmailSignInView(completing: false) }
        .alert(t("Sign in"), isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button(t("OK")) { error = nil } } message: { Text(t(error ?? "request_failed")) }
    }
    private func run(_ operation: @escaping () async throws -> Void) {
        busy = true; Task { defer { busy = false }; do { try await operation() } catch { self.error = AppStore.message(error) } }
    }
}

struct EmailSignInView: View {
    @EnvironmentObject private var auth: Authentication
    @Environment(\.dismiss) private var dismiss
    let completing: Bool
    @State private var email = Keychain.read("pending-email") ?? ""
    @State private var busy = false
    @State private var sent = false
    @State private var error: String?
    var body: some View {
        NavigationStack {
            Form {
                Section { Text(t(completing ? "Confirm your email to finish signing in." : "We’ll send a secure sign-in link to your email.")); TextField(t("Email address"), text: $email).textContentType(.emailAddress).keyboardType(.emailAddress).textInputAutocapitalization(.never).autocorrectionDisabled() }
                if sent { Section { Label(t("Check your inbox and open the link on this iPhone."), systemImage: "envelope.badge") } }
                if let error { Section { Text(t(error)).foregroundStyle(.red) } }
                Button(t(completing ? "Sign in" : sent ? "Send again" : "Send sign-in link")) {
                    busy = true; Task { defer { busy = false }; do { if completing { try await auth.completeEmail(email); dismiss() } else { try await auth.sendEmail(email); sent = true } } catch { self.error = AppStore.message(error) } }
                }.disabled(busy || !email.contains("@"))
                if busy { ProgressView() }
            }.navigationTitle(t("Email sign-in")).toolbar { ToolbarItem(placement: .cancellationAction) { Button(t("Close")) { dismiss() } } }
        }
    }
}

struct LanguagePicker: View {
    @AppStorage("language") private var language = Locale.current.language.languageCode?.identifier == "ar" ? "ar" : "en"
    var body: some View { Picker(t("Language"), selection: $language) { Text("English").tag("en"); Text("العربية").tag("ar") }.accessibilityIdentifier("languagePicker") }
}

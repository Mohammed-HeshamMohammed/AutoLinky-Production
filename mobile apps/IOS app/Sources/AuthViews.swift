import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @EnvironmentObject private var auth: Authentication
    @State private var emailSheet = false
    @State private var error: String?
    @State private var busy = false
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    BrandWordmark().frame(maxWidth: .infinity, alignment: .leading).padding(.top, 24).padding(.bottom, 24)
                    BrandPageHeading(eyebrow: "Find your next opportunity", title: "Your next opportunity starts here.", subtitle: "Find jobs matched to your skills. Keep your CV and applications together.")
                    BrandRule()
                    VStack(spacing: 0) {
                        welcomeStep("01", "Your CV", "Start with your CV, then review the profile it creates.")
                        BrandRule()
                        welcomeStep("02", "For you", "Find jobs matched to your skills.")
                        BrandRule()
                        welcomeStep("03", "Applications", "Your tracked and emailed applications will appear here.")
                    }
                    VStack(spacing: 12) {
                        if auth.configuration.googleEnabled { Button { run { try await auth.google() } } label: { Text(t("Continue with Google")) }.buttonStyle(BrandPrimaryButtonStyle()) }
                        if auth.configuration.appleEnabled {
                            SignInWithAppleButton(.continue, onRequest: auth.appleRequest) { result in run { try await auth.appleComplete(result) } }
                                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                                .frame(height: 54).clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        if auth.configuration.emailEnabled { Button(t("Continue with email")) { emailSheet = true }.buttonStyle(BrandOutlineButtonStyle()) }
                        if !auth.configuration.googleEnabled && !auth.configuration.appleEnabled && !auth.configuration.emailEnabled { Text(t("Sign-in providers are awaiting configuration for this development build.")).foregroundStyle(BrandColors.muted) }
                        if busy { ProgressView() }
                    }.disabled(busy)
                    HStack(spacing: 24) {
                        if let terms = auth.configuration.legal("terms") { Link(t("Terms"), destination: terms) }
                        if let privacy = auth.configuration.legal("privacy") { Link(t("Privacy"), destination: privacy) }
                        Spacer()
                    }.font(.caption).foregroundStyle(BrandColors.muted)
                    BrandRule()
                    LanguagePicker().pickerStyle(.menu)
                }.padding(.horizontal, 28).padding(.bottom, 32).frame(maxWidth: 560).frame(maxWidth: .infinity)
            }.brandSurface().navigationBarTitleDisplayMode(.inline).toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $emailSheet) { EmailSignInView(completing: false) }
        .alert(t("Sign in"), isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button(t("OK")) { error = nil } } message: { Text(t(error ?? "request_failed")) }
    }
    private func welcomeStep(_ number: String, _ title: String, _ subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 20) {
            Text(number).font(.caption.monospacedDigit()).foregroundStyle(BrandColors.primary).padding(.top, 3)
            VStack(alignment: .leading, spacing: 6) {
                Text(t(title)).font(.subheadline.weight(.semibold)).foregroundStyle(BrandColors.text)
                Text(t(subtitle)).font(.caption).lineSpacing(3).foregroundStyle(BrandColors.muted)
            }
        }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 20)
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
            BrandForm {
                BrandPageHeading(eyebrow: "AutoLinky", title: "Email sign-in", subtitle: completing ? "Confirm your email to finish signing in." : "We’ll send a secure sign-in link to your email.")
                    .listRowSeparator(.hidden)
                Section { TextField(t("Email address"), text: $email).textContentType(.emailAddress).keyboardType(.emailAddress).textInputAutocapitalization(.never).autocorrectionDisabled().padding(.vertical, 6) }
                if sent { Section { Text(t("Check your inbox and open the link on this iPhone.")).foregroundStyle(BrandColors.success).lineSpacing(4) } }
                if let error { Section { Text(t(error)).foregroundStyle(BrandColors.error) } }
                Button(t(completing ? "Sign in" : sent ? "Send again" : "Send sign-in link")) {
                    busy = true; Task { defer { busy = false }; do { if completing { try await auth.completeEmail(email); dismiss() } else { try await auth.sendEmail(email); sent = true } } catch { self.error = AppStore.message(error) } }
                }.buttonStyle(BrandPrimaryButtonStyle()).listRowSeparator(.hidden).disabled(busy || !email.contains("@"))
                if busy { ProgressView() }
            }.navigationTitle(t("Email sign-in")).toolbar { ToolbarItem(placement: .cancellationAction) { Button(t("Close")) { dismiss() } } }
        }
    }
}

struct LanguagePicker: View {
    @AppStorage("language") private var language = Locale.current.language.languageCode?.identifier == "ar" ? "ar" : "en"
    var body: some View { Picker(t("Language"), selection: $language) { Text("English").tag("en"); Text("العربية").tag("ar") }.accessibilityIdentifier("languagePicker") }
}

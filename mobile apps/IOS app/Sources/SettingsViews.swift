import SwiftUI
import AuthenticationServices
import AutoLinkyCore

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("notifications") private var notifications = false
    @State private var busy = false
    @State private var signOut = false
    var body: some View {
        Form {
            Section(t("Preferences")) {
                LanguagePicker()
                Picker(t("Appearance"), selection: $appearance) { Text(t("System")).tag("system"); Text(t("Light")).tag("light"); Text(t("Dark")).tag("dark") }
                Toggle(t("Activity notifications"), isOn: Binding(get: { notifications }, set: { value in busy = true; Task { defer { busy = false }; await store.perform { if value { try await ActivityNotifications.enable(api: store.api, uid: store.auth.uid ?? ""); notifications = true } else { await ActivityNotifications.disable(api: store.api); notifications = false } } } }))
                Text(t("iOS decides when background checks run. You can always refresh applications in the app.")).font(.footnote).foregroundStyle(.secondary)
            }.disabled(busy)
            Section(t("About")) { LabeledContent(t("Version"), value: "\(store.auth.configuration.version) (\(store.auth.configuration.build))"); NavigationLink(t("Check for updates")) { ReleaseView() }; if let url = store.auth.configuration.legal("terms") { Link(t("Terms"), destination: url) }; if let url = store.auth.configuration.legal("privacy") { Link(t("Privacy"), destination: url) }; if let site = store.auth.configuration.site { Link(t("Open website"), destination: site) } }
            Section(t("Account")) { Button(t("Sign out")) { signOut = true }; NavigationLink { DeleteAccountView() } label: { Text(t("Delete account")).foregroundStyle(.red) } }
            if busy { ProgressView() }
        }.navigationTitle(t("Settings"))
        .confirmationDialog(t("Sign out of this device?"), isPresented: $signOut, titleVisibility: .visible) { Button(t("Sign out")) { busy = true; Task { defer { busy = false }; await ActivityNotifications.disable(api: store.api); notifications = false; await store.perform { try store.auth.signOut() } } } }
    }
}

struct DeleteAccountView: View {
    @EnvironmentObject private var store: AppStore
    @State private var confirmation = ""
    @State private var busy = false
    @State private var emailSheet = false
    var body: some View {
        Form {
            Section { Text(t("Delete account")).font(.title2.bold()); Text(t("This permanently deletes your AutoLinky account, profile, CV and application data. This cannot be undone.")); Text(t("For your security, sign in again before deleting.")) }
            Section(t("Confirm your identity")) {
                if store.auth.configuration.googleEnabled { Button(t("Continue with Google")) { run { try await store.auth.google() } } }
                if store.auth.configuration.appleEnabled { SignInWithAppleButton(.continue, onRequest: store.auth.appleRequest) { result in run { try await store.auth.appleComplete(result) } }.frame(height: 48) }
                if store.auth.configuration.emailEnabled { Button(t("Continue with email")) { emailSheet = true } }
            }
            Section { Text(t("Type DELETE to confirm.")); TextField("DELETE", text: $confirmation).textInputAutocapitalization(.characters).autocorrectionDisabled(); Button(t("Permanently delete account"), role: .destructive) { run {
                try await store.auth.revokeApple()
                _ = try await store.api.request("/v1/me", method: "DELETE")
                await ActivityNotifications.disable(api: nil)
                try store.auth.signOut()
            } }.disabled(confirmation != "DELETE"); if busy { ProgressView() } }
        }.navigationTitle(t("Delete account")).disabled(busy).sheet(isPresented: $emailSheet) { EmailSignInView(completing: false).environmentObject(store.auth) }
    }
    private func run(_ action: @escaping () async throws -> Void) { busy = true; Task { defer { busy = false }; await store.perform(action) } }
}

struct ReleaseView: View {
    @State private var busy = true
    @State private var release: BinaryRelease?
    @State private var error: String?
    var body: some View {
        Form {
            if busy { ProgressView(t("Checking for updates…")) }
            else if let release {
                Section { Text("AutoLinky \(release.version) (\(release.build))").font(.headline); Link(t("Open release download"), destination: release.downloadURL); Text(t("Development iOS packages require signing before installation.")).font(.footnote).foregroundStyle(.secondary) }
            } else { Text(t(error ?? "You’re up to date.")) }
            Section { Text(t("Android and iOS use the same release feed. Each platform installs its own app build.")).font(.footnote); Button(t("Check again")) { Task { await check() } } }
        }.navigationTitle(t("App updates")).task { await check() }
    }
    private func check() async {
        busy = true; error = nil; release = nil; defer { busy = false }
        do {
            guard let file = Bundle.main.url(forResource: "release-source", withExtension: "json") else { throw APIError(status: 0, code: "update_unavailable") }
            let source = try JSONDecoder().decode(ReleaseSource.self, from: Data(contentsOf: file))
            let (data, response) = try await URLSession.shared.data(from: source.feedURL)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw APIError(status: 0, code: "update_unavailable") }
            let releases = try JSONDecoder().decode(JSON.self, from: data).items
            for item in releases where !item["draft"].flag {
                guard let manifestAsset = item["assets"].items.first(where: { $0["name"].text == source.manifest }), let manifestURL = source.trustedAsset(manifestAsset["browser_download_url"].text) else { continue }
                let (bytes, manifestResponse) = try await URLSession.shared.data(from: manifestURL)
                guard (manifestResponse as? HTTPURLResponse)?.statusCode == 200, bytes.count < 65536 else { continue }
                let manifest = try JSONDecoder().decode(JSON.self, from: bytes)
                if manifest["channel"].text != source.channel { continue }
                let name = manifest["artifacts"]["ios"]["file"].text
                guard let asset = item["assets"].items.first(where: { $0["name"].text == name }), let candidate = BinaryRelease(manifest: manifest, assetURL: asset["browser_download_url"].text, source: source, platform: "ios") else { continue }
                if candidate.build > Configuration().build, candidate.build > (release?.build ?? 0) { release = candidate }
            }
        } catch { self.error = "update_unavailable" }
    }
}

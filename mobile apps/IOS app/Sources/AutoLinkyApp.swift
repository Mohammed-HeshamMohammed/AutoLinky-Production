import SwiftUI
import FirebaseCore
import BackgroundTasks
import UserNotifications
import AutoLinkyCore

@main struct AutoLinkyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var auth: Authentication
    @AppStorage("language") private var language = Locale.current.language.languageCode?.identifier == "ar" ? "ar" : "en"
    @AppStorage("appearance") private var appearance = "system"
    init() {
        if FirebaseApp.app() == nil { FirebaseApp.configure() }
        _auth = StateObject(wrappedValue: Authentication(configuration: Configuration()))
    }
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(auth)
                .environment(\.locale, Locale(identifier: language))
                .environment(\.layoutDirection, language == "ar" ? .rightToLeft : .leftToRight)
                .preferredColorScheme(appearance == "system" ? nil : appearance == "dark" ? .dark : .light)
                .tint(Color(red: 47/255, green: 79/255, blue: 232/255))
                .onOpenURL { auth.receive($0) }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { if let url = $0.webpageURL { auth.receive(url) } }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        BGTaskScheduler.shared.register(forTaskWithIdentifier: ActivityNotifications.taskIdentifier, using: nil) { task in
            let work = Task { await ActivityNotifications.refresh(); task.setTaskCompleted(success: !Task.isCancelled) }
            task.expirationHandler = { work.cancel() }
        }
        return true
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) { completionHandler([.banner, .sound]) }
}

struct RootView: View {
    @EnvironmentObject private var auth: Authentication
    @State private var configured = Configuration().api != nil
    var body: some View {
        Group {
            if !configured { SetupView { configured = true } }
            else if !auth.initialized { ProgressView(t("Loading your account…")) }
            else if let uid = auth.uid { SignedInView(auth: auth, uid: uid).id(uid) }
            else { WelcomeView() }
        }
        .sheet(isPresented: Binding(get: { auth.incomingLink != nil }, set: { if !$0 { auth.incomingLink = nil } })) { EmailSignInView(completing: true) }
    }
}

struct SignedInView: View {
    @StateObject private var store: AppStore
    @Environment(\.scenePhase) private var phase
    init(auth: Authentication, uid: String) { _store = StateObject(wrappedValue: AppStore(auth: auth, owner: uid)) }
    var body: some View {
        Group {
            if store.loading { ProgressView(t("Loading your account…")) }
            else if store.account.isNull {
                ContentUnavailableView { Label(t("Unable to load account"), systemImage: "wifi.exclamationmark") } description: { Text(t("Check your connection and try again.")) } actions: {
                    Button(t("Retry")) { Task { await store.load() } }
                    Button(t("Sign out")) { Task { await ActivityNotifications.disable(api: nil); try? store.auth.signOut() } }
                }
            } else {
                TabView {
                    NavigationStack { FeedView(matched: true) }.tabItem { Label(t("For you"), systemImage: "sparkles") }
                    NavigationStack { FeedView(matched: false) }.tabItem { Label(t("Explore"), systemImage: "globe") }
                    NavigationStack { ProfileView() }.tabItem { Label(t("Profile"), systemImage: "person.crop.circle") }
                }
            }
        }
        .environmentObject(store)
        .task { await store.load() }
        .fullScreenCover(isPresented: $store.showOnboarding) { NavigationStack { ProfileEditor(onboarding: true).environmentObject(store) }.interactiveDismissDisabled() }
        .alert(t("Something needs your attention"), isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) { Button(t("OK")) { store.error = nil } } message: { Text(t(store.error ?? "request_failed")) }
        .task(id: phase) {
            guard phase == .active else { return }
            while !Task.isCancelled {
                await store.perform {
                    try await store.refreshAuto()
                    if store.autoApply["enabled"].flag || UserDefaults.standard.bool(forKey: "notifications") { try await store.checkActivity() }
                }
                do { try await Task.sleep(for: .seconds(60)) } catch { return }
            }
        }
    }
}

struct BrandMark: View {
    var body: some View { Image("BrandLogo").resizable().scaledToFit().frame(width: 88, height: 88).accessibilityHidden(true) }
}

struct SetupView: View {
    @EnvironmentObject private var auth: Authentication
    var complete: () -> Void
    @State private var address = Configuration().configuredAPI
    @State private var invalid = false
    var body: some View {
        NavigationStack {
            Form {
                Section { BrandMark().frame(maxWidth: .infinity); Text(t("Welcome to AutoLinky")).font(.title2.bold()); Text(t("Connect this development build to your AutoLinky API.")) }
                Section(t("API address")) { TextField("https://api.example.com", text: $address).textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL).accessibilityIdentifier("apiAddress")
                    if invalid { Text(t("Use a valid HTTPS API address.")).foregroundStyle(.red) }
                    Button(t("Continue")) {
                        var allowed = false
                        #if targetEnvironment(simulator) && DEBUG
                        allowed = Security.apiBase(address, allowLocal: true) != nil
                        #else
                        allowed = Security.apiBase(address) != nil
                        #endif
                        guard allowed else { invalid = true; return }
                        UserDefaults.standard.set(address, forKey: "development.api"); complete()
                    }.accessibilityIdentifier("setupContinue")
                }
                Section { LanguagePicker(); if let site = auth.configuration.site { Link(t("Open website"), destination: site) } }
            }.navigationTitle("AutoLinky")
        }
    }
}

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
        BrandTheme.configure()
        if FirebaseApp.app() == nil { FirebaseApp.configure() }
        _auth = StateObject(wrappedValue: Authentication(configuration: Configuration()))
    }
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(auth)
                .environment(\.locale, Locale(identifier: language))
                .environment(\.layoutDirection, language == "ar" ? .rightToLeft : .leftToRight)
                .preferredColorScheme(appearance == "system" ? nil : appearance == "dark" ? .dark : .light)
                .tint(BrandColors.primary)
                .background(BrandColors.canvas.ignoresSafeArea())
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
                    NavigationStack { FeedView(matched: true) }.tabItem { Label(t("For you"), systemImage: "rectangle.stack") }
                    NavigationStack { FeedView(matched: false) }.tabItem { Label(t("Explore"), systemImage: "magnifyingglass") }
                    NavigationStack { ProfileView() }.tabItem { Label(t("Profile"), systemImage: "person.crop.square") }
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

struct BrandWordmark: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var formation = 0.0
    @State private var started = false

    var body: some View {
        Image("BrandWordmark").resizable().scaledToFit()
            .frame(maxWidth: 260, maxHeight: 54)
            .modifier(WordmarkFormation(progress: reduceMotion ? 1 : formation))
            .accessibilityLabel("AutoLinky")
            .task {
                guard !started else { return }
                started = true
                if reduceMotion { formation = 1 }
                else { withAnimation(.linear(duration: 2.2)) { formation = 1 } }
            }
            .onChange(of: reduceMotion) { _, reduced in
                if reduced {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) { formation = 1 }
                }
            }
    }
}

private enum WordmarkIDot {
    static let bounds = CGRect(x: 250.780385437, y: 4.447470551, width: 12.151630096, height: 11.531758575)
    static let start = 0.65
    static let end = 0.96
    private static let keyframes: [(Double, Double)] = [
        (0, -22), (0.01, -22), (0.38, 4.10759903), (0.42, 4.10759903),
        (0.62, -3.2), (0.8, 4.10759903), (0.84, 4.10759903), (0.93, -0.7), (1, 0),
    ]
    private static func relative(_ progress: Double) -> Double { min(1, max(0, (progress - start) / (end - start))) }
    static func opacity(_ progress: Double) -> Double { min(1, relative(progress) / 0.01) }
    static func offset(_ progress: Double) -> Double {
        let value = relative(progress)
        for index in 1..<keyframes.count {
            let (begin, from) = keyframes[index - 1]
            let (finish, to) = keyframes[index]
            if value <= finish {
                let t = min(1, max(0, (value - begin) / (finish - begin)))
                let eased = index == 4 || index == 7 ? 1 - (1 - t) * (1 - t) : t * t
                return from + (to - from) * eased
            }
        }
        return 0
    }
}

/// An animatable modifier moves a second clipped copy of the actual artwork.
/// The mask only reveals the stem; the dot moves rigidly outside that mask.
private struct WordmarkFormation: AnimatableModifier {
    var progress: Double
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    func body(content: Content) -> some View {
        content.mask { WordmarkFormationMask(progress: progress) }
            .overlay {
                if progress >= WordmarkIDot.start && progress < 0.97 {
                    GeometryReader { geometry in
                        let scale = min(geometry.size.width / 405, geometry.size.height / 80)
                        content.mask { WordmarkDotMask() }
                            .offset(y: CGFloat(WordmarkIDot.offset(progress)) * scale)
                            .opacity(WordmarkIDot.opacity(progress))
                            .accessibilityHidden(true)
                            .allowsHitTesting(false)
                    }
                }
            }
    }
}

private struct WordmarkDotMask: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width / 405, rect.height / 80)
        let transform = CGAffineTransform(a: scale, b: 0, c: 0, d: scale, tx: rect.midX - 405 * scale / 2, ty: rect.midY - 80 * scale / 2)
        return Path(WordmarkIDot.bounds).applying(transform)
    }
}

/// A reveal mask over the exported artwork keeps every final outline intact.
private struct WordmarkFormationMask: Shape {
    var progress: Double
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    private func phase(_ start: Double, _ end: Double) -> Double {
        let value = min(1, max(0, (progress - start) / (end - start)))
        return value * value * (3 - 2 * value)
    }

    private func aPhase(_ start: Double, _ end: Double) -> Double {
        min(1, max(0, (progress - start) / (end - start)))
    }

    // Exact colored outlines from the canonical wordmark. Body brushes exclude
    // these regions so they cannot reveal a detached terminal ahead of its turn.
    private static let accents: [Path] = {
        var a = Path()
        a.move(to: CGPoint(x: 43, y: 51)); a.addLine(to: CGPoint(x: 73, y: 51))
        a.addCurve(to: CGPoint(x: 88, y: 64), control1: CGPoint(x: 82, y: 51), control2: CGPoint(x: 88, y: 57))
        a.addCurve(to: CGPoint(x: 74, y: 76), control1: CGPoint(x: 88, y: 71), control2: CGPoint(x: 82, y: 76))
        a.addCurve(to: CGPoint(x: 62, y: 69), control1: CGPoint(x: 68, y: 76), control2: CGPoint(x: 64, y: 73))
        for point in [CGPoint(x: 57, y: 60), CGPoint(x: 68, y: 60), CGPoint(x: 71, y: 66)] { a.addLine(to: point) }
        a.addCurve(to: CGPoint(x: 76, y: 68), control1: CGPoint(x: 72, y: 69), control2: CGPoint(x: 74, y: 69))
        a.addCurve(to: CGPoint(x: 79, y: 62), control1: CGPoint(x: 79, y: 67), control2: CGPoint(x: 80, y: 64))
        a.addCurve(to: CGPoint(x: 73, y: 59), control1: CGPoint(x: 78, y: 60), control2: CGPoint(x: 76, y: 59))
        a.addLine(to: CGPoint(x: 39, y: 59)); a.closeSubpath()
        var l = Path()
        l.move(to: CGPoint(x: 14, y: 32)); l.addLine(to: CGPoint(x: 24, y: 32))
        l.addCurve(to: CGPoint(x: 36, y: 42), control1: CGPoint(x: 31, y: 32), control2: CGPoint(x: 36, y: 36.5))
        l.addCurve(to: CGPoint(x: 24, y: 52), control1: CGPoint(x: 36, y: 47.5), control2: CGPoint(x: 31, y: 52))
        for point in [CGPoint(x: 14, y: 52), CGPoint(x: 14, y: 45), CGPoint(x: 24, y: 45)] { l.addLine(to: point) }
        l.addCurve(to: CGPoint(x: 28.5, y: 42), control1: CGPoint(x: 27, y: 45), control2: CGPoint(x: 28.5, y: 44))
        l.addCurve(to: CGPoint(x: 24, y: 39), control1: CGPoint(x: 28.5, y: 40), control2: CGPoint(x: 27, y: 39))
        l.addLine(to: CGPoint(x: 14, y: 39)); l.closeSubpath()
        return [a.applying(CGAffineTransform(translationX: -14, y: -17)), l.applying(CGAffineTransform(translationX: 207.765, y: 7))]
    }()

    func path(in rect: CGRect) -> Path {
        if progress >= 0.97 { return Path(rect) }
        var result = Path()
        func add(_ outline: Path) { result = result.union(outline) }
        func line(_ points: [CGPoint]) -> Path {
            var line = Path()
            guard let first = points.first else { return line }
            line.move(to: first)
            for point in points.dropFirst() { line.addLine(to: point) }
            return line
        }
        func brush(_ line: Path, _ amount: Double, _ width: CGFloat) -> Path {
            guard amount > 0 else { return Path() }
            return line.trimmedPath(from: 0, to: CGFloat(amount)).strokedPath(StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
        }
        let aAccent = Self.accents[0]
        let lAccent = Self.accents[1]
        var aBody = brush(line([CGPoint(x: 9, y: 59), CGPoint(x: 35, y: 11), CGPoint(x: 39, y: 11), CGPoint(x: 51, y: 32)]), aPhase(0.015, 0.22), 16)
        aBody.addPath(brush(line([CGPoint(x: 23, y: 46), CGPoint(x: 44, y: 46), CGPoint(x: 51, y: 55), CGPoint(x: 61, y: 58)]), aPhase(0.14, 0.29), 12))
        if progress >= 0.29 { aBody = Path(CGRect(x: 0, y: 0, width: 76, height: 80)) }
        add(aBody.subtracting(aAccent))
        let aBar = aAccent.intersection(Path(CGRect(x: 24, y: 33, width: 35, height: 9.01)))
        let aLoop = aAccent.subtracting(aBar)
        var aReturn = Path()
        aReturn.move(to: CGPoint(x: 49, y: 46))
        aReturn.addCurve(to: CGPoint(x: 64, y: 55), control1: CGPoint(x: 53, y: 54), control2: CGPoint(x: 57, y: 58))
        aReturn.addCurve(to: CGPoint(x: 59, y: 38), control1: CGPoint(x: 77, y: 51), control2: CGPoint(x: 72, y: 38))
        add(brush(aReturn, aPhase(0.27, 0.44), 14).intersection(aLoop))
        if progress >= 0.44 { add(aLoop) }
        add(brush(line([CGPoint(x: 59, y: 38), CGPoint(x: 25, y: 38)]), aPhase(0.42, 0.52), 14).intersection(aBar))
        if progress >= 0.52 { add(Path(CGRect(x: 0, y: 0, width: 76, height: 80))) }

        func letter(_ left: CGFloat, _ right: CGFloat, _ start: Double, down: Bool = true) {
            let amount = phase(start, start + 0.22)
            guard amount > 0 else { return }
            let outline = Path(CGRect(x: left, y: down ? 0 : 80 * CGFloat(1 - amount), width: right - left, height: 80 * CGFloat(amount)))
            add(outline.subtracting(lAccent))
        }
        letter(78, 123, 0.27)
        letter(123, 154, 0.31)
        letter(154, 202, 0.35, down: false)
        letter(203, 245, 0.39)
        letter(245, 269, 0.43)
        letter(269, 315, 0.47, down: false)
        letter(315, 359.5, 0.51)
        letter(359.5, 405, 0.55)
        var lReturn = Path()
        lReturn.move(to: CGPoint(x: 221.765, y: 55.5)); lReturn.addLine(to: CGPoint(x: 231.765, y: 55.5))
        lReturn.addCurve(to: CGPoint(x: 231.765, y: 42.5), control1: CGPoint(x: 242.765, y: 55.5), control2: CGPoint(x: 242.765, y: 42.5))
        lReturn.addLine(to: CGPoint(x: 221.765, y: 42.5))
        add(brush(lReturn, phase(0.76, 0.88), 9).intersection(lAccent))
        if progress >= 0.88 { add(lAccent) }
        result = result.subtracting(Path(WordmarkIDot.bounds))
        let scale = min(rect.width / 405, rect.height / 80)
        let transform = CGAffineTransform(a: scale, b: 0, c: 0, d: scale, tx: rect.midX - 405 * scale / 2, ty: rect.midY - 80 * scale / 2)
        return result.applying(transform)
    }
}

struct SetupView: View {
    @EnvironmentObject private var auth: Authentication
    var complete: () -> Void
    @State private var address = Configuration().configuredAPI
    @State private var invalid = false
    var body: some View {
        NavigationStack {
            BrandForm {
                VStack(alignment: .leading, spacing: 24) {
                    BrandWordmark().frame(maxWidth: .infinity, alignment: .leading).padding(.top, 20)
                    BrandPageHeading(eyebrow: "AutoLinky", title: "Welcome to AutoLinky", subtitle: "Connect this development build to your AutoLinky API.")
                }.listRowSeparator(.hidden)
                Section(t("API address")) { TextField("https://api.example.com", text: $address).textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL).accessibilityIdentifier("apiAddress")
                    if invalid { Text(t("Use a valid HTTPS API address.")).foregroundStyle(BrandColors.error) }
                    Button(t("Continue")) {
                        var allowed = false
                        #if targetEnvironment(simulator) && DEBUG
                        allowed = Security.apiBase(address, allowLocal: true) != nil
                        #else
                        allowed = Security.apiBase(address) != nil
                        #endif
                        guard allowed else { invalid = true; return }
                        UserDefaults.standard.set(address, forKey: "development.api"); complete()
                    }.buttonStyle(BrandPrimaryButtonStyle()).listRowSeparator(.hidden).accessibilityIdentifier("setupContinue")
                }
                Section { LanguagePicker(); if let site = auth.configuration.site { Link(t("Open website"), destination: site) } }
            }.navigationTitle("AutoLinky")
        }
    }
}

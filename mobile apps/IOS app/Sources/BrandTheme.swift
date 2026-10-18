import SwiftUI
import UIKit

// Named light/dark colors are generated from the same identity as Android and web.
enum BrandColors {
    static let canvas = Color("Canvas")
    static let surface = Color("Surface")
    static let chrome = Color("Chrome")
    static let hero = Color("Hero")
    static let onHero = Color("OnHero")
    static let text = Color("Text")
    static let muted = Color("Muted")
    static let primary = Color("Primary")
    static let success = Color("Success")
    static let warning = Color("Warning")
    static let error = Color("Error")
    static let line = Color("Line")
}

@MainActor enum BrandTheme {
    static func configure() {
        let navigation = UINavigationBarAppearance()
        navigation.configureWithOpaqueBackground()
        navigation.backgroundColor = UIColor(named: "Hero")
        navigation.shadowColor = .clear
        navigation.titleTextAttributes = [.foregroundColor: UIColor(named: "OnHero") ?? .white, .font: UIFont.systemFont(ofSize: 16, weight: .semibold)]
        navigation.largeTitleTextAttributes = [.foregroundColor: UIColor(named: "OnHero") ?? .white, .font: UIFont.systemFont(ofSize: 34, weight: .semibold)]
        navigation.buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(named: "OnHero") ?? .white]
        navigation.backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(named: "OnHero") ?? .white]
        UINavigationBar.appearance().standardAppearance = navigation
        UINavigationBar.appearance().scrollEdgeAppearance = navigation
        UINavigationBar.appearance().compactAppearance = navigation
        UINavigationBar.appearance().tintColor = UIColor(named: "OnHero")

        let tabs = UITabBarAppearance()
        tabs.configureWithOpaqueBackground()
        tabs.backgroundColor = UIColor(named: "Canvas")
        tabs.shadowColor = UIColor(named: "Line")
        for item in [tabs.stackedLayoutAppearance, tabs.inlineLayoutAppearance, tabs.compactInlineLayoutAppearance] {
            item.normal.iconColor = UIColor(named: "Muted")
            item.normal.titleTextAttributes = [.foregroundColor: UIColor(named: "Muted") ?? .secondaryLabel, .font: UIFont.systemFont(ofSize: 11, weight: .medium)]
            item.selected.iconColor = UIColor(named: "Primary")
            item.selected.titleTextAttributes = [.foregroundColor: UIColor(named: "Primary") ?? .label, .font: UIFont.systemFont(ofSize: 11, weight: .semibold)]
        }
        UITabBar.appearance().standardAppearance = tabs
        UITabBar.appearance().scrollEdgeAppearance = tabs
        UITableView.appearance().separatorColor = UIColor(named: "Line")
        UITableView.appearance().backgroundColor = UIColor(named: "Canvas")
    }
}

extension View {
    func brandSurface() -> some View {
        scrollContentBackground(.hidden)
            .background(BrandColors.canvas.ignoresSafeArea())
            .tint(BrandColors.primary)
            .foregroundStyle(BrandColors.text)
    }
}

struct BrandForm<Content: View>: View {
    private let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        BrandList { content }
    }
}

struct BrandList<Content: View>: View {
    private let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        List {
            content
                .listRowBackground(BrandColors.canvas)
                .listRowInsets(EdgeInsets(top: 14, leading: 26, bottom: 14, trailing: 26))
        }
            .listStyle(.plain)
            .listRowSeparatorTint(BrandColors.line)
            .listSectionSpacing(.custom(28))
            .environment(\.defaultMinListRowHeight, 56)
            .brandSurface()
            .toolbarBackground(BrandColors.hero, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct BrandMasthead: View {
    var body: some View {
        Image("BrandWordmark").resizable().scaledToFit()
            .frame(width: 142, height: 29)
            .environment(\.colorScheme, .dark)
            .accessibilityLabel("AutoLinky")
    }
}

struct BrandPageHeading: View {
    let eyebrow: String
    let title: String
    var subtitle: String? = nil
    @Environment(\.layoutDirection) private var direction
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize = 38
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionLabel(eyebrow)
            Text(t(title)).font(.system(size: titleSize, weight: .semibold))
                .tracking(direction == .rightToLeft ? 0 : -1.3).fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(BrandColors.text).accessibilityAddTraits(.isHeader)
            if let subtitle { Text(t(subtitle)).font(.subheadline).lineSpacing(4).foregroundStyle(BrandColors.muted).fixedSize(horizontal: false, vertical: true) }
        }.padding(.top, 12).padding(.bottom, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct BrandSectionLabel: View {
    let text: String
    @Environment(\.layoutDirection) private var direction
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(t(text)).font(.caption.weight(.semibold)).tracking(direction == .rightToLeft ? 0 : 1.6)
            .textCase(.uppercase).foregroundStyle(BrandColors.primary)
            .accessibilityLabel(t(text))
    }
}

struct BrandRule: View {
    var body: some View { Rectangle().fill(BrandColors.line).frame(height: 1).accessibilityHidden(true) }
}

struct BrandMetric: View {
    let value: String
    let label: String
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(value).font(.system(.largeTitle, design: .default, weight: .medium)).tracking(-1)
                .foregroundStyle(BrandColors.text).contentTransition(.numericText())
            Text(t(label)).font(.caption).foregroundStyle(BrandColors.muted)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct BrandPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity).padding(.horizontal, 20).padding(.vertical, 18)
            .foregroundStyle(BrandColors.canvas)
            .background(BrandColors.text, in: RoundedRectangle(cornerRadius: 6))
            .opacity(!isEnabled ? 0.4 : configuration.isPressed ? 0.8 : 1)
    }
}

struct BrandOutlineButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity).padding(.horizontal, 20).padding(.vertical, 17)
            .foregroundStyle(BrandColors.text)
            .background(configuration.isPressed ? BrandColors.surface : BrandColors.canvas, in: RoundedRectangle(cornerRadius: 6))
            .overlay { RoundedRectangle(cornerRadius: 6).stroke(BrandColors.line, lineWidth: 1) }
            .opacity(isEnabled ? 1 : 0.4)
    }
}

struct BrandEmptyState: View {
    let title: String
    let message: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandRule().padding(.bottom, 12)
            Text(t(title)).font(.title2.weight(.medium)).foregroundStyle(BrandColors.text)
            Text(t(message)).font(.subheadline).lineSpacing(4).foregroundStyle(BrandColors.muted)
        }.padding(.vertical, 32).frame(maxWidth: .infinity, alignment: .leading)
    }
}

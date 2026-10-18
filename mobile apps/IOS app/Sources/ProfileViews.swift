import SwiftUI
import UniformTypeIdentifiers
import AutoLinkyCore

struct ProfileView: View {
    @EnvironmentObject private var store: AppStore
    @State private var importing = false
    @State private var busy = false
    @State private var deleteCV = false
    var body: some View {
        BrandForm {
            VStack(alignment: .leading, spacing: 16) {
                BrandPageHeading(eyebrow: "AutoLinky", title: "Profile", subtitle: store.profile["headline"].text.isEmpty ? nil : store.profile["headline"].text)
                Text(store.auth.email).font(.subheadline).foregroundStyle(BrandColors.muted).privacySensitive()
                NavigationLink(t("Edit profile")) { ProfileEditor(onboarding: false) }.buttonStyle(BrandOutlineButtonStyle())
            }.padding(.bottom, 14).listRowSeparator(.hidden)
            Section {
                if store.cv.isNull { Text(t("Upload your CV to build your profile and find relevant jobs.")).font(.title3.weight(.medium)).lineSpacing(4).padding(.vertical, 10) }
                else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(store.cv["file_name"].text).font(.title3.weight(.medium)).fixedSize(horizontal: false, vertical: true)
                        Text(ByteCountFormatter.string(fromByteCount: Int64(store.cv["file_size"].integer), countStyle: .file)).font(.caption).foregroundStyle(BrandColors.muted)
                    }.padding(.vertical, 12)
                    if store.cv["analysis"].text == "partial" { Text(t("Your CV was partly read. You can ask for another analysis.")); Button(t("Analyze again")) { run { try await store.reanalyze() } } }
                    Button(t("Delete CV"), role: .destructive) { deleteCV = true }
                }
                Button(t(store.cv.isNull ? "Upload CV" : "Replace CV")) { importing = true }.buttonStyle(BrandPrimaryButtonStyle()).listRowSeparator(.hidden)
                if busy { ProgressView(t("Reading your CV…")) }
                Text(t("PDF or DOCX, up to 4 MB. Your CV is stored privately.")).font(.footnote).foregroundStyle(BrandColors.muted)
            } header: { BrandSectionLabel("Your CV") }.disabled(busy)
            Section { NavigationLink(t("Applications")) { ApplicationsView() }; NavigationLink(t("Auto apply")) { AutoApplyView() }; NavigationLink(t("Gmail settings")) { MailSettingsView() }; NavigationLink(t("Search progress")) { SearchProgressView() } } header: { BrandSectionLabel("Your target work") }
            Section { NavigationLink(t("Settings")) { SettingsView() } }
        }.navigationTitle(t("Profile"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .principal) { BrandMasthead() } }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.pdf, UTType(filenameExtension: "docx") ?? .data]) { result in run { try await store.upload(result.get()) } }
        .confirmationDialog(t("Delete your stored CV? Your profile will stay."), isPresented: $deleteCV, titleVisibility: .visible) { Button(t("Delete CV"), role: .destructive) { run { _ = try await store.api.request("/v1/cv", method: "DELETE"); try store.validateOwner(); store.cv = .null } } }
        .refreshable { await store.load() }
    }
    private func run(_ action: @escaping () async throws -> Void) { busy = true; Task { defer { busy = false }; await store.perform(action) } }
}

struct ProfileEditor: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let onboarding: Bool
    @State private var headline = ""
    @State private var roles = Set<String>()
    @State private var fields = Set<String>()
    @State private var skills = Set<String>()
    @State private var languages = Set<String>()
    @State private var extras = ""
    @State private var titles = ""
    @State private var countries = ""
    @State private var scope = "egypt"
    @State private var level = ""
    @State private var years = 0
    @State private var remote = true
    @State private var busy = false
    @State private var importing = false
    @State private var loaded = false
    var body: some View {
        BrandForm {
            BrandPageHeading(eyebrow: "Profile", title: onboarding ? "Let’s find the right opportunities for you." : "Edit profile", subtitle: onboarding ? "Start with your CV, then review the profile it creates." : nil).listRowSeparator(.hidden)
            if onboarding { Section { Button(t("Upload CV")) { importing = true }.buttonStyle(BrandPrimaryButtonStyle()).listRowSeparator(.hidden); if !store.cv.isNull { Text(store.cv["file_name"].text).foregroundStyle(BrandColors.success) } } }
            Section(t("About you")) { TextField(t("Headline"), text: $headline); Picker(t("Experience level"), selection: $level) { Text(t("Not specified")).tag(""); ForEach(["intern", "junior", "mid", "senior", "manager"], id: \.self) { Text(t($0)).tag($0) } }; Stepper(t("Years of experience") + ": \(years)", value: $years, in: 0...60) }
            Section(t("Your target work")) {
                Picker(t("Where to work"), selection: $scope) { ForEach(["egypt", "egypt_gulf", "egypt_remote", "egypt_gulf_remote", "remote", "worldwide"], id: \.self) { Text(t($0)).tag($0) } }
                Toggle(t("Open to remote work"), isOn: $remote)
                TextField(t("Country codes, separated by commas"), text: $countries).textInputAutocapitalization(.characters).autocorrectionDisabled()
                TextField(t("Search titles, one per line"), text: $titles, axis: .vertical).lineLimit(3...8)
                Text(t("Up to 8 job titles. These guide collection and matching.")).font(.footnote).foregroundStyle(BrandColors.muted)
                NavigationLink { TaxonomySelection(title: "Roles", values: store.taxonomy["roles"].items, selection: $roles, limit: 5) } label: { LabeledContent { Text("\(roles.count)/5").environment(\.layoutDirection, .leftToRight) } label: { Text(t("Roles")) } }
                NavigationLink { TaxonomySelection(title: "Fields", values: store.taxonomy["fields"].items, selection: $fields, limit: 5) } label: { LabeledContent { Text("\(fields.count)/5").environment(\.layoutDirection, .leftToRight) } label: { Text(t("Fields")) } }
            }
            Section(t("Skills and languages")) {
                NavigationLink { TaxonomySelection(title: "Skills", values: store.taxonomy["skills"].items, selection: $skills, limit: 60) } label: { LabeledContent { Text("\(skills.count)/60").environment(\.layoutDirection, .leftToRight) } label: { Text(t("Skills")) } }
                TextField(t("Other skills, separated by commas"), text: $extras, axis: .vertical)
                ForEach(["en", "ar", "de", "fr", "nl", "es", "pt"], id: \.self) { language in Toggle(Locale.current.localizedString(forLanguageCode: language) ?? language, isOn: Binding(get: { languages.contains(language) }, set: { if $0 { languages.insert(language) } else { languages.remove(language) } })) }
            }
            if busy { ProgressView(t("Saving…")) }
        }.navigationTitle(t(onboarding ? "Set up your profile" : "Edit profile")).navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button(t("Save")) { save() }.disabled(busy || headline.count > 100 || lines(titles).count > 8 || list(extras).count > 30 || list(countries).count > 15) } }
        .disabled(busy)
        .onAppear { if !loaded { fill(); loaded = true } }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.pdf, UTType(filenameExtension: "docx") ?? .data]) { result in busy = true; Task { defer { busy = false }; await store.perform { try await store.upload(result.get()); fill() } } }
    }
    private func fill() {
        let p = store.profile
        headline = p["headline"].text; roles = Set(p["target_roles"].strings); fields = Set(p["target_fields"].strings); skills = Set(p["skills"].strings)
        languages = Set(p["languages"].isNull ? ["en", "ar"] : p["languages"].strings)
        extras = p["extra_skills"].strings.joined(separator: ", "); titles = p["search_titles"].strings.joined(separator: "\n"); countries = p["countries"].strings.joined(separator: ", ")
        scope = p["search_scope"].text.isEmpty ? "egypt" : p["search_scope"].text; level = p["level"].text; years = min(60, max(0, p["years_experience"].integer)); remote = p["remote_ok"].isNull || p["remote_ok"].flag
    }
    private func list(_ text: String) -> [String] { Array(NSOrderedSet(array: text.components(separatedBy: CharacterSet(charactersIn: ",،")).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })) as? [String] ?? [] }
    private func lines(_ text: String) -> [String] { text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty } }
    private func save() {
        busy = true; Task { defer { busy = false }; await store.perform {
            try await store.saveProfile(["headline": .string(headline), "target_roles": .strings(roles.sorted()), "target_fields": .strings(fields.sorted()), "skills": .strings(skills.sorted()), "extra_skills": .strings(list(extras)), "level": level.isEmpty ? .null : .string(level), "years_experience": .number(Double(years)), "countries": .strings(list(countries)), "remote_ok": .bool(remote), "languages": .strings(languages.sorted()), "search_titles": .strings(lines(titles)), "search_scope": .string(scope)])
            dismiss()
        } }
    }
}

struct TaxonomySelection: View {
    let title: String
    let values: [JSON]
    @Binding var selection: Set<String>
    let limit: Int
    @State private var query = ""
    @AppStorage("language") private var language = "en"
    private func label(_ value: JSON) -> String { let name = value[language == "ar" ? "name_ar" : "name_en"].text; return name.isEmpty ? (value["name"].text.isEmpty ? value["slug"].text : value["name"].text) : name }
    var body: some View {
        BrandList {
            BrandPageHeading(eyebrow: "Edit profile", title: title).listRowSeparator(.hidden)
            ForEach(selection.filter { slug in !values.contains { $0["slug"].text == slug } }.sorted(), id: \.self) { slug in Button { selection.remove(slug) } label: { Label(slug, systemImage: "checkmark.circle.fill") } }
            ForEach(values.filter { query.isEmpty || label($0).localizedCaseInsensitiveContains(query) || $0["slug"].text.localizedCaseInsensitiveContains(query) }) { value in
                let slug = value["slug"].text
                Button { if selection.contains(slug) { selection.remove(slug) } else if selection.count < limit { selection.insert(slug) } } label: { HStack { Text(label(value)); Spacer(); if selection.contains(slug) { Image(systemName: "checkmark") } } }
                .disabled(!selection.contains(slug) && selection.count >= limit)
            }
        }.navigationTitle(t(title)).searchable(text: $query).toolbar { Text("\(selection.count)/\(limit)").environment(\.layoutDirection, .leftToRight).foregroundStyle(BrandColors.muted) }
    }
}

struct SearchProgressView: View {
    @EnvironmentObject private var store: AppStore
    @State private var status: JSON = .null
    @State private var busy = false
    var body: some View {
        BrandList {
            BrandPageHeading(eyebrow: "Explore", title: "Search progress", subtitle: "Search requests are handled by the collector when it is available.").listRowSeparator(.hidden)
            ForEach(status["titles"].items) { item in LabeledContent(item["title"].text, value: t(item["status"].text)) }
            Button(t("Search now")) { Task { await refresh(start: true) } }.buttonStyle(BrandPrimaryButtonStyle()).listRowSeparator(.hidden).disabled(busy)
            if busy { ProgressView() }
        }.navigationTitle(t("Search progress")).task { await refresh(start: false) }.refreshable { await refresh(start: false) }
    }
    private func refresh(start: Bool) async { busy = true; defer { busy = false }; await store.perform { let result = try await store.api.request(start ? "/v1/profile/search-now" : "/v1/profile/search-status", method: start ? "POST" : "GET"); try store.validateOwner(); status = result } }
}

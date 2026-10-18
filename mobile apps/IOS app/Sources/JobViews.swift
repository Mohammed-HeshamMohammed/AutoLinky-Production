import SwiftUI
import AutoLinkyCore

struct FeedView: View {
    @EnvironmentObject private var store: AppStore
    let matched: Bool
    @State private var jobs: [Job] = []
    @State private var cursor: String?
    @State private var query = ""
    @State private var channel = ""
    @State private var mode = ""
    @State private var busy = false
    @State private var error: String?
    private var key: String { "\(query)|\(channel)|\(mode)|\(store.revision)" }
    var body: some View {
        BrandList {
            BrandPageHeading(eyebrow: "AutoLinky", title: matched ? "For you" : "Explore", subtitle: "Find jobs matched to your skills.")
                .listRowSeparator(.hidden)
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    BrandSectionLabel("Search jobs")
                    Picker(t("Apply by"), selection: $channel) { Text(t("All methods")).tag(""); ForEach(["email", "whatsapp", "link", "dm", "comment", "easy_apply", "external", "phone"], id: \.self) { Text(t($0)).tag($0) } }.pickerStyle(.menu)
                    Picker(t("Work mode"), selection: $mode) { Text(t("All locations")).tag(""); ForEach(["remote", "onsite", "hybrid"], id: \.self) { Text(t($0)).tag($0) } }.pickerStyle(.menu)
                }.font(.subheadline)
            }
            if matched {
                Section {
                    NavigationLink { AutoApplyView() } label: {
                        HStack(alignment: .top, spacing: 20) {
                            VStack(alignment: .leading, spacing: 9) {
                                BrandSectionLabel("Auto apply")
                                Text(t(store.autoApply["enabled"].flag ? "Auto apply enabled" : "Auto apply preferences")).font(.headline.weight(.medium)).foregroundStyle(BrandColors.text)
                            }
                            Spacer(minLength: 0)
                            VStack(alignment: .trailing, spacing: 6) {
                                Text("\(store.autoApply["sent_today"].integer)").font(.title.weight(.medium)).monospacedDigit().foregroundStyle(BrandColors.text)
                                Text(t("Sent today")).font(.caption2).foregroundStyle(BrandColors.muted)
                            }
                        }.padding(20).background(BrandColors.surface)
                    }.listRowSeparator(.hidden)
                }
            }
            if let error { Section { Text(t(error)); Button(t("Retry")) { Task { await load(reset: true) } } } }
            if jobs.isEmpty && !busy && error == nil { BrandEmptyState(title: "No jobs yet", message: "Try another filter or update your profile. New opportunities appear as they are collected.").listRowSeparator(.hidden) }
            ForEach(jobs) { job in NavigationLink { JobDetailView(job: job) } label: { JobRow(job: job) } }
            if busy { ProgressView().frame(maxWidth: .infinity) }
            if cursor != nil && !busy { Button(t("Load more")) { Task { await load(reset: false) } } }
        }
        .navigationTitle(t(matched ? "For you" : "Explore"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .principal) { BrandMasthead() } }
        .searchable(text: $query, prompt: t("Search jobs"))
        .task(id: key) { if !query.isEmpty { try? await Task.sleep(for: .milliseconds(300)) }; if !Task.isCancelled { await load(reset: true) } }
        .refreshable { await load(reset: true) }
    }
    private func load(reset: Bool) async {
        busy = true; error = nil
        defer { busy = false }
        do {
            var parameters = [URLQueryItem(name: "limit", value: "20")]
            if !reset, let cursor { parameters.append(.init(name: "cursor", value: cursor)) }
            if !channel.isEmpty { parameters.append(.init(name: "apply", value: channel)) }
            if !mode.isEmpty { parameters.append(.init(name: "work_mode", value: mode)) }
            if !matched && !query.isEmpty { parameters.append(.init(name: "q", value: query)) }
            let page = JobPage(try await store.api.request(matched ? "/v1/jobs/matched" : "/v1/jobs", query: parameters))
            try store.validateOwner()
            let incoming = matched && !query.isEmpty ? page.jobs.filter { "\($0.title) \($0.company)".localizedCaseInsensitiveContains(query) } : page.jobs
            let prior = reset ? [] : jobs
            var ids = Set(prior.map(\.id)); jobs = prior + incoming.filter { ids.insert($0.id).inserted }; cursor = page.cursor
        } catch is CancellationError { } catch { if !Task.isCancelled { self.error = AppStore.message(error) } }
    }
}

struct JobRow: View {
    let job: Job
    @Environment(\.layoutDirection) private var direction
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !job.company.isEmpty { Text(job.company).font(.caption.weight(.semibold)).tracking(direction == .rightToLeft ? 0 : 0.9).foregroundStyle(BrandColors.primary) }
            HStack(alignment: .top, spacing: 18) {
                Text(job.title).font(.title2.weight(.semibold)).tracking(direction == .rightToLeft ? 0 : -0.6).foregroundStyle(BrandColors.text).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if let match = job.matchPercent {
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("\(match)%").font(.title3.weight(.medium)).monospacedDigit()
                        Text(t("Match")).font(.caption2).foregroundStyle(BrandColors.muted)
                    }.foregroundStyle(match >= 70 ? BrandColors.success : BrandColors.primary)
                }
            }
            if !job.location.isEmpty { Text(job.location).font(.subheadline).foregroundStyle(BrandColors.muted) }
            HStack(alignment: .firstTextBaseline) {
                Text(job.methods.map(t).joined(separator: " · ")).font(.caption).foregroundStyle(BrandColors.muted)
                Spacer(minLength: 8)
                if !job.application.isNull { Text(t(job.application["status"].text)).font(.caption.weight(.semibold)).foregroundStyle(BrandColors.success) }
            }
        }.padding(.vertical, 14)
    }
}

struct JobDetailView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.openURL) private var openURL
    let job: Job
    @State private var detail: Job?
    @State private var emailSheet = false
    @State private var confirmMethod: String?
    @State private var busy = false
    var body: some View {
        BrandList {
            VStack(alignment: .leading, spacing: 14) { BrandSectionLabel("Opportunity"); JobRow(job: detail ?? job) }.padding(.top, 10)
                .listRowSeparator(.hidden)
            if let detail {
                if let score = job.matchPercent { Section { HStack { Text("\(score)%").font(.largeTitle.weight(.medium)).monospacedDigit(); Spacer(); Text(job.raw["match_reasons"]["skills"].strings.joined(separator: ", ")).font(.subheadline).foregroundStyle(BrandColors.muted) }; if !job.raw["match_reasons"]["missing"].strings.isEmpty { Text(t("Skills to develop") + ": " + job.raw["match_reasons"]["missing"].strings.joined(separator: ", ")).font(.subheadline).foregroundStyle(BrandColors.muted) } } header: { BrandSectionLabel("Why this matches") } }
                if !detail.description.isEmpty { Section { Text(detail.description).font(.body).lineSpacing(6).textSelection(.enabled).padding(.vertical, 8) } header: { BrandSectionLabel("About this opportunity") } }
                if !detail.raw["skills"].strings.isEmpty { Section(t("Skills")) { Text(detail.raw["skills"].strings.joined(separator: ", ")) } }
                Section {
                    ForEach(detail.methods, id: \.self) { method in
                        if method == "email" { Button(t("Preview and send my CV")) { emailSheet = true }.buttonStyle(BrandPrimaryButtonStyle()).listRowSeparator(.hidden) }
                        else if let url = detail.destination(for: method) { Button(t(method)) { openURL(url) { opened in if opened { confirmMethod = method } } } }
                    }
                    if let source = Security.webURL(detail.raw["url"].text) { Link(t("View original post"), destination: source) }
                } header: { BrandSectionLabel("Apply") }
                if !detail.application.isNull { Section(t("Application")) { Text(t(detail.application["status"].text)) } }
            } else { ProgressView() }
        }.navigationTitle(t("Opportunity")).navigationBarTitleDisplayMode(.inline).disabled(busy)
        .task { await reload() }
        .sheet(isPresented: $emailSheet, onDismiss: { Task { await reload() } }) { NavigationStack { EmailPreviewView(job: detail ?? job).environmentObject(store) } }
        .confirmationDialog(t("Did you apply?"), isPresented: Binding(get: { confirmMethod != nil }, set: { if !$0 { confirmMethod = nil } }), titleVisibility: .visible) {
            Button(t("Mark as applied")) { if let method = confirmMethod { busy = true; Task { defer { busy = false }; await store.perform { _ = try await store.api.request("/v1/applications", method: "POST", json: .object(["job_id": .string(job.id), "method": .string(method)])); store.revision += 1; await reload() } } }; confirmMethod = nil }
            Button(t("Not yet"), role: .cancel) { confirmMethod = nil }
        }
    }
    private func reload() async { await store.perform { let raw = try await store.api.request("/v1/jobs/\(job.id)"); try store.validateOwner(); detail = Job(raw) } }
}

struct EmailPreviewView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let job: Job
    @State private var preview: JSON = .null
    @State private var letter = ""
    @State private var busy = false
    @State private var confirmation = false
    @State private var error: String?
    var body: some View {
        BrandForm {
            BrandPageHeading(eyebrow: "Applications", title: "Email application", subtitle: "Review before sending").listRowSeparator(.hidden)
            if preview.isNull { if let error { Text(t(error)); NavigationLink(t("Gmail settings")) { MailSettingsView() }; Button(t("Retry")) { Task { await load() } } } else { ProgressView() } }
            else {
                Section(t("Review before sending")) { LabeledContent(t("To"), value: preview["to"].text); LabeledContent(t("From"), value: preview["from_address"].text); LabeledContent(t("Subject"), value: preview["subject"].text); LabeledContent(t("Attachment"), value: preview["attachment"].text) }
                Section(t("Cover letter")) { TextEditor(text: $letter).frame(minHeight: 240).accessibilityLabel(t("Cover letter")) }
                Section { Button(t("Send my CV")) { confirmation = true }.buttonStyle(BrandPrimaryButtonStyle()).listRowSeparator(.hidden).disabled(busy || letter.count > 8000); if busy { ProgressView() }; Text(t("If sending is interrupted, check your application history before trying again.")).font(.footnote).foregroundStyle(BrandColors.muted) }
            }
        }.navigationTitle(t("Email application")).toolbar { ToolbarItem(placement: .cancellationAction) { Button(t("Close")) { dismiss() } } }.task { await load() }
        .confirmationDialog(t("Send this application?"), isPresented: $confirmation, titleVisibility: .visible) { Button(t("Send my CV")) { busy = true; Task { defer { busy = false }; do { _ = try await store.api.request("/v1/applications", method: "POST", json: .object(["job_id": .string(job.id), "method": .string("email"), "letter": .string(letter)])); try store.validateOwner(); store.revision += 1; dismiss() } catch { self.error = AppStore.message(error); preview = .null } } } }
    }
    private func load() async { do { let result = try await store.api.request("/v1/applications/email-preview", query: [.init(name: "job_id", value: job.id)]); try store.validateOwner(); preview = result; letter = result["body"].text; error = nil } catch { self.error = AppStore.message(error) } }
}

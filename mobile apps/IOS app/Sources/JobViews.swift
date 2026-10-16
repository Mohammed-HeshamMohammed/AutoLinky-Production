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
        List {
            Section {
                Picker(t("Apply by"), selection: $channel) { Text(t("All methods")).tag(""); ForEach(["email", "whatsapp", "link", "dm", "comment", "easy_apply", "external", "phone"], id: \.self) { Text(t($0)).tag($0) } }
                Picker(t("Work mode"), selection: $mode) { Text(t("All locations")).tag(""); ForEach(["remote", "onsite", "hybrid"], id: \.self) { Text(t($0)).tag($0) } }
            }
            if matched { Section { NavigationLink { AutoApplyView() } label: { Label(t("Auto apply"), systemImage: "paperplane.circle") } } }
            if let error { Section { Text(t(error)); Button(t("Retry")) { Task { await load(reset: true) } } } }
            if jobs.isEmpty && !busy && error == nil { ContentUnavailableView(t("No jobs yet"), systemImage: "magnifyingglass", description: Text(t("Try another filter or update your profile. New opportunities appear as they are collected."))) }
            ForEach(jobs) { job in NavigationLink { JobDetailView(job: job) } label: { JobRow(job: job) } }
            if busy { ProgressView().frame(maxWidth: .infinity) }
            if cursor != nil && !busy { Button(t("Load more")) { Task { await load(reset: false) } } }
        }
        .navigationTitle(t(matched ? "For you" : "Explore"))
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
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .top) { Text(job.title).font(.headline); Spacer(); if let match = job.matchPercent { Text("\(match)%").font(.subheadline.bold()).foregroundStyle(match >= 70 ? .green : .blue) } }
            if !job.company.isEmpty { Text(job.company).font(.subheadline) }
            if !job.location.isEmpty { Label(job.location, systemImage: "mappin.and.ellipse").font(.caption).foregroundStyle(.secondary) }
            HStack { Text(job.methods.map(t).joined(separator: " · ")).font(.caption).foregroundStyle(.secondary); Spacer(); if !job.application.isNull { Text(t(job.application["status"].text)).font(.caption.bold()).foregroundStyle(.green) } }
        }.padding(.vertical, 8)
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
        List {
            JobRow(job: detail ?? job)
            if let detail {
                if let score = job.matchPercent { Section(t("Why this matches")) { Text("\(score)%"); Text(job.raw["match_reasons"]["skills"].strings.joined(separator: ", ")); if !job.raw["match_reasons"]["missing"].strings.isEmpty { Text(t("Skills to develop") + ": " + job.raw["match_reasons"]["missing"].strings.joined(separator: ", ")) } } }
                if !detail.description.isEmpty { Section(t("About this opportunity")) { Text(detail.description).textSelection(.enabled) } }
                if !detail.raw["skills"].strings.isEmpty { Section(t("Skills")) { Text(detail.raw["skills"].strings.joined(separator: ", ")) } }
                Section(t("Apply")) {
                    ForEach(detail.methods, id: \.self) { method in
                        if method == "email" { Button(t("Preview and send my CV")) { emailSheet = true } }
                        else if let url = detail.destination(for: method) { Button(t(method)) { openURL(url) { opened in if opened { confirmMethod = method } } } }
                    }
                    if let source = Security.webURL(detail.raw["url"].text) { Link(t("View original post"), destination: source) }
                }
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
        Form {
            if preview.isNull { if let error { Text(t(error)); NavigationLink(t("Gmail settings")) { MailSettingsView() }; Button(t("Retry")) { Task { await load() } } } else { ProgressView() } }
            else {
                Section(t("Review before sending")) { LabeledContent(t("To"), value: preview["to"].text); LabeledContent(t("From"), value: preview["from_address"].text); LabeledContent(t("Subject"), value: preview["subject"].text); LabeledContent(t("Attachment"), value: preview["attachment"].text) }
                Section(t("Cover letter")) { TextEditor(text: $letter).frame(minHeight: 240).accessibilityLabel(t("Cover letter")) }
                Section { Button(t("Send my CV")) { confirmation = true }.disabled(busy || letter.count > 8000); if busy { ProgressView() }; Text(t("If sending is interrupted, check your application history before trying again.")).font(.footnote).foregroundStyle(.secondary) }
            }
        }.navigationTitle(t("Email application")).toolbar { ToolbarItem(placement: .cancellationAction) { Button(t("Close")) { dismiss() } } }.task { await load() }
        .confirmationDialog(t("Send this application?"), isPresented: $confirmation, titleVisibility: .visible) { Button(t("Send my CV")) { busy = true; Task { defer { busy = false }; do { _ = try await store.api.request("/v1/applications", method: "POST", json: .object(["job_id": .string(job.id), "method": .string("email"), "letter": .string(letter)])); try store.validateOwner(); store.revision += 1; dismiss() } catch { self.error = AppStore.message(error); preview = .null } } } }
    }
    private func load() async { do { let result = try await store.api.request("/v1/applications/email-preview", query: [.init(name: "job_id", value: job.id)]); try store.validateOwner(); preview = result; letter = result["body"].text; error = nil } catch { self.error = AppStore.message(error) } }
}

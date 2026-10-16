import SwiftUI
import AutoLinkyCore

struct AutoApplyView: View {
    @EnvironmentObject private var store: AppStore
    @State private var enabled = false
    @State private var match = 70
    @State private var limit = 20
    @State private var gap = 5
    @State private var busy = false
    var body: some View {
        Form {
            Section(t("Sending status")) {
                LabeledContent(t("Sent today"), value: "\(store.autoApply["sent_today"].integer)")
                LabeledContent(t("Plan"), value: t(store.autoApply["plan"].text))
                if store.autoApply["plan"].text == "free" { LabeledContent(t("Free applications remaining"), value: "\(store.autoApply["free_left"].integer)") }
                if !store.autoApply["problem"].isNull { Text(t(store.autoApply["problem"].text)).foregroundStyle(.orange) }
                if !store.autoApply["next_send_at"].text.isEmpty { LabeledContent(t("Next send"), value: store.autoApply["next_send_at"].text) }
                NavigationLink(t("Gmail settings")) { MailSettingsView() }
            }
            Section(t("Auto apply preferences")) {
                Toggle(t("Auto apply enabled"), isOn: $enabled)
                Stepper(t("Minimum match") + ": \(match)%", value: $match, in: 40...95, step: 5)
                Stepper(t("Daily limit") + ": \(limit)", value: $limit, in: 1...500)
                Stepper(t("Minutes between emails") + ": \(gap)", value: $gap, in: 3...120)
                Text(t("Applications are sent by the server, within your plan and Gmail limits. Closing the app does not stop the server.")).font(.footnote).foregroundStyle(.secondary)
                Button(t("Save")) { busy = true; Task { defer { busy = false }; await store.perform { try await store.setAuto(["enabled": .bool(enabled), "min_match": .number(Double(match)), "daily_limit": .number(Double(limit)), "gap_minutes": .number(Double(gap))]); fill() } } }
            }.disabled(busy)
            if let url = Security.webURL(store.autoApply["upgrade_url"].text) { Section { Link(t("Upgrade"), destination: url) } }
            if busy { ProgressView() }
        }.navigationTitle(t("Auto apply")).task { await store.perform { try await store.refreshAuto(); fill() } }.refreshable { await store.perform { try await store.refreshAuto(); fill() } }
    }
    private func fill() { enabled = store.autoApply["enabled"].flag; match = min(95, max(40, store.autoApply["min_match"].integer)); limit = min(500, max(1, store.autoApply["daily_limit"].integer)); gap = min(120, max(3, store.autoApply["gap_minutes"].integer)) }
}

struct MailSettingsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var address = ""
    @State private var name = ""
    @State private var password = ""
    @State private var signature = ""
    @State private var busy = false
    @State private var disconnect = false
    @State private var saved = false
    var body: some View {
        Form {
            Section(t("Connect your Gmail")) {
                Text(t("Use the Gmail address you sign in with and a Google app password. Your normal password will not work."))
                TextField(t("Gmail address"), text: $address).keyboardType(.emailAddress).textInputAutocapitalization(.never).autocorrectionDisabled()
                TextField(t("Sender name"), text: $name).textContentType(.name)
                SecureField(t("16-letter app password"), text: $password).textContentType(.password).textInputAutocapitalization(.never).autocorrectionDisabled().privacySensitive()
                Link(t("Create a Google app password"), destination: URL(string: "https://myaccount.google.com/apppasswords")!)
            }
            Section(t("Email signature")) { TextEditor(text: $signature).frame(minHeight: 130); Button(t("Suggest from my CV")) { execute { let result = try await store.api.request("/v1/mail-account/signature"); try store.validateOwner(); signature = result["signature"].text } } }
            Section { Button(t("Save Gmail connection")) { execute {
                var fields: [String: JSON] = ["address": .string(address), "sender_name": .string(name), "signature": .string(signature)]
                if !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { fields["app_password"] = .string(password) }
                let result = try await store.api.request("/v1/mail-account", method: "PUT", json: .object(fields)); try store.validateOwner(); store.autoApply = result; password = ""; saved = true
            } }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || address.lowercased() != store.auth.email.lowercased() || signature.count > 600)
                if saved { Label(t("Saved"), systemImage: "checkmark.circle").foregroundStyle(.green) }
                if store.autoApply["email_connected"].flag || !store.autoApply["email"].isNull { Button(t("Disconnect Gmail"), role: .destructive) { disconnect = true } }
                if busy { ProgressView() }
            }
        }.navigationTitle(t("Gmail settings")).disabled(busy).onAppear { let email = store.autoApply["email"]; address = email["address"].text.isEmpty ? store.auth.email : email["address"].text; name = email["sender_name"].text; signature = email["signature"].text }.onDisappear { password = "" }
        .confirmationDialog(t("Disconnect Gmail and stop auto apply?"), isPresented: $disconnect, titleVisibility: .visible) { Button(t("Disconnect Gmail"), role: .destructive) { execute { _ = try await store.api.request("/v1/mail-account", method: "DELETE"); try await store.refreshAuto(); password = "" } } }
    }
    private func execute(_ action: @escaping () async throws -> Void) { busy = true; saved = false; Task { defer { busy = false }; await store.perform(action) } }
}

struct ApplicationsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var items: [JSON] = []
    @State private var cursor: String?
    @State private var busy = false
    @State private var error: String?
    var body: some View {
        List {
            if items.isEmpty && !busy { ContentUnavailableView(t("No applications yet"), systemImage: "paperplane", description: Text(t("Your tracked and emailed applications will appear here."))) }
            if let error { Text(t(error)); Button(t("Retry")) { Task { await load(reset: true) } } }
            ForEach(items) { item in
                NavigationLink { JobDetailView(job: Job(item["job"])) } label: { VStack(alignment: .leading, spacing: 6) { JobRow(job: Job(item["job"])); Text(t(item["status"].text) + " · " + t(item["method"].text)).font(.caption); if !item["error"].text.isEmpty { Text(t(item["error"].text)).font(.caption).foregroundStyle(.orange) } } }
                .swipeActions { if !(item["method"].text == "email" && ["sent", "sending", "queued"].contains(item["status"].text)) { Button(t("Remove"), role: .destructive) { Task { await store.perform { _ = try await store.api.request("/v1/applications/\(item["job"]["id"].text)", method: "DELETE"); await load(reset: true); store.revision += 1 } } } } }
            }
            if busy { ProgressView() }
            if cursor != nil && !busy { Button(t("Load more")) { Task { await load(reset: false) } } }
        }.navigationTitle(t("Applications")).task { await load(reset: true) }.refreshable { await load(reset: true) }
    }
    private func load(reset: Bool) async { busy = true; error = nil; defer { busy = false }; do { let result = try await store.api.request("/v1/applications", query: !reset && cursor != nil ? [.init(name: "cursor", value: cursor)] : []); try store.validateOwner(); var ids = Set((reset ? [] : items).map { $0["job"]["id"].text }); items = (reset ? [] : items) + result["items"].items.filter { ids.insert($0["job"]["id"].text).inserted }; cursor = result["next_cursor"].text.isEmpty ? nil : result["next_cursor"].text } catch { if !Task.isCancelled { self.error = AppStore.message(error) } } }
}

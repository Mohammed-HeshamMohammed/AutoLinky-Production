import Foundation
import UserNotifications
import BackgroundTasks
import AutoLinkyCore

enum ActivityNotifications {
    static let taskIdentifier = "com.autolinky.ios.activity"
    @MainActor static func enable(api: APIClient, uid: String) async throws {
        guard !uid.isEmpty, try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) else { throw APIError(status: 0, code: "notification_permission") }
        let existing = Keychain.read("activity-device").flatMap { try? JSONDecoder().decode(JSON.self, from: Data($0.utf8)) }
        if existing?["uid"].text != uid || existing?["base"].text != Configuration().api?.absoluteString {
            await disable(api: api)
            let device = try await api.request("/v1/devices", method: "POST", json: .object(["platform": .string("ios")]))
            let value: JSON = .object(["uid": .string(uid), "base": .string(Configuration().api?.absoluteString ?? ""), "id": device["device_id"], "token": device["token"]])
            try Keychain.save("activity-device", String(data: JSONEncoder().encode(value), encoding: .utf8))
        }
        UserDefaults.standard.set(Date().ISO8601Format(), forKey: "activity.after.\(uid)")
        schedule()
    }
    @MainActor static func disable(api: APIClient?) async {
        if let value = Keychain.read("activity-device"), let bytes = value.data(using: .utf8), let record = try? JSONDecoder().decode(JSON.self, from: bytes) {
            if let api { _ = try? await api.request("/v1/devices/\(record["id"].text)", method: "DELETE") }
            UserDefaults.standard.removeObject(forKey: "activity.after.\(record["uid"].text)")
        }
        try? Keychain.save("activity-device", nil)
        UserDefaults.standard.set(false, forKey: "notifications")
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    static func schedule() {
        guard UserDefaults.standard.bool(forKey: "notifications") || Keychain.read("activity-device") != nil else { return }
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier); request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }
    static func refresh() async {
        defer { schedule() }
        guard UserDefaults.standard.bool(forKey: "notifications"), let value = Keychain.read("activity-device"), let bytes = value.data(using: .utf8), let record = try? JSONDecoder().decode(JSON.self, from: bytes), let base = Security.apiBase(record["base"].text), record["token"].text.hasPrefix("dv1_") else { return }
        let uid = record["uid"].text
        do {
            let after = UserDefaults.standard.string(forKey: "activity.after.\(uid)") ?? Date().ISO8601Format()
            var request = URLRequest(url: try Security.endpoint(base: base, path: "/v1/device/activity", query: [.init(name: "after", value: after)]), cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
            request.setValue("Device \(record["token"].text)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await IsolatedSession.make().data(for: request)
            try Task.checkCancellation()
            guard Keychain.read("activity-device") == value else { return }
            if [401, 403].contains((response as? HTTPURLResponse)?.statusCode ?? 0) { await disable(api: nil); return }
            guard (response as? HTTPURLResponse)?.statusCode == 200, data.count <= 1024 * 1024 else { return }
            let result = try JSONDecoder().decode(JSON.self, from: data)
            await publish(result, uid: uid)
        } catch { }
    }
    @MainActor static func publish(_ result: JSON, uid: String) async {
        guard UserDefaults.standard.bool(forKey: "notifications"), let record = Keychain.read("activity-device"), let raw = record.data(using: .utf8), (try? JSONDecoder().decode(JSON.self, from: raw))?["uid"].text == uid else { return }
        let old = UserDefaults.standard.string(forKey: "activity.after.\(uid)") ?? ""
        let formatter = ISO8601DateFormatter(); formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let oldDate = formatter.date(from: old) ?? .distantPast
        let nowDate = formatter.date(from: result["now"].text) ?? .distantPast
        guard nowDate >= oldDate else { return }
        // Advance before awaiting notifications so a simultaneous foreground/background
        // response cannot deliver the same batch twice.
        if !result["now"].text.isEmpty { UserDefaults.standard.set(result["now"].text, forKey: "activity.after.\(uid)") }
        for item in result["items"].items where (formatter.date(from: item["at"].text) ?? .distantPast) > oldDate {
            guard !Task.isCancelled, Keychain.read("activity-device") == record else { return }
            let content = UNMutableNotificationContent()
            content.title = t(item["status"].text == "sent" ? "Application sent" : "Application needs attention")
            content.body = item["title"].text; content.sound = .default
            try? await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: item["job_id"].text + "-" + item["status"].text, content: content, trigger: nil))
        }
        if result["new_matches"].integer > 0 && nowDate > oldDate && Keychain.read("activity-device") == record {
            let content = UNMutableNotificationContent(); content.title = t("New matching jobs"); content.body = t("Open AutoLinky to see your latest opportunities.")
            try? await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "new-matches", content: content, trigger: nil))
        }
    }
}

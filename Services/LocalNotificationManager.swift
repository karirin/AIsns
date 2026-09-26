import Foundation
import UIKit
import UserNotifications

final class LocalNotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = LocalNotificationManager()

    enum Destination: String {
        case chat
        case notifications
    }

    /// 通知タップで開く画面。MainTabView が受け取ってタブを切り替え、nil に戻す。
    @MainActor @Published var pendingDestination: Destination?

    private let center = UNUserNotificationCenter.current()
    private let promptShownKey = "notification_context_prompt_shown_v1"
    private let morningIdentifier = "proactive.morning"
    private let nightIdentifier = "proactive.night"
    private let inactiveIdentifier = "proactive.inactive"

    private override init() {
        super.init()
        center.delegate = self
    }

    var hasShownContextPrompt: Bool {
        UserDefaults.standard.bool(forKey: promptShownKey)
    }

    func markContextPromptShown() {
        UserDefaults.standard.set(true, forKey: promptShownKey)
        AppAnalytics.logOnce(.notificationPermissionPrompt)
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            AppAnalytics.log(.notificationPermissionResult, parameters: ["granted": granted ? 1 : 0])
            return granted
        } catch {
            AppAnalytics.log(.notificationPermissionResult, parameters: ["granted": 0])
            return false
        }
    }

    func isAuthorized() async -> Bool {
        let status = await center.notificationSettings().authorizationStatus
        return status == .authorized || status == .provisional || status == .ephemeral
    }

    func notifyComment(from name: String, content: String, postID: UUID) async {
        await scheduleImmediate(
            identifier: "comment.\(postID.uuidString).\(UUID().uuidString)",
            title: name,
            body: "あなたの投稿にコメントしました「\(content)」",
            userInfo: ["destination": "notifications", "post_id": postID.uuidString]
        )
    }

    func notifyChat(from name: String, content: String, oshiID: UUID) async {
        await scheduleImmediate(
            identifier: "chat.\(oshiID.uuidString).\(UUID().uuidString)",
            title: name,
            body: content,
            userInfo: ["destination": "chat", "oshi_id": oshiID.uuidString]
        )
    }

    func refreshProactiveNotifications(oshi: OshiCharacter?) async {
        guard await isAuthorized(), let oshi else { return }
        center.removePendingNotificationRequests(
            withIdentifiers: [morningIdentifier, nightIdentifier, inactiveIdentifier]
        )

        scheduleCalendar(
            identifier: morningIdentifier,
            title: oshi.name,
            body: "おはよう。今日も少し話せたらうれしいな",
            hour: 8,
            minute: 15
        )
        scheduleCalendar(
            identifier: nightIdentifier,
            title: oshi.name,
            body: "今日もおつかれさま。眠る前に少しだけ話さない？",
            hour: 21,
            minute: 30
        )

        let inactiveContent = UNMutableNotificationContent()
        inactiveContent.title = oshi.name
        inactiveContent.body = "最近どうしてる？ また話せたらうれしいな"
        inactiveContent.sound = .default
        inactiveContent.userInfo = ["destination": "chat", "oshi_id": oshi.id.uuidString]
        let inactiveTrigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 3 * 24 * 60 * 60,
            repeats: false
        )
        try? await center.add(
            UNNotificationRequest(
                identifier: inactiveIdentifier,
                content: inactiveContent,
                trigger: inactiveTrigger
            )
        )
    }

    private func scheduleImmediate(
        identifier: String,
        title: String,
        body: String,
        userInfo: [AnyHashable: Any]
    ) async {
        guard await isAuthorized() else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        try? await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    private func scheduleCalendar(
        identifier: String,
        title: String,
        body: String,
        hour: Int,
        minute: Int
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["destination": "chat"]
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: DateComponents(hour: hour, minute: minute),
            repeats: true
        )
        center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let raw = response.notification.request.content.userInfo["destination"] as? String,
              let destination = Destination(rawValue: raw) else { return }
        await MainActor.run { pendingDestination = destination }
    }
}

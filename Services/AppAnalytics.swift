import FirebaseAnalytics
import Foundation

enum AppAnalytics {
    enum Event: String {
        case onboardingComplete = "onboarding_complete"
        case oshiCreated = "oshi_created"
        case firstPost = "first_post"
        case firstChat = "first_chat"
        case chatLimitHit = "chat_limit_hit"
        case paywallView = "paywall_view"
        case retentionD1 = "retention_d1"
        case retentionD7 = "retention_d7"
        case shareCard = "share_card"
        case notificationPermissionPrompt = "notification_permission_prompt"
        case notificationPermissionResult = "notification_permission_result"
    }

    private static let firstOpenKey = "analytics_first_open_date_v1"

    static func log(_ event: Event, parameters: [String: Any]? = nil) {
        Analytics.logEvent(event.rawValue, parameters: parameters)
    }

    static func logOnce(_ event: Event, parameters: [String: Any]? = nil) {
        let key = "analytics_once_\(event.rawValue)_v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        log(event, parameters: parameters)
    }

    static func recordLaunch(now: Date = Date(), calendar: Calendar = .current) {
        let defaults = UserDefaults.standard
        guard let firstOpen = defaults.object(forKey: firstOpenKey) as? Date else {
            defaults.set(now, forKey: firstOpenKey)
            return
        }

        let firstDay = calendar.startOfDay(for: firstOpen)
        let currentDay = calendar.startOfDay(for: now)
        let days = calendar.dateComponents([.day], from: firstDay, to: currentDay).day ?? 0
        if days == 1 { logOnce(.retentionD1, parameters: ["days_since_install": days]) }
        if days == 7 { logOnce(.retentionD7, parameters: ["days_since_install": days]) }
    }
}

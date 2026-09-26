import Combine
import Foundation

@MainActor
final class ReviewRequestManager: ObservableObject {
    struct Thresholds {
        static let minimumUsageDays = 3
        static let minimumSessions = 5
        static let minimumCompletedActions = 3
        static let cooldown: TimeInterval = 90 * 24 * 60 * 60
    }

    static let shared = ReviewRequestManager()

    @Published private(set) var requestRevision = 0

    private enum Key {
        static let usageDays = "review_request_usage_days_v1"
        static let sessionCount = "review_request_session_count_v1"
        static let completedActionCount = "review_request_completed_action_count_v1"
        static let lastRequestDate = "review_request_last_attempt_date_v1"
        static let lastRequestedVersion = "review_request_last_attempt_version_v1"
    }

    private let defaults: UserDefaults
    private let calendar: Calendar
    private let appVersion: () -> String
    private var recordedCurrentSession = false
    private var hasPendingRequest = false

    init(
        defaults: UserDefaults = .standard,
        calendar: Calendar = .current,
        appVersion: @escaping () -> String = {
            Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        }
    ) {
        self.defaults = defaults
        self.calendar = calendar
        self.appVersion = appVersion
    }

    /// 1プロセスにつき1セッションとして記録する。起動直後には評価依頼を判定しない。
    func recordAppSession(now: Date = Date()) {
        guard !recordedCurrentSession else { return }
        recordedCurrentSession = true

        defaults.set(defaults.integer(forKey: Key.sessionCount) + 1, forKey: Key.sessionCount)

        var usageDays = Set(defaults.stringArray(forKey: Key.usageDays) ?? [])
        usageDays.insert(dayIdentifier(for: now))
        defaults.set(Array(usageDays).sorted(), forKey: Key.usageDays)
    }

    /// 投稿保存やAI返信の保存が完了し、操作が一区切りついた時だけ呼ぶ。
    func recordMeaningfulCompletion(now: Date = Date()) {
        defaults.set(
            defaults.integer(forKey: Key.completedActionCount) + 1,
            forKey: Key.completedActionCount
        )

        guard !hasPendingRequest, isEligible(now: now) else { return }
        hasPendingRequest = true
        requestRevision += 1
    }

    /// StoreKitの呼び出しを「表示完了」とは扱わず、依頼を試みた日時だけを保存する。
    func consumePendingRequest(now: Date = Date()) -> Bool {
        guard hasPendingRequest, isEligible(now: now) else { return false }
        hasPendingRequest = false
        defaults.set(now, forKey: Key.lastRequestDate)
        defaults.set(appVersion(), forKey: Key.lastRequestedVersion)
        return true
    }

    func isEligible(now: Date = Date()) -> Bool {
        let usageDayCount = Set(defaults.stringArray(forKey: Key.usageDays) ?? []).count
        guard usageDayCount >= Thresholds.minimumUsageDays else { return false }
        guard defaults.integer(forKey: Key.sessionCount) >= Thresholds.minimumSessions else { return false }
        guard defaults.integer(forKey: Key.completedActionCount) >= Thresholds.minimumCompletedActions else { return false }
        guard defaults.string(forKey: Key.lastRequestedVersion) != appVersion() else { return false }

        if let lastRequestDate = defaults.object(forKey: Key.lastRequestDate) as? Date,
           now.timeIntervalSince(lastRequestDate) < Thresholds.cooldown {
            return false
        }

        return true
    }

    private func dayIdentifier(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }
}

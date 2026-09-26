import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

@MainActor
final class DailyEngagementStore: ObservableObject {
    static let shared = DailyEngagementStore()
    static let appGroupID = "group.Swift-Beginners-app.AIsns"

    @Published private(set) var streak: Int = 0
    @Published private(set) var todayTopic: String = ""

    private let streakKey = "daily_activity_streak_v1"
    private let lastActivityKey = "daily_activity_last_date_v1"
    private let topicKey = "widget_daily_topic"
    private let speakerKey = "widget_daily_speaker"

    private let topics = [
        "今日のランチ、何を食べた？",
        "今日ちょっと嬉しかったこと、教えて",
        "今いちばん聴きたい曲は？",
        "今日の自分を褒めるなら、どんなところ？",
        "最近ハマっているもの、ある？",
        "いま行ってみたい場所はどこ？",
        "今日いちばん印象に残った出来事は？"
    ]

    private init() {
        streak = UserDefaults.standard.integer(forKey: streakKey)
        todayTopic = topic(for: Date())
    }

    func recordActivity(now: Date = Date()) {
        let defaults = UserDefaults.standard
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)

        if let last = defaults.object(forKey: lastActivityKey) as? Date {
            let lastDay = calendar.startOfDay(for: last)
            let distance = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if distance == 1 { streak += 1 }
            if distance > 1 { streak = 1 }
        } else {
            streak = 1
        }

        defaults.set(today, forKey: lastActivityKey)
        defaults.set(streak, forKey: streakKey)
        todayTopic = topic(for: now)
    }

    func updateWidget(oshiName: String?, message: String? = nil) {
        let defaults = UserDefaults(suiteName: Self.appGroupID) ?? .standard
        if let message {
            defaults.set(message, forKey: topicKey)
        } else if defaults.string(forKey: topicKey) == nil {
            defaults.set(todayTopic, forKey: topicKey)
        }
        defaults.set(oshiName ?? "推し", forKey: speakerKey)
#if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "AImateHitokotoWidget")
#endif
    }

    private func topic(for date: Date) -> String {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0
        return topics[day % topics.count]
    }
}

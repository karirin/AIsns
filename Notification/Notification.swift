// Notification/Notification.swift

import Foundation

// MARK: - Notification Model

enum NotificationCategory: String, Codable {
    case me = "me"
    case createdOshi = "createdOshi"
}

/// 通知の種類
enum NotificationType: String, Codable {
    case reaction = "いいね"
    case comment = "コメント"
    case mention = "メンション"   // 将来対応
    case follow = "フォロー"
    
    var icon: String {
        switch self {
        case .reaction: return "heart.fill"
        case .comment: return "bubble.left.fill"
        case .mention: return "at"
        case .follow: return "person.fill.badge.plus"
        // 削除されたcaseの処理も削除
        }
    }
    
    var color: String {
        switch self {
        case .reaction: return "pink"
        case .comment: return "blue"
        case .mention: return "purple"
        case .follow: return "green"
        // 削除されたcaseの処理も削除
        }
    }
    
    var canGroup: Bool {
        switch self {
        case .reaction, .comment, .follow:
            return true
        default:
            return false
        }
    }
}

struct AppNotification: Identifiable, Codable {
    let id: UUID
    let type: NotificationType
    var senderId: UUID
    var senderName: String
    var content: String
    var relatedPostId: UUID?
    var timestamp: Date
    var isRead: Bool
    var category: NotificationCategory
    var targetOshiName: String?
    
    init(
        id: UUID = UUID(),
        type: NotificationType,
        senderId: UUID,
        senderName: String,
        content: String,
        relatedPostId: UUID? = nil,
        timestamp: Date = Date(),
        isRead: Bool = false,
        category: NotificationCategory = .me,
        targetOshiName: String? = nil
    ) {
        self.id = id
        self.type = type
        self.senderId = senderId
        self.senderName = senderName
        self.content = content
        self.relatedPostId = relatedPostId
        self.timestamp = timestamp
        self.isRead = isRead
        self.category = category
        self.targetOshiName = targetOshiName
    }
    
    var message: String {
        switch category {
        case .me:
            switch type {
            case .reaction:
                return "\(senderName)があなたの投稿にいいねしました"
            case .comment:
                return "\(senderName)があなたの投稿にコメントしました"
            case .mention:
                return "\(senderName)があなたをメンションしました"
            case .follow:
                return "\(senderName)があなたをフォローしました"
            // 削除されたcaseの処理も削除
            }
        case .createdOshi:
            let targetName = targetOshiName ?? "あなたのAI"
            switch type {
            case .reaction:
                return "\(senderName)が\(targetName)の投稿にいいねしました"
            case .comment:
                return "\(senderName)が\(targetName)の投稿にコメントしました"
            case .follow:
                return "\(senderName)が\(targetName)をフォローしました"
            default:
                return "\(senderName)が\(targetName)に反応しました"
            }
        }
    }
}

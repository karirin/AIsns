//
//  Notification.swift
//  AIsns
//
//  Created by Apple on 2025/12/23.
//

import Foundation

// MARK: - Notification Model

/// 通知のカテゴリー
enum NotificationCategory: String, Codable {
    case me = "me"                 // 自分への通知
    case createdOshi = "createdOshi" // 作成したAIへの反応
}

/// 通知の種類
enum NotificationType: String, Codable {
    case reaction = "いいね"      // 投稿にいいねされた
    case comment = "コメント"     // 投稿にコメントされた
    case mention = "メンション"   // メンションされた（将来対応）
    case follow = "フォロー"      // フォローされた（将来対応）
    case chat = "チャット"        // 新しいメッセージ
    case oshiPost = "推しの投稿"  // 推しが投稿した
    
    var icon: String {
        switch self {
        case .reaction: return "heart.fill"
        case .comment: return "bubble.left.fill"
        case .mention: return "at"
        case .follow: return "person.fill.badge.plus"
        case .chat: return "message.fill"
        case .oshiPost: return "star.fill"
        }
    }
    
    var color: String {
        switch self {
        case .reaction: return "pink"
        case .comment: return "blue"
        case .mention: return "purple"
        case .follow: return "green"
        case .chat: return "orange"
        case .oshiPost: return "yellow"
        }
    }
    
    /// 同じ投稿に対する通知をグループ化できるか
    var canGroup: Bool {
        switch self {
        case .reaction, .comment, .follow:
            return true
        default:
            return false
        }
    }
}

/// 通知モデル
struct AppNotification: Identifiable, Codable {
    let id: UUID
    let type: NotificationType
    var senderId: UUID         // 送信者のID（推しのID）
    var senderName: String     // 送信者の名前
    var content: String        // 通知内容
    var relatedPostId: UUID?   // 関連する投稿ID
    var timestamp: Date
    var isRead: Bool
    
    // カテゴリ分け用
    var category: NotificationCategory
    var targetOshiName: String? // 対象のAI名（category == .createdOshi の場合）
    
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
    
    /// 通知メッセージの生成
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
            case .chat:
                return "\(senderName)からメッセージが届きました"
            case .oshiPost:
                return "\(senderName)が投稿しました"
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

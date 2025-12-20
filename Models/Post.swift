import Foundation

// 投稿モデル
struct Post: Identifiable, Codable {
    let id: UUID
    var authorId: UUID? // nil = ユーザー投稿
    var authorName: String
    var content: String
    var timestamp: Date
    var reactions: [Reaction]
    var comments: [Comment]
    var isUserPost: Bool
    
    init(id: UUID = UUID(), authorId: UUID? = nil, authorName: String, 
         content: String, timestamp: Date = Date(), isUserPost: Bool = true) {
        self.id = id
        self.authorId = authorId
        self.authorName = authorName
        self.content = content
        self.timestamp = timestamp
        self.reactions = []
        self.comments = []
        self.isUserPost = isUserPost
    }
}

// リアクション
struct Reaction: Identifiable, Codable {
    let id: UUID
    let oshiId: UUID
    let oshiName: String
    let emoji: String
    let timestamp: Date
    
    init(id: UUID = UUID(), oshiId: UUID, oshiName: String, 
         emoji: String = "❤️", timestamp: Date = Date()) {
        self.id = id
        self.oshiId = oshiId
        self.oshiName = oshiName
        self.emoji = emoji
        self.timestamp = timestamp
    }
}

// コメント
struct Comment: Identifiable, Codable {
    let id: UUID
    let oshiId: UUID
    let oshiName: String
    let content: String
    let timestamp: Date
    
    init(id: UUID = UUID(), oshiId: UUID, oshiName: String, 
         content: String, timestamp: Date = Date()) {
        self.id = id
        self.oshiId = oshiId
        self.oshiName = oshiName
        self.content = content
        self.timestamp = timestamp
    }
}

// チャットメッセージ
struct Message: Identifiable, Codable {
    let id: UUID
    var content: String
    var isFromUser: Bool
    var oshiId: UUID?
    var timestamp: Date
    var isRead: Bool
    
    init(id: UUID = UUID(), content: String, isFromUser: Bool, 
         oshiId: UUID? = nil, timestamp: Date = Date(), isRead: Bool = false) {
        self.id = id
        self.content = content
        self.isFromUser = isFromUser
        self.oshiId = oshiId
        self.timestamp = timestamp
        self.isRead = isRead
    }
}

// チャットルーム
struct ChatRoom: Identifiable, Codable {
    let id: UUID
    var oshiId: UUID
    var messages: [Message]
    var lastMessageDate: Date?
    var unreadCount: Int
    
    init(id: UUID = UUID(), oshiId: UUID, messages: [Message] = [], 
         lastMessageDate: Date? = nil, unreadCount: Int = 0) {
        self.id = id
        self.oshiId = oshiId
        self.messages = messages
        self.lastMessageDate = lastMessageDate
        self.unreadCount = unreadCount
    }
    
    mutating func addMessage(_ message: Message) {
        messages.append(message)
        lastMessageDate = message.timestamp
        if !message.isFromUser && !message.isRead {
            unreadCount += 1
        }
    }
    
    mutating func markAllAsRead() {
        for index in messages.indices {
            messages[index].isRead = true
        }
        unreadCount = 0
    }
}

// ユーザーの感情状態（投稿から推測）
enum UserMood: String, Codable {
    case happy = "嬉しい"
    case tired = "疲れている"
    case sad = "落ち込んでいる"
    case excited = "テンション高め"
    case normal = "普通"
    case stressed = "ストレス"
}

import Foundation
import FirebaseDatabase

/// 最適化されたFirebase Database Manager
class FirebaseDatabaseManager {
    static let shared = FirebaseDatabaseManager()
    
    private let ref: DatabaseReference
    private let userId: String
    
    private init() {
        self.ref = FirebaseConfig.shared.databaseRef
        self.userId = FirebaseConfig.shared.userId
    }
    
    // MARK: - Oshi Character (変更なし)
    
    func saveOshi(_ oshi: OshiCharacter) async throws {
        let oshiRef = ref.child("users/\(userId)/oshiList/\(oshi.id.uuidString)")
        
        var oshiData: [String: Any] = [
            "id": oshi.id.uuidString,
            "name": oshi.name,
            "personality": oshi.personality.rawValue,
            "speechCharacteristics": oshi.speechCharacteristics,
            "userCallingName": oshi.userCallingName,
            "speechStyle": oshi.speechStyle.rawValue,
            "relationshipDistance": oshi.relationshipDistance.rawValue,
            "worldSetting": oshi.worldSetting.rawValue,
            "ngTopics": oshi.ngTopics,
            "avatarColor": oshi.avatarColor,
            "createdAt": oshi.createdAt.timeIntervalSince1970,
            "intimacyLevel": oshi.intimacyLevel,
            "totalInteractions": oshi.totalInteractions,
            "lastInteractionDate": oshi.lastInteractionDate?.timeIntervalSince1970 ?? 0
        ]
        
        if let gender = oshi.gender {
            oshiData["gender"] = gender.rawValue
        }
        
        if let imageURL = oshi.avatarImageURL {
            oshiData["avatarImageURL"] = imageURL
        }
        
        try await oshiRef.setValue(oshiData)
    }
    
    func loadOshiList() async throws -> [OshiCharacter] {
        let snapshot = try await ref.child("users/\(userId)/oshiList").getData()
        
        guard let value = snapshot.value as? [String: [String: Any]] else {
            return []
        }
        
        var oshiList: [OshiCharacter] = []
        
        for (_, oshiData) in value {
            if let oshi = parseOshiCharacter(from: oshiData) {
                oshiList.append(oshi)
            }
        }
        
        return oshiList.sorted { $0.createdAt > $1.createdAt }
    }
    
    func deleteOshi(_ oshiId: UUID) async throws {
        try? await FirebaseStorageManager.shared.deleteOshiAvatar(oshiId: oshiId)
        
        let oshiRef = ref.child("users/\(userId)/oshiList/\(oshiId.uuidString)")
        try await oshiRef.removeValue()
        
        // 投稿から推しの投稿を削除
        let postsSnapshot = try await ref.child("users/\(userId)/posts").getData()
        if let posts = postsSnapshot.value as? [String: [String: Any]] {
            for (postId, postData) in posts {
                if let authorId = postData["authorId"] as? String, authorId == oshiId.uuidString {
                    // 投稿本体を削除
                    try await ref.child("users/\(userId)/posts/\(postId)").removeValue()
                    // リアクション・コメントも削除
                    try await ref.child("users/\(userId)/reactions/\(postId)").removeValue()
                    try await ref.child("users/\(userId)/comments/\(postId)").removeValue()
                }
            }
        }
    }
    
    // MARK: - Posts (最適化版)
    
    /// 投稿を保存（リアクション・コメントは含まない）
    func savePost(_ post: Post) async throws {
        let postRef = ref.child("users/\(userId)/posts/\(post.id.uuidString)")
        
        let postData: [String: Any] = [
            "id": post.id.uuidString,
            "authorId": post.authorId?.uuidString ?? "",
            "authorName": post.authorName,
            "content": post.content,
            "timestamp": post.timestamp.timeIntervalSince1970,
            "isUserPost": post.isUserPost,
            "reactionCount": post.reactionCount,
            "commentCount": post.commentCount
        ]
        
        try await postRef.setValue(postData)
    }
    
    /// 投稿リストを取得（軽量・件数のみ）
    func loadPosts(limit: Int = 50) async throws -> [Post] {
        let snapshot = try await ref.child("users/\(userId)/posts")
            .queryOrdered(byChild: "timestamp")
            .queryLimited(toLast: UInt(limit))
            .getData()
        
        guard let value = snapshot.value as? [String: [String: Any]] else {
            return []
        }
        
        var posts: [Post] = []
        
        for (_, postData) in value {
            if let post = parsePost(from: postData) {
                posts.append(post)
            }
        }
        
        return posts.sorted { $0.timestamp > $1.timestamp }
    }
    
    /// 投稿を更新（主にカウント更新用）
    func updatePost(_ post: Post) async throws {
        try await savePost(post)
    }
    
    // MARK: - Reactions (新規実装)
    
    /// リアクションを追加
    func addReaction(_ reaction: Reaction, to postId: UUID) async throws {
        // 1. リアクションを保存（oshiIdをキーにして重複防止）
        let reactionRef = ref.child("users/\(userId)/reactions/\(postId.uuidString)/\(reaction.oshiId.uuidString)")
        
        let reactionData: [String: Any] = [
            "id": reaction.id.uuidString,
            "oshiId": reaction.oshiId.uuidString,
            "oshiName": reaction.oshiName,
            "emoji": reaction.emoji,
            "timestamp": reaction.timestamp.timeIntervalSince1970
        ]
        
        try await reactionRef.setValue(reactionData)
        
        // 2. 投稿のreactionCountをインクリメント
        let countRef = ref.child("users/\(userId)/posts/\(postId.uuidString)/reactionCount")
        try await countRef.setValue(ServerValue.increment(1))
    }
    
    /// 特定投稿のリアクションを全取得
    func loadReactions(for postId: UUID) async throws -> [Reaction] {
        do {
            let snapshot = try await ref.child("users/\(userId)/reactions/\(postId.uuidString)").getData()
            
            guard let value = snapshot.value as? [String: [String: Any]] else {
                return []
            }
            
            var reactions: [Reaction] = []
            
            for (_, reactionData) in value {
                if let reaction = parseReaction(from: reactionData) {
                    reactions.append(reaction)
                }
            }
            
            return reactions.sorted { $0.timestamp > $1.timestamp }
        } catch let error as NSError {
            // オフラインエラーの場合は空配列を返す
            if error.domain == "com.firebase.core" && error.code == 1 {
                print("⚠️ リアクション読み込みスキップ: \(error.localizedDescription)")
                return []
            }
            throw error
        }
    }
    
    /// リアクションを削除
    func removeReaction(oshiId: UUID, from postId: UUID) async throws {
        // 1. リアクションを削除
        let reactionRef = ref.child("users/\(userId)/reactions/\(postId.uuidString)/\(oshiId.uuidString)")
        try await reactionRef.removeValue()
        
        // 2. 投稿のreactionCountをデクリメント
        let countRef = ref.child("users/\(userId)/posts/\(postId.uuidString)/reactionCount")
        try await countRef.setValue(ServerValue.increment(-1))
    }
    
    // MARK: - Comments (新規実装)
    
    /// コメントを追加
    func addComment(_ comment: Comment, to postId: UUID) async throws {
        // 1. コメントを保存
        let commentRef = ref.child("users/\(userId)/comments/\(postId.uuidString)/\(comment.id.uuidString)")
        
        let commentData: [String: Any] = [
            "id": comment.id.uuidString,
            "oshiId": comment.oshiId.uuidString,
            "oshiName": comment.oshiName,
            "content": comment.content,
            "timestamp": comment.timestamp.timeIntervalSince1970
        ]
        
        try await commentRef.setValue(commentData)
        
        // 2. 投稿のcommentCountをインクリメント
        let countRef = ref.child("users/\(userId)/posts/\(postId.uuidString)/commentCount")
        try await countRef.setValue(ServerValue.increment(1))
    }
    
    /// 特定投稿のコメントを取得（ページネーション対応）
    func loadComments(for postId: UUID, limit: Int = 10, before: Date? = nil) async throws -> [Comment] {
        var query = ref.child("users/\(userId)/comments/\(postId.uuidString)")
            .queryOrdered(byChild: "timestamp")
        
        if let before = before {
            query = query.queryEnding(atValue: before.timeIntervalSince1970)
        }
        
        query = query.queryLimited(toLast: UInt(limit))
        
        do {
            let snapshot = try await query.getData()
            
            guard let value = snapshot.value as? [String: [String: Any]] else {
                return []
            }
            
            var comments: [Comment] = []
            
            for (_, commentData) in value {
                if let comment = parseComment(from: commentData) {
                    comments.append(comment)
                }
            }
            
            return comments.sorted { $0.timestamp < $1.timestamp } // 古い順
        } catch let error as NSError {
            // インデックスエラーまたはオフラインエラーの場合は空配列を返す
            if error.domain == "com.firebase.core" && error.code == 1 {
                print("⚠️ コメント読み込みスキップ: \(error.localizedDescription)")
                return []
            }
            throw error
        }
    }

    /// コメントを削除
    func removeComment(_ commentId: UUID, from postId: UUID) async throws {
        // 1. コメントを削除
        let commentRef = ref.child("users/\(userId)/comments/\(postId.uuidString)/\(commentId.uuidString)")
        try await commentRef.removeValue()
        
        // 2. 投稿のcommentCountをデクリメント
        let countRef = ref.child("users/\(userId)/posts/\(postId.uuidString)/commentCount")
        try await countRef.setValue(ServerValue.increment(-1))
    }
    
    // MARK: - Chat Rooms (変更なし)
    
    func saveChatRoom(_ chatRoom: ChatRoom) async throws {
        let roomRef = ref.child("users/\(userId)/chatRooms/\(chatRoom.oshiId.uuidString)")
        
        let roomData: [String: Any] = [
            "id": chatRoom.id.uuidString,
            "oshiId": chatRoom.oshiId.uuidString,
            "lastMessageDate": chatRoom.lastMessageDate?.timeIntervalSince1970 ?? 0,
            "unreadCount": chatRoom.unreadCount
        ]
        
        try await roomRef.setValue(roomData)
        
        let messagesRef = ref.child("users/\(userId)/messages/\(chatRoom.oshiId.uuidString)")
        
        for message in chatRoom.messages.suffix(100) {
            let messageData: [String: Any] = [
                "id": message.id.uuidString,
                "content": message.content,
                "isFromUser": message.isFromUser,
                "oshiId": message.oshiId?.uuidString ?? "",
                "timestamp": message.timestamp.timeIntervalSince1970,
                "isRead": message.isRead
            ]
            
            try await messagesRef.child(message.id.uuidString).setValue(messageData)
        }
    }
    
    func loadChatRooms() async throws -> [ChatRoom] {
        let roomsSnapshot = try await ref.child("users/\(userId)/chatRooms").getData()
        
        guard let roomsValue = roomsSnapshot.value as? [String: [String: Any]] else {
            return []
        }
        
        var chatRooms: [ChatRoom] = []
        
        for (oshiIdString, roomData) in roomsValue {
            guard let id = UUID(uuidString: roomData["id"] as? String ?? ""),
                  let oshiId = UUID(uuidString: oshiIdString) else {
                continue
            }
            
            let messagesSnapshot = try await ref.child("users/\(userId)/messages/\(oshiIdString)").getData()
            var messages: [Message] = []
            
            if let messagesValue = messagesSnapshot.value as? [String: [String: Any]] {
                for (_, messageData) in messagesValue {
                    if let message = parseMessage(from: messageData) {
                        messages.append(message)
                    }
                }
            }
            
            messages.sort { $0.timestamp < $1.timestamp }
            
            let lastMessageDate = (roomData["lastMessageDate"] as? TimeInterval).flatMap {
                $0 > 0 ? Date(timeIntervalSince1970: $0) : nil
            }
            
            let chatRoom = ChatRoom(
                id: id,
                oshiId: oshiId,
                messages: messages,
                lastMessageDate: lastMessageDate,
                unreadCount: roomData["unreadCount"] as? Int ?? 0
            )
            
            chatRooms.append(chatRoom)
        }
        
        return chatRooms
    }
    
    func addMessage(to oshiId: UUID, message: Message) async throws {
        let messageRef = ref.child("users/\(userId)/messages/\(oshiId.uuidString)/\(message.id.uuidString)")
        
        let messageData: [String: Any] = [
            "id": message.id.uuidString,
            "content": message.content,
            "isFromUser": message.isFromUser,
            "oshiId": message.oshiId?.uuidString ?? "",
            "timestamp": message.timestamp.timeIntervalSince1970,
            "isRead": message.isRead
        ]
        
        try await messageRef.setValue(messageData)
        
        let roomRef = ref.child("users/\(userId)/chatRooms/\(oshiId.uuidString)")
        try await roomRef.updateChildValues([
            "lastMessageDate": message.timestamp.timeIntervalSince1970
        ])
        
        if !message.isFromUser {
            let unreadRef = roomRef.child("unreadCount")
            try await unreadRef.setValue(ServerValue.increment(1))
        }
    }
    
    func markChatAsRead(oshiId: UUID) async throws {
        let roomRef = ref.child("users/\(userId)/chatRooms/\(oshiId.uuidString)")
        try await roomRef.updateChildValues(["unreadCount": 0])
        
        let messagesRef = ref.child("users/\(userId)/messages/\(oshiId.uuidString)")
        let snapshot = try await messagesRef.getData()
        
        if let messages = snapshot.value as? [String: [String: Any]] {
            for (messageId, _) in messages {
                try await messagesRef.child(messageId).updateChildValues(["isRead": true])
            }
        }
    }
    
    // MARK: - Helpers
    
    private func parseOshiCharacter(from data: [String: Any]) -> OshiCharacter? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = data["name"] as? String,
              let personalityRaw = data["personality"] as? String,
              let personality = PersonalityType(rawValue: personalityRaw),
              let speechStyleRaw = data["speechStyle"] as? String,
              let speechStyle = SpeechStyle(rawValue: speechStyleRaw),
              let relationshipDistanceRaw = data["relationshipDistance"] as? String,
              let relationshipDistance = RelationshipDistance(rawValue: relationshipDistanceRaw),
              let worldSettingRaw = data["worldSetting"] as? String,
              let worldSetting = WorldSetting(rawValue: worldSettingRaw),
              let avatarColor = data["avatarColor"] as? String,
              let createdAtTimestamp = data["createdAt"] as? TimeInterval else {
            return nil
        }
        
        let genderRaw = data["gender"] as? String
        let gender = genderRaw.flatMap { Gender(rawValue: $0) }
        let speechCharacteristics = data["speechCharacteristics"] as? String ?? ""
        let userCallingName = data["userCallingName"] as? String ?? ""
        let ngTopics = data["ngTopics"] as? [String] ?? []
        let intimacyLevel = data["intimacyLevel"] as? Int ?? 0
        let totalInteractions = data["totalInteractions"] as? Int ?? 0
        let lastInteractionTimestamp = data["lastInteractionDate"] as? TimeInterval ?? 0
        let avatarImageURL = data["avatarImageURL"] as? String
        
        var oshi = OshiCharacter(
            id: id,
            name: name,
            gender: gender,
            personality: personality,
            speechCharacteristics: speechCharacteristics,
            userCallingName: userCallingName,
            speechStyle: speechStyle,
            relationshipDistance: relationshipDistance,
            worldSetting: worldSetting,
            ngTopics: ngTopics,
            avatarColor: avatarColor,
            avatarImageURL: avatarImageURL
        )
        
        oshi.intimacyLevel = intimacyLevel
        oshi.totalInteractions = totalInteractions
        oshi.lastInteractionDate = lastInteractionTimestamp > 0 ? Date(timeIntervalSince1970: lastInteractionTimestamp) : nil
        
        return oshi
    }
    
    private func parsePost(from data: [String: Any]) -> Post? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let authorName = data["authorName"] as? String,
              let content = data["content"] as? String,
              let timestampInterval = data["timestamp"] as? TimeInterval,
              let isUserPost = data["isUserPost"] as? Bool else {
            return nil
        }
        
        let authorId = (data["authorId"] as? String).flatMap { UUID(uuidString: $0) }
        let timestamp = Date(timeIntervalSince1970: timestampInterval)
        let reactionCount = data["reactionCount"] as? Int ?? 0
        let commentCount = data["commentCount"] as? Int ?? 0
        
        var post = Post(
            id: id,
            authorId: authorId,
            authorName: authorName,
            content: content,
            timestamp: timestamp,
            isUserPost: isUserPost
        )
        
        post.reactionCount = reactionCount
        post.commentCount = commentCount
        
        return post
    }
    
    private func parseMessage(from data: [String: Any]) -> Message? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let content = data["content"] as? String,
              let isFromUser = data["isFromUser"] as? Bool,
              let timestampInterval = data["timestamp"] as? TimeInterval else {
            return nil
        }
        
        let oshiId = (data["oshiId"] as? String).flatMap { UUID(uuidString: $0) }
        let timestamp = Date(timeIntervalSince1970: timestampInterval)
        let isRead = data["isRead"] as? Bool ?? false
        
        return Message(
            id: id,
            content: content,
            isFromUser: isFromUser,
            oshiId: oshiId,
            timestamp: timestamp,
            isRead: isRead
        )
    }
    
    private func parseReaction(from data: [String: Any]) -> Reaction? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let oshiIdString = data["oshiId"] as? String,
              let oshiId = UUID(uuidString: oshiIdString),
              let oshiName = data["oshiName"] as? String,
              let emoji = data["emoji"] as? String,
              let timestampInterval = data["timestamp"] as? TimeInterval else {
            return nil
        }
        
        let timestamp = Date(timeIntervalSince1970: timestampInterval)
        
        return Reaction(id: id, oshiId: oshiId, oshiName: oshiName, emoji: emoji, timestamp: timestamp)
    }
    
    private func parseComment(from data: [String: Any]) -> Comment? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let oshiIdString = data["oshiId"] as? String,
              let oshiId = UUID(uuidString: oshiIdString),
              let oshiName = data["oshiName"] as? String,
              let content = data["content"] as? String,
              let timestampInterval = data["timestamp"] as? TimeInterval else {
            return nil
        }
        
        let timestamp = Date(timeIntervalSince1970: timestampInterval)
        
        return Comment(id: id, oshiId: oshiId, oshiName: oshiName, content: content, timestamp: timestamp)
    }
}

import Foundation
import FirebaseDatabase

class FirebaseDatabaseManager {
    static let shared = FirebaseDatabaseManager()
    
    private let ref: DatabaseReference
    private let userId: String
    
    private init() {
        self.ref = FirebaseConfig.shared.databaseRef
        self.userId = FirebaseConfig.shared.userId
    }
    
    // MARK: - Oshi Character
    
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
        
        // 性別がnilでない場合のみ保存
        if let gender = oshi.gender {
            oshiData["gender"] = gender.rawValue
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
        let oshiRef = ref.child("users/\(userId)/oshiList/\(oshiId.uuidString)")
        try await oshiRef.removeValue()
        
        // 関連データも削除
        try await ref.child("users/\(userId)/chatRooms/\(oshiId.uuidString)").removeValue()
        
        // 投稿から推しの投稿を削除
        let postsSnapshot = try await ref.child("users/\(userId)/posts").getData()
        if let posts = postsSnapshot.value as? [String: [String: Any]] {
            for (postId, postData) in posts {
                if let authorId = postData["authorId"] as? String, authorId == oshiId.uuidString {
                    try await ref.child("users/\(userId)/posts/\(postId)").removeValue()
                }
            }
        }
    }
    
    // MARK: - Posts
    
    func savePost(_ post: Post) async throws {
        let postRef = ref.child("users/\(userId)/posts/\(post.id.uuidString)")
        
        let postData: [String: Any] = [
            "id": post.id.uuidString,
            "authorId": post.authorId?.uuidString ?? "",
            "authorName": post.authorName,
            "content": post.content,
            "timestamp": post.timestamp.timeIntervalSince1970,
            "isUserPost": post.isUserPost,
            "reactions": post.reactions.map { reactionToDict($0) },
            "comments": post.comments.map { commentToDict($0) }
        ]
        
        try await postRef.setValue(postData)
    }
    
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
    
    func updatePost(_ post: Post) async throws {
        try await savePost(post)
    }
    
    // MARK: - Chat Rooms
    
    func saveChatRoom(_ chatRoom: ChatRoom) async throws {
        let roomRef = ref.child("users/\(userId)/chatRooms/\(chatRoom.oshiId.uuidString)")
        
        let roomData: [String: Any] = [
            "id": chatRoom.id.uuidString,
            "oshiId": chatRoom.oshiId.uuidString,
            "lastMessageDate": chatRoom.lastMessageDate?.timeIntervalSince1970 ?? 0,
            "unreadCount": chatRoom.unreadCount
        ]
        
        try await roomRef.setValue(roomData)
        
        // メッセージは別ノードに保存（効率化のため）
        let messagesRef = ref.child("users/\(userId)/messages/\(chatRoom.oshiId.uuidString)")
        
        for message in chatRoom.messages.suffix(100) { // 最新100件のみ保存
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
            
            // メッセージを読み込み
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
        
        // チャットルームのlastMessageDateを更新
        let roomRef = ref.child("users/\(userId)/chatRooms/\(oshiId.uuidString)")
        try await roomRef.updateChildValues([
            "lastMessageDate": message.timestamp.timeIntervalSince1970
        ])
        
        // 未読カウントを更新
        if !message.isFromUser {
            let unreadRef = roomRef.child("unreadCount")
            try await unreadRef.setValue(ServerValue.increment(1))
        }
    }
    
    func markChatAsRead(oshiId: UUID) async throws {
        let roomRef = ref.child("users/\(userId)/chatRooms/\(oshiId.uuidString)")
        try await roomRef.updateChildValues(["unreadCount": 0])
        
        // すべてのメッセージを既読に
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
        
        // 新しいフィールドの読み込み（オプショナル）
        let genderRaw = data["gender"] as? String
        let gender = genderRaw.flatMap { Gender(rawValue: $0) }
        let speechCharacteristics = data["speechCharacteristics"] as? String ?? ""
        let userCallingName = data["userCallingName"] as? String ?? ""
        
        let ngTopics = data["ngTopics"] as? [String] ?? []
        let intimacyLevel = data["intimacyLevel"] as? Int ?? 0
        let totalInteractions = data["totalInteractions"] as? Int ?? 0
        let lastInteractionTimestamp = data["lastInteractionDate"] as? TimeInterval ?? 0
        
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
            avatarColor: avatarColor
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
        
        var post = Post(
            id: id,
            authorId: authorId,
            authorName: authorName,
            content: content,
            timestamp: timestamp,
            isUserPost: isUserPost
        )
        
        if let reactionsData = data["reactions"] as? [[String: Any]] {
            post.reactions = reactionsData.compactMap { parseReaction(from: $0) }
        }
        
        if let commentsData = data["comments"] as? [[String: Any]] {
            post.comments = commentsData.compactMap { parseComment(from: $0) }
        }
        
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
    
    private func reactionToDict(_ reaction: Reaction) -> [String: Any] {
        return [
            "id": reaction.id.uuidString,
            "oshiId": reaction.oshiId.uuidString,
            "oshiName": reaction.oshiName,
            "emoji": reaction.emoji,
            "timestamp": reaction.timestamp.timeIntervalSince1970
        ]
    }
    
    private func commentToDict(_ comment: Comment) -> [String: Any] {
        return [
            "id": comment.id.uuidString,
            "oshiId": comment.oshiId.uuidString,
            "oshiName": comment.oshiName,
            "content": comment.content,
            "timestamp": comment.timestamp.timeIntervalSince1970
        ]
    }
}

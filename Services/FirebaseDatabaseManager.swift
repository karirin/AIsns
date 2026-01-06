import Foundation
import FirebaseDatabase

/// 最適化されたFirebase Database Manager (共有SNS対応版)
class FirebaseDatabaseManager {
    static let shared = FirebaseDatabaseManager()

    private let ref: DatabaseReference
    private let userId: String
    var currentUserId: String { userId }

    private init() {
        self.ref = FirebaseConfig.shared.databaseRef
        self.userId = FirebaseConfig.shared.userId
    }
    
    // MARK: - User Flags & Contacts
    
    func updateContact(userId: String, newContact: String, completion: @escaping (Bool) -> Void) {
        let contactRef = ref.child("contacts").child(userId)
        contactRef.observeSingleEvent(of: .value) { snapshot in
            var contacts: [String] = []
            if let currentContacts = snapshot.value as? [String] { contacts = currentContacts }
            contacts.append(newContact)
            contactRef.setValue(contacts) { error, _ in completion(error == nil) }
        }
    }
    
    func fetchUserFlag(completion: @escaping (Int?, Error?) -> Void) {
        ref.child("users").child(userId).child("userFlag").observeSingleEvent(of: .value) { snapshot in
            completion(snapshot.value as? Int ?? 0, nil)
        } withCancel: { error in completion(nil, error) }
    }

    func updateUserFlag(userId: String, userFlag: Int, completion: @escaping (Bool) -> Void) {
        ref.child("users").child(userId).updateChildValues(["userFlag": userFlag]) { error, _ in completion(error == nil) }
    }
    
    func updateUserCsFlag(userId: String, userCsFlag: Int, completion: @escaping (Bool) -> Void) {
        ref.child("users").child(userId).updateChildValues(["userCsFlag": userCsFlag]) { error, _ in completion(error == nil) }
    }

    // MARK: - Oshi Management

    func saveOshi(_ oshi: OshiCharacter) async throws {
        let oshiRef = ref.child("users/\(userId)/oshiList/\(oshi.id.uuidString)")
        
        var oshiData: [String: Any] = [
            "id": oshi.id.uuidString,
            "name": oshi.name,
            "personalityText": oshi.personalityText,
            "speechCharacteristics": oshi.speechCharacteristics,
            "userCallingName": oshi.userCallingName,
            "speechStyleText": oshi.speechStyleText,
            "createdAt": oshi.createdAt.timeIntervalSince1970,
            "totalInteractions": oshi.totalInteractions,
            "lastInteractionDate": oshi.lastInteractionDate?.timeIntervalSince1970 ?? 0,
            "isFollowingUser": oshi.isFollowingUser,
            "isFollowedByUser": oshi.isFollowedByUser,
            "isPublic": oshi.isPublic,
            "followerCount": oshi.followerCount
        ]
        if let gender = oshi.gender { oshiData["gender"] = gender.rawValue }
        if let imageURL = oshi.avatarImageURL { oshiData["avatarImageURL"] = imageURL }
        if let creatorId = oshi.creatorId { oshiData["creatorId"] = creatorId }
        
        try await oshiRef.setValue(oshiData)
    }
    
    func saveUserProfile(userName: String, userBio: String, avatarImageURL: String?) async throws {
        let profileRef = ref.child("users/\(userId)/profile")
        var data: [String: Any] = [
            "userName": userName,
            "userBio": userBio,
            "updatedAt": Date().timeIntervalSince1970
        ]
        data["avatarImageURL"] = avatarImageURL ?? ""
        try await profileRef.updateChildValues(data)
    }

    func loadUserProfile() async throws -> (userName: String, userBio: String, avatarImageURL: String?) {
        let snap = try await ref.child("users/\(userId)/profile").getData()
        guard let v = snap.value as? [String: Any] else { return ("あなた", "", nil) }
        let name = v["userName"] as? String ?? "あなた"
        let bio = v["userBio"] as? String ?? ""
        let avatar = (v["avatarImageURL"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        return (name, bio, avatar)
    }
    
    func deletePresetOshi(_ oshiId: UUID) async throws {
        let presetRef = ref.child("presets/oshiList/\(oshiId.uuidString)")
        try await presetRef.removeValue()
        print("✅ プリセット推し削除成功: \(oshiId.uuidString)")
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

    /// 推し削除
    func deleteOshi(_ oshiId: UUID) async throws {
        try? await FirebaseStorageManager.shared.deleteOshiAvatar(oshiId: oshiId)

        // 1. 推しデータの削除
        let oshiRef = ref.child("users/\(userId)/oshiList/\(oshiId.uuidString)")
        try await oshiRef.removeValue()
    }

    // MARK: - Posts

    /// 投稿を保存(リアクション・コメントは含まない)
    func savePost(_ post: Post, isPublic: Bool = false) async throws {
        let postData = encodePostToDictionary(post)
        var updates: [String: Any] = [:]
        
        // 1. データ実体 (root/posts/{postId}) - すべての基本
        updates["posts/\(post.id.uuidString)"] = postData
        
        // 2. 自分の投稿リスト (users/{userId}/myPosts/{postId})
        if post.isUserPost {
            updates["users/\(userId)/myPosts/\(post.id.uuidString)"] = postData
        }
        
        // 3. 推しの投稿リスト (oshi-posts/{oshiId}/{postId})
        // これが「推しのプロフィール画面」等で使われるデータソース
        if !post.isUserPost, let authorId = post.authorId {
            updates["oshi-posts/\(authorId.uuidString)/\(post.id.uuidString)"] = postData
        }
        
        // 4. 公開タイムライン (publicTimeline/{postId})
        // ここに入ると「おすすめ」に表示される
        if isPublic {
            updates["publicTimeline/\(post.id.uuidString)"] = postData
            
            // 将来的なファンアウト用（現状は空振りでも問題なし）
            let followers = try await fetchUserFollowers(userId: userId)
            for followerId in followers {
                updates["users/\(followerId)/homeTimeline/\(post.id.uuidString)"] = postData
            }
        }
        
        try await ref.updateChildValues(updates)
    }

    /// 公開投稿（おすすめ）を取得
    func loadPublicPosts(limit: Int = 50) async throws -> [Post] {
        let snapshot = try await ref.child("publicTimeline")
            .queryOrdered(byChild: "timestamp")
            .queryLimited(toLast: UInt(limit))
            .getData()

        return parsePosts(from: snapshot)
    }
    
    /// 自分の投稿を取得
    func loadMyPosts(limit: Int = 50) async throws -> [Post] {
        let snapshot = try await ref.child("users/\(userId)/myPosts")
            .queryOrdered(byChild: "timestamp")
            .queryLimited(toLast: UInt(limit))
            .getData()
            
        return parsePosts(from: snapshot)
    }
    
    /// ✅ 追加: 特定の推しの投稿を取得 (プロフィール画面用など)
    /// これがないと他ユーザーが推しの詳細画面を開いた時に投稿が表示されません
    func loadOshiPosts(oshiId: UUID, limit: Int = 50) async throws -> [Post] {
        let snapshot = try await ref.child("oshi-posts/\(oshiId.uuidString)")
            .queryOrdered(byChild: "timestamp")
            .queryLimited(toLast: UInt(limit))
            .getData()
            
        return parsePosts(from: snapshot)
    }

    /// フォロー中の推しの投稿を一括取得
    func loadFollowingPosts(followingIds: [UUID], limitPerOshi: Int = 5) async throws -> [Post] {
        var allPosts: [Post] = []
        
        await withTaskGroup(of: [Post].self) { group in
            for oshiId in followingIds {
                group.addTask {
                    do {
                        // 各推しの投稿リスト(oshi-posts)から並列取得
                        let snapshot = try await self.ref.child("oshi-posts/\(oshiId.uuidString)")
                            .queryOrdered(byChild: "timestamp")
                            .queryLimited(toLast: UInt(limitPerOshi))
                            .getData()
                        return self.parsePosts(from: snapshot)
                    } catch {
                        return []
                    }
                }
            }
            
            for await posts in group {
                allPosts.append(contentsOf: posts)
            }
        }
        
        return allPosts.sorted { $0.timestamp > $1.timestamp }.prefix(50).map { $0 }
    }

    func loadPosts(by postIds: [UUID]) async throws -> [Post] {
        var loadedPosts: [Post] = []
        
        await withTaskGroup(of: Post?.self) { group in
            for postId in postIds {
                group.addTask {
                    do {
                        let snapshot = try await self.ref.child("posts/\(postId.uuidString)").getData()
                        guard let data = snapshot.value as? [String: Any] else { return nil }
                        return self.parsePost(from: data)
                    } catch {
                        return nil
                    }
                }
            }
            
            for await post in group {
                if let post = post { loadedPosts.append(post) }
            }
        }
        
        let postMap = Dictionary(uniqueKeysWithValues: loadedPosts.map { ($0.id, $0) })
        return postIds.compactMap { postMap[$0] }
    }
    
    private func parsePosts(from snapshot: DataSnapshot) -> [Post] {
        guard let value = snapshot.value as? [String: Any] else { return [] }
        
        var posts: [Post] = []
        for (_, data) in value {
            if let dict = data as? [String: Any],
               let post = parsePost(from: dict) {
                posts.append(post)
            }
        }
        return posts.sorted { $0.timestamp > $1.timestamp }
    }

    private func encodePostToDictionary(_ post: Post) -> [String: Any] {
        var data: [String: Any] = [
            "id": post.id.uuidString,
            "authorName": post.authorName,
            "content": post.content,
            "timestamp": post.timestamp.timeIntervalSince1970,
            "isUserPost": post.isUserPost,
            "reactionCount": post.reactionCount,
            "commentCount": post.commentCount,
            "repostCount": post.repostCount,
            "imageURLs": post.imageURLs
        ]
        if let authorId = post.authorId { data["authorId"] = authorId.uuidString }
        if let avatarURL = post.authorAvatarURL { data["authorAvatarURL"] = avatarURL }
        if let creatorId = post.creatorId { data["creatorId"] = creatorId }
        
        return data
    }
    
    // MARK: - 通知の自動削除
    
    func deleteOldNotifications(olderThan date: Date) async throws {
        let timestamp = date.timeIntervalSince1970
        let query = ref.child("users/\(userId)/notifications")
            .queryOrdered(byChild: "timestamp")
            .queryEnding(atValue: timestamp)
            
        let snapshot = try await query.getData()
        guard let value = snapshot.value as? [String: Any] else { return }
        
        var updates: [String: Any?] = [:]
        for key in value.keys {
            updates["users/\(userId)/notifications/\(key)"] = nil
        }
        
        if !updates.isEmpty {
            try await ref.updateChildValues(updates as [AnyHashable : Any])
        }
    }
    
    // MARK: - Follow / Unfollow
    
    /// ✅ 追加: ユーザーのフォロワーIDを取得
    func fetchUserFollowers(userId: String) async throws -> [String] {
        // 現在はAI SNSのため、ユーザー間フォローがない場合は空配列を返す
        return []
    }
    
    func followRemoteOshi(oshi: OshiCharacter) async throws {
        let refPath = "users/\(userId)/following/\(oshi.id.uuidString)"
        try await ref.child(refPath).setValue(Date().timeIntervalSince1970)
        
        let followerRef = ref.child("oshi-followers/\(oshi.id.uuidString)/\(userId)")
        try await followerRef.setValue(Date().timeIntervalSince1970)
        
        if let creatorId = oshi.creatorId {
            let countRef = ref.child("users/\(creatorId)/oshiList/\(oshi.id.uuidString)/followerCount")
            try await countRef.setValue(ServerValue.increment(1))
        } else {
            let countRef = ref.child("presets/oshiList/\(oshi.id.uuidString)/followerCount")
            try await countRef.setValue(ServerValue.increment(1))
        }
        
        guard let creatorId = oshi.creatorId else { return }
        let (myUserName, _, myAvatarURL) = try await loadUserProfile()
        
        let notification = AppNotification(
            type: .follow,
            senderId: UUID(uuidString: userId) ?? UUID(),
            senderName: myUserName,
            content: "あなたのAIをフォローしました",
            relatedPostId: nil,
            category: .createdOshi,
            targetOshiName: oshi.name,
            senderAvatarURL: myAvatarURL
        )
        
        try await sendNotification(to: creatorId, notification: notification)
    }

    func unfollowRemoteOshi(oshiId: UUID) async throws {
        let refPath = "users/\(userId)/following/\(oshiId.uuidString)"
        try await ref.child(refPath).removeValue()
        
        let followerRef = ref.child("oshi-followers/\(oshiId.uuidString)/\(userId)")
        try await followerRef.removeValue()
    }
    
    func fetchFollowingOshis() async throws -> [OshiCharacter] {
        let followingIds = try await loadFollowingIds()
        if followingIds.isEmpty { return [] }
        
        var oshis: [OshiCharacter] = []
        let presets = try await loadPresetOshiList()
        let myOshis = try await loadOshiList()
        
        for id in followingIds {
            if let preset = presets.first(where: { $0.id == id }) {
                oshis.append(preset)
            } else if let myOshi = myOshis.first(where: { $0.id == id }) {
                oshis.append(myOshi)
            }
        }
        return oshis
    }
    
    func fetchOshiFollowers(oshiId: UUID) async throws -> [OshiCharacter] {
        let snapshot = try await ref.child("oshi-followers/\(oshiId.uuidString)").getData()
        guard let value = snapshot.value as? [String: Any] else { return [] }
        let userIds = value.keys
        
        var users: [OshiCharacter] = []
        for uid in userIds {
            if let userProfile = try await fetchUserProfile(userId: uid) {
                users.append(userProfile)
            }
        }
        return users
    }

    func loadFollowingIds() async throws -> [UUID] {
        let snapshot = try await ref.child("users/\(userId)/following").getData()
        guard let value = snapshot.value as? [String: Any] else { return [] }
        return value.keys.compactMap { UUID(uuidString: $0) }
    }

    func updatePost(_ post: Post) async throws {
        try await savePost(post)
    }

    // MARK: - Reactions (Shared)

    func addReaction(_ reaction: Reaction, to postId: UUID, postAuthorId: String, oshiName: String? = nil) async throws {
        let reactionRef = ref.child("post-reactions/\(postId.uuidString)/\(reaction.id.uuidString)")
        let reactionData: [String: Any] = [
            "id": reaction.id.uuidString,
            "oshiId": reaction.oshiId.uuidString,
            "oshiName": reaction.oshiName,
            "emoji": reaction.emoji,
            "timestamp": reaction.timestamp.timeIntervalSince1970,
            "userId": userId
        ]
        var updates: [String: Any] = [:]
        updates["post-reactions/\(postId.uuidString)/\(reaction.id.uuidString)"] = reactionData
        updates["users/\(userId)/likes/\(postId.uuidString)"] = Date().timeIntervalSince1970
        try await ref.updateChildValues(updates)
        
        let countRef = ref.child("posts/\(postId.uuidString)/reactionCount")
        try await countRef.setValue(ServerValue.increment(1))
        
        let (myUserName, _, myAvatarURL) = try await loadUserProfile()
        let category: NotificationCategory = (oshiName != nil) ? .createdOshi : .me
        
        let notification = AppNotification(
            type: .reaction,
            senderId: UUID(uuidString: userId) ?? UUID(),
            senderName: myUserName,
            content: "あなたの投稿にいいねしました",
            relatedPostId: postId,
            category: category,
            targetOshiName: oshiName,
            senderAvatarURL: myAvatarURL
        )
        try await sendNotification(to: postAuthorId, notification: notification)
    }

    func loadReactions(for postId: UUID) async throws -> [Reaction] {
        do {
            let snapshot = try await ref.child("post-reactions/\(postId.uuidString)").getData()
            guard let value = snapshot.value as? [String: [String: Any]] else { return [] }

            var reactions: [Reaction] = []
            for (_, reactionData) in value {
                if let reaction = parseReaction(from: reactionData) {
                    reactions.append(reaction)
                }
            }
            return reactions.sorted { $0.timestamp > $1.timestamp }
        } catch let error as NSError {
            if error.domain == "com.firebase.core" && error.code == 1 { return [] }
            throw error
        }
    }

    func deleteReaction(_ reaction: Reaction, from postId: UUID) async throws {
        let reactionRef = ref.child("post-reactions/\(postId.uuidString)/\(reaction.id.uuidString)")
        try await reactionRef.removeValue()
        
        let myLikeRef = ref.child("users/\(userId)/likes/\(postId.uuidString)")
        try await myLikeRef.removeValue()

        let countRef = ref.child("posts/\(postId.uuidString)/reactionCount")
        try await countRef.setValue(ServerValue.increment(-1))
    }
    
    // MARK: - Comments (Shared)

    func addComment(_ comment: Comment, to postId: UUID) async throws {
        let commentRef = ref.child("post-comments/\(postId.uuidString)/\(comment.id.uuidString)")
        let commentData: [String: Any] = [
            "id": comment.id.uuidString,
            "oshiId": comment.oshiId.uuidString,
            "oshiName": comment.oshiName,
            "content": comment.content,
            "timestamp": comment.timestamp.timeIntervalSince1970,
            "userId": userId
        ]
        try await commentRef.setValue(commentData)

        let countRef = ref.child("posts/\(postId.uuidString)/commentCount")
        try await countRef.setValue(ServerValue.increment(1))
    }

    func loadComments(for postId: UUID, limit: Int = 10, before: Date? = nil) async throws -> [Comment] {
        var query = ref.child("post-comments/\(postId.uuidString)")
            .queryOrdered(byChild: "timestamp")

        if let before = before {
            query = query.queryEnding(atValue: before.timeIntervalSince1970)
        }
        query = query.queryLimited(toLast: UInt(limit))

        do {
            let snapshot = try await query.getData()
            guard let value = snapshot.value as? [String: [String: Any]] else { return [] }

            var comments: [Comment] = []
            for (_, commentData) in value {
                if let comment = parseComment(from: commentData) {
                    comments.append(comment)
                }
            }
            return comments.sorted { $0.timestamp < $1.timestamp }
        } catch let error as NSError {
            if error.domain == "com.firebase.core" && error.code == 1 { return [] }
            throw error
        }
    }

    func removeComment(_ commentId: UUID, from postId: UUID) async throws {
        let commentRef = ref.child("post-comments/\(postId.uuidString)/\(commentId.uuidString)")
        try await commentRef.removeValue()

        let countRef = ref.child("posts/\(postId.uuidString)/commentCount")
        try await countRef.setValue(ServerValue.increment(-1))
    }

    // MARK: - Chat Rooms & Messages
    
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
        guard let roomsValue = roomsSnapshot.value as? [String: [String: Any]] else { return [] }

        var chatRooms: [ChatRoom] = []
        for (oshiIdString, roomData) in roomsValue {
            guard let id = UUID(uuidString: roomData["id"] as? String ?? ""),
                  let oshiId = UUID(uuidString: oshiIdString) else { continue }

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
              let personalityText = data["personalityText"] as? String,
              let speechStyleText = data["speechStyleText"] as? String,
              let createdAtTimestamp = data["createdAt"] as? TimeInterval else { return nil }

        let gender = (data["gender"] as? String).flatMap { Gender(rawValue: $0) }
        let speechCharacteristics = data["speechCharacteristics"] as? String ?? ""
        let userCallingName = data["userCallingName"] as? String ?? ""
        let totalInteractions = data["totalInteractions"] as? Int ?? 0
        let lastInteractionTimestamp = data["lastInteractionDate"] as? TimeInterval ?? 0
        let avatarImageURL = data["avatarImageURL"] as? String
        let isFollowingUser = data["isFollowingUser"] as? Bool ?? false
        let isFollowedByUser = data["isFollowedByUser"] as? Bool ?? false
        let isPublic = data["isPublic"] as? Bool ?? false
        let followerCount = data["followerCount"] as? Int ?? 0
        let creatorId = data["creatorId"] as? String

        var oshi = OshiCharacter(
            id: id,
            name: name,
            gender: gender,
            personalityText: personalityText,
            speechCharacteristics: speechCharacteristics,
            userCallingName: userCallingName,
            speechStyleText: speechStyleText,
            avatarImageURL: avatarImageURL,
            isFollowingUser: isFollowingUser,
            isFollowedByUser: isFollowedByUser,
            isPublic: isPublic,
            followerCount: followerCount,
            creatorId: creatorId
        )
        oshi.totalInteractions = totalInteractions
        oshi.lastInteractionDate = lastInteractionTimestamp > 0 ? Date(timeIntervalSince1970: lastInteractionTimestamp) : nil
        return oshi
    }

    // MARK: - Presets
    
    func savePresetOshi(_ oshi: OshiCharacter) async throws {
        let path = "presets/oshiList/\(oshi.id.uuidString)"
        let oshiRef = ref.child(path)
        var oshiData: [String: Any] = [
            "id": oshi.id.uuidString,
            "name": oshi.name,
            "personalityText": oshi.personalityText,
            "speechCharacteristics": oshi.speechCharacteristics,
            "userCallingName": oshi.userCallingName,
            "speechStyleText": oshi.speechStyleText,
            "createdAt": oshi.createdAt.timeIntervalSince1970,
            "totalInteractions": 0,
            "avatarImageURL": oshi.avatarImageURL ?? "",
        ]
        if let creatorId = oshi.creatorId { oshiData["creatorId"] = creatorId }
        if let gender = oshi.gender { oshiData["gender"] = gender.rawValue }
        try await oshiRef.updateChildValues(oshiData)
    }

    func sendNotification(to targetUserId: String, notification: AppNotification) async throws {
        guard targetUserId != userId else { return }
        
        let notificationRef = ref.child("users/\(targetUserId)/notifications/\(notification.id.uuidString)")
        var data: [String: Any] = [
            "id": notification.id.uuidString,
            "type": notification.type.rawValue,
            "senderId": notification.senderId.uuidString,
            "senderName": notification.senderName,
            "content": notification.content,
            "timestamp": notification.timestamp.timeIntervalSince1970,
            "isRead": notification.isRead,
            "category": notification.category.rawValue
        ]
        if let relatedPostId = notification.relatedPostId { data["relatedPostId"] = relatedPostId.uuidString }
        if let targetName = notification.targetOshiName { data["targetOshiName"] = targetName }
        if let avatarURL = notification.senderAvatarURL { data["senderAvatarURL"] = avatarURL }
        
        try await notificationRef.setValue(data)
    }
    
    func fetchUserProfile(userId: String) async throws -> OshiCharacter? {
        let snapshot = try await ref.child("users/\(userId)/profile").getData()
        guard let v = snapshot.value as? [String: Any] else { return nil }
        
        let name = v["userName"] as? String ?? "不明なユーザー"
        let bio = v["userBio"] as? String ?? ""
        let avatar = (v["avatarImageURL"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        
        return OshiCharacter(
            id: UUID(uuidString: userId) ?? UUID(),
            name: name,
            gender: .other,
            personalityText: bio,
            speechCharacteristics: "",
            userCallingName: "",
            speechStyleText: "",
            avatarImageURL: avatar,
            isFollowingUser: false,
            isFollowedByUser: false,
            isPublic: true
        )
    }

    func saveNotification(_ notification: AppNotification) async throws {
        let notificationRef = ref.child("users/\(userId)/notifications/\(notification.id.uuidString)")
        var data: [String: Any] = [
            "id": notification.id.uuidString,
            "type": notification.type.rawValue,
            "senderId": notification.senderId.uuidString,
            "senderName": notification.senderName,
            "content": notification.content,
            "timestamp": notification.timestamp.timeIntervalSince1970,
            "isRead": notification.isRead,
            "category": notification.category.rawValue
        ]
        if let relatedPostId = notification.relatedPostId { data["relatedPostId"] = relatedPostId.uuidString }
        if let targetName = notification.targetOshiName { data["targetOshiName"] = targetName }
        if let avatarURL = notification.senderAvatarURL { data["senderAvatarURL"] = avatarURL }
        
        try await notificationRef.setValue(data)
    }

    func fetchPresetOshis() async throws -> [OshiCharacter] {
        let snap = try await ref.child("presets/oshiList").getData()
        guard snap.exists() else { return [] }
        var items: [(Int, OshiCharacter)] = []
        for child in snap.children {
            guard let c = child as? DataSnapshot, let v = c.value as? [String: Any] else { continue }
            guard let idStr = v["id"] as? String, let id = UUID(uuidString: idStr),
                  let name = v["name"] as? String,
                  let personalityText = v["personalityText"] as? String,
                  let speechStyleText = v["speechStyleText"] as? String else { continue }
            
            let gender = (v["gender"] as? String).flatMap { Gender(rawValue: $0) }
            let speechCharacteristics = v["speechCharacteristics"] as? String ?? ""
            let userCallingName = v["userCallingName"] as? String ?? ""
            let avatar = (v["avatarImageURL"] as? String).flatMap { $0.isEmpty ? nil : $0 }
            let sortOrder = v["sortOrder"] as? Int ?? 9999
            
            let oshi = OshiCharacter(
                id: id,
                name: name,
                gender: gender,
                personalityText: personalityText,
                speechCharacteristics: speechCharacteristics,
                userCallingName: userCallingName,
                speechStyleText: speechStyleText,
                avatarImageURL: avatar
            )
            items.append((sortOrder, oshi))
        }
        return items.sorted { $0.0 < $1.0 }.map { $0.1 }
    }

    func loadPresetOshiList() async throws -> [OshiCharacter] {
        let snapshot = try await ref.child("presets/oshiList").getData()
        guard let value = snapshot.value as? [String: [String: Any]] else { return [] }
        var list: [OshiCharacter] = []
        for (_, data) in value {
            if let oshi = parseOshiCharacter(from: data) {
                list.append(oshi)
            }
        }
        return list
    }

    func loadNotifications(limit: Int = 100) async throws -> [AppNotification] {
        let snapshot = try await ref.child("users/\(userId)/notifications")
            .queryOrdered(byChild: "timestamp")
            .queryLimited(toLast: UInt(limit))
            .getData()
        
        guard let rawValue = snapshot.value, !(rawValue is NSNull) else { return [] }
        var notifications: [AppNotification] = []
        
        if let dictValue = rawValue as? [String: Any] {
            for (_, item) in dictValue {
                if let data = item as? [String: Any], let n = parseNotification(from: data) {
                    notifications.append(n)
                }
            }
        } else if let arrayValue = rawValue as? [Any] {
            for item in arrayValue {
                if let data = item as? [String: Any], let n = parseNotification(from: data) {
                    notifications.append(n)
                }
            }
        }
        return notifications.sorted { $0.timestamp > $1.timestamp }
    }
    
    func markAllNotificationsAsRead() async throws {
        let notificationsRef = ref.child("users/\(userId)/notifications")
        let snapshot = try await notificationsRef.queryOrdered(byChild: "isRead").queryEqual(toValue: false).getData()
        guard let value = snapshot.value as? [String: Any] else { return }
        
        var updates: [String: Any] = [:]
        for (key, _) in value { updates["\(key)/isRead"] = true }
        if !updates.isEmpty { try await notificationsRef.updateChildValues(updates) }
    }
    
    func updateNotificationReadStatus(_ notificationId: UUID, isRead: Bool) async throws {
        try await ref.child("users/\(userId)/notifications/\(notificationId.uuidString)")
            .updateChildValues(["isRead": isRead])
    }
    
    func saveBookmark(postId: UUID) async throws {
        let refPath = "users/\(userId)/bookmarks/\(postId.uuidString)"
        let timestamp = Date().timeIntervalSince1970
        try await ref.child(refPath).setValue(timestamp)
    }

    func deleteBookmark(postId: UUID) async throws {
        let refPath = "users/\(userId)/bookmarks/\(postId.uuidString)"
        try await ref.child(refPath).removeValue()
    }

    func loadBookmarkIDs() async throws -> [UUID] {
        let snapshot = try await ref.child("users/\(userId)/bookmarks").getData()
        guard let value = snapshot.value as? [String: TimeInterval] else { return [] }
        return value.sorted { $0.value > $1.value }.compactMap { UUID(uuidString: $0.key) }
    }
    
    func clearAllNotifications() async throws {
        try await ref.child("users/\(userId)/notifications").removeValue()
    }
    
    private func parseNotification(from data: [String: Any]) -> AppNotification? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let typeString = data["type"] as? String,
              let type = NotificationType(rawValue: typeString),
              let senderIdString = data["senderId"] as? String,
              let senderId = UUID(uuidString: senderIdString),
              let senderName = data["senderName"] as? String,
              let content = data["content"] as? String,
              let timestampInterval = data["timestamp"] as? TimeInterval else { return nil }
        
        let timestamp = Date(timeIntervalSince1970: timestampInterval)
        let isRead = data["isRead"] as? Bool ?? false
        let relatedPostId = (data["relatedPostId"] as? String).flatMap { UUID(uuidString: $0) }
        let category = (data["category"] as? String).flatMap { NotificationCategory(rawValue: $0) } ?? .me
        let targetOshiName = data["targetOshiName"] as? String
        let senderAvatarURL = data["senderAvatarURL"] as? String
        
        return AppNotification(
            id: id,
            type: type,
            senderId: senderId,
            senderName: senderName,
            content: content,
            relatedPostId: relatedPostId,
            timestamp: timestamp,
            isRead: isRead,
            category: category,
            targetOshiName: targetOshiName,
            senderAvatarURL: senderAvatarURL
        )
    }

    // MARK: - Parsers

    func parsePost(from data: [String: Any]) -> Post? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let authorName = data["authorName"] as? String,
              let content = data["content"] as? String,
              let timestampInterval = data["timestamp"] as? TimeInterval,
              let isUserPost = data["isUserPost"] as? Bool else { return nil }
        
        let authorId = (data["authorId"] as? String).flatMap { UUID(uuidString: $0) }
        let timestamp = Date(timeIntervalSince1970: timestampInterval)
        let reactionCount = data["reactionCount"] as? Int ?? 0
        let commentCount = data["commentCount"] as? Int ?? 0
        let repostCount = data["repostCount"] as? Int ?? 0
        let authorAvatarURL = data["authorAvatarURL"] as? String
        let imageURLs = data["imageURLs"] as? [String] ?? []
        let creatorId = data["creatorId"] as? String

        var post = Post(
            id: id,
            authorId: authorId,
            authorName: authorName,
            content: content,
            timestamp: timestamp,
            isUserPost: isUserPost,
            authorAvatarURL: authorAvatarURL,
            imageURLs: imageURLs,
            creatorId: creatorId
        )
        post.reactionCount = reactionCount
        post.commentCount = commentCount
        post.repostCount = repostCount
        return post
    }
    
    func repostPost(postId: UUID) async throws {
        let repostRef = ref.child("users/\(userId)/reposts/\(postId.uuidString)")
        try await repostRef.setValue(Date().timeIntervalSince1970)
        let countRef = ref.child("posts/\(postId.uuidString)/repostCount")
        try await countRef.setValue(ServerValue.increment(1))
    }

    func unrepostPost(postId: UUID) async throws {
        let repostRef = ref.child("users/\(userId)/reposts/\(postId.uuidString)")
        try await repostRef.removeValue()
        let countRef = ref.child("posts/\(postId.uuidString)/repostCount")
        try await countRef.setValue(ServerValue.increment(-1))
    }

    func loadUserRepostIDs() async throws -> [UUID] {
        let snapshot = try await ref.child("users/\(userId)/reposts").getData()
        guard let value = snapshot.value as? [String: Any] else { return [] }
        return value.keys.compactMap { UUID(uuidString: $0) }
    }

    private func parseMessage(from data: [String: Any]) -> Message? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let content = data["content"] as? String,
              let isFromUser = data["isFromUser"] as? Bool,
              let timestampInterval = data["timestamp"] as? TimeInterval else { return nil }
        
        let oshiId = (data["oshiId"] as? String).flatMap { UUID(uuidString: $0) }
        let timestamp = Date(timeIntervalSince1970: timestampInterval)
        let isRead = data["isRead"] as? Bool ?? false
        return Message(id: id, content: content, isFromUser: isFromUser, oshiId: oshiId, timestamp: timestamp, isRead: isRead)
    }

    func loadUserLikedPostIDs() async throws -> [UUID] {
        let snapshot = try await ref.child("users/\(userId)/likes").getData()
        guard let value = snapshot.value as? [String: TimeInterval] else { return [] }
        return value.keys.compactMap { UUID(uuidString: $0) }
    }

    private func parseReaction(from data: [String: Any]) -> Reaction? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let oshiIdString = data["oshiId"] as? String,
              let oshiId = UUID(uuidString: oshiIdString),
              let oshiName = data["oshiName"] as? String,
              let emoji = data["emoji"] as? String,
              let timestampInterval = data["timestamp"] as? TimeInterval else { return nil }
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
              let timestampInterval = data["timestamp"] as? TimeInterval else { return nil }
        let timestamp = Date(timeIntervalSince1970: timestampInterval)
        return Comment(id: id, oshiId: oshiId, oshiName: oshiName, content: content, timestamp: timestamp)
    }
}

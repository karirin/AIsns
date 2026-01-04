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

            if let currentContacts = snapshot.value as? [String] {
                contacts = currentContacts
            }

            contacts.append(newContact)

            contactRef.setValue(contacts) { error, _ in
                if let error = error {
                    print("❌ Error updating contact: \(error)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
        } withCancel: { error in
            print("❌ Error reading contact: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    func fetchUserFlag(completion: @escaping (Int?, Error?) -> Void) {
        let userRef = ref.child("users").child(userId)

        userRef.child("userFlag").observeSingleEvent(of: .value) { snapshot in
            if let userFlag = snapshot.value as? Int {
                DispatchQueue.main.async {
                    completion(userFlag, nil)
                }
            } else {
                DispatchQueue.main.async {
                    completion(0, nil)
                }
            }
        } withCancel: { error in
            DispatchQueue.main.async {
                completion(nil, error)
            }
        }
    }
    
    func updateUserFlag(userId: String, userFlag: Int, completion: @escaping (Bool) -> Void) {
        let userRef = ref.child("users").child(userId)
        let updates: [String: Any] = ["userFlag": userFlag]

        userRef.updateChildValues(updates) { error, _ in
            if let error = error {
                print("❌ Error updating userFlag: \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    func updateUserCsFlag(userId: String, userCsFlag: Int, completion: @escaping (Bool) -> Void) {
        let userRef = ref.child("users").child(userId)
        let updates: [String: Any] = ["userCsFlag": userCsFlag]
        print("🔧 updateUserCsFlag updates:", updates)

        userRef.updateChildValues(updates) { error, _ in
            if let error = error {
                print("❌ Error updating userCsFlag: \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
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
            "isPublic": oshi.isPublic
        ]

        if let gender = oshi.gender {
            oshiData["gender"] = gender.rawValue
        }

        if let imageURL = oshi.avatarImageURL {
            oshiData["avatarImageURL"] = imageURL
        }
        
        // 追加: 作成者ID
        if let creatorId = oshi.creatorId {
            oshiData["creatorId"] = creatorId
        }
        
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

        guard let v = snap.value as? [String: Any] else {
            return ("あなた", "", nil)
        }

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

        // 2. この推しに関連する投稿の削除が必要ならここで行う
        // 今回は「推しの削除」機能であり、過去の投稿が残っていても大きな問題ではないため、
        // 複雑な整合性処理は省略します。
    }

    // MARK: - Posts

    /// 投稿を保存(リアクション・コメントは含まない)
    func savePost(_ post: Post, isPublic: Bool = false) async throws {
        // 1. データ実体: root/posts/{postId} に保存 (全ユーザー共有)
        let postData = encodePostToDictionary(post)
        
        // 2. 参照用パスの準備
        var updates: [String: Any] = [:]
        
        // A. 実体の保存パス
        updates["posts/\(post.id.uuidString)"] = postData
        
        // B. 自分の投稿リスト (users/{userId}/myPostIds/{postId})
        updates["users/\(userId)/myPostIds/\(post.id.uuidString)"] = post.timestamp.timeIntervalSince1970
        
        // C. 公開タイムライン (publicTimeline/{postId}) - 公開設定の場合のみ
        if isPublic {
            updates["publicTimeline/\(post.id.uuidString)"] = post.timestamp.timeIntervalSince1970
        }
        
        try await ref.updateChildValues(updates)
    }

    /// 公開投稿（おすすめ）を取得
    func loadPublicPosts(limit: Int = 50) async throws -> [Post] {
        let snapshot = try await ref.child("publicTimeline")
            .queryOrderedByValue()
            .queryLimited(toLast: UInt(limit))
            .getData()

        guard let value = snapshot.value as? [String: TimeInterval] else {
            return []
        }
        
        let sortedIds = value.sorted { $0.value > $1.value }.map { UUID(uuidString: $0.key) }.compactMap { $0 }
        
        if sortedIds.isEmpty { return [] }
        return try await loadPosts(by: sortedIds)
    }
    
    /// 自分の投稿を取得
    func loadMyPosts(limit: Int = 50) async throws -> [Post] {
        let snapshot = try await ref.child("users/\(userId)/myPostIds")
            .queryOrderedByValue()
            .queryLimited(toLast: UInt(limit))
            .getData()
            
        guard let value = snapshot.value as? [String: TimeInterval] else {
            return []
        }
        
        let sortedIds = value.sorted { $0.value > $1.value }.map { UUID(uuidString: $0.key) }.compactMap { $0 }
        
        if sortedIds.isEmpty { return [] }
        return try await loadPosts(by: sortedIds)
    }

    func loadPosts(by postIds: [UUID]) async throws -> [Post] {
        var loadedPosts: [Post] = []
        
        await withTaskGroup(of: Post?.self) { group in
            for postId in postIds {
                group.addTask {
                    do {
                        // ✅ 全ユーザー共有のパスから取得
                        let snapshot = try await self.ref.child("posts/\(postId.uuidString)").getData()
                        
                        guard let data = snapshot.value as? [String: Any],
                              let post = self.parsePost(from: data) else {
                            return nil
                        }
                        return post
                    } catch {
                        print("⚠️ 投稿取得エラー \(postId): \(error)")
                        return nil
                    }
                }
            }
            
            for await post in group {
                if let post = post {
                    loadedPosts.append(post)
                }
            }
        }
        
        let postMap = Dictionary(uniqueKeysWithValues: loadedPosts.map { ($0.id, $0) })
        return postIds.compactMap { postMap[$0] }
    }
    
    private func encodePostToDictionary(_ post: Post) -> [String: Any] {
        var data: [String: Any] = [
            "id": post.id.uuidString,
            "authorId": post.authorId?.uuidString ?? "",
            "authorName": post.authorName,
            "content": post.content,
            "timestamp": post.timestamp.timeIntervalSince1970,
            "isUserPost": post.isUserPost,
            "reactionCount": post.reactionCount,
            "commentCount": post.commentCount,
            "repostCount": post.repostCount
        ]
        if let avatarURL = post.authorAvatarURL {
             data["authorAvatarURL"] = avatarURL
        }
        if !post.imageURLs.isEmpty {
            data["imageURLs"] = post.imageURLs
        }
        
        // 👇 追加: creatorIdがあれば保存
        if let creatorId = post.creatorId {
            data["creatorId"] = creatorId
        }
        
        return data
    }
    
    func followRemoteOshi(oshi: OshiCharacter) async throws {
        print("📍 followRemoteOshi 開始")
        print("  - フォロー対象: \(oshi.name)")
        print("  - 推しID: \(oshi.id)")
        print("  - creatorId: \(oshi.creatorId ?? "nil")")
        
        // 1. 既存の処理: フォロー情報の保存
        let refPath = "users/\(userId)/following/\(oshi.id.uuidString)"
        try await ref.child(refPath).setValue(Date().timeIntervalSince1970)
        
        // 2. 追加処理: 通知の送信
        guard let creatorId = oshi.creatorId else {
            print("⚠️ creatorIdがnilのため通知を送信できません")
            return
        }
        
        let (myUserName, _, myAvatarURL) = try await loadUserProfile()  // ✅ アバターURLも取得
        print("📤 通知送信情報:")
        print("  - 送信者: \(myUserName)")
        print("  - 送信者アバターURL: \(myAvatarURL ?? "nil")")
        print("  - 通知先: \(creatorId)")

        print("followRemoteOshi　👤 フォロー実行者: \(myUserName)")
        print("followRemoteOshi　🖼️ アバターURL: \(myAvatarURL ?? "未設定")")
        
        let notification = AppNotification(
            type: .follow,
            senderId: UUID(uuidString: userId) ?? UUID(),
            senderName: myUserName,
            content: "あなたのAIをフォローしました",
            relatedPostId: nil,
            category: .createdOshi,
            targetOshiName: oshi.name,
            senderAvatarURL: myAvatarURL  // ✅ 追加: アバターURLを含める
        )
        
        try await sendNotification(to: creatorId, notification: notification)
        print("✅ 通知送信完了")
    }

    func unfollowRemoteOshi(oshiId: UUID) async throws {
        let refPath = "users/\(userId)/following/\(oshiId.uuidString)"
        try await ref.child(refPath).removeValue()
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

    /// リアクションを追加 (共有対応)
    func addReaction(_ reaction: Reaction, to postId: UUID, postAuthorId: String, oshiName: String? = nil) async throws {
        // 1. 既存の処理: リアクション保存
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
        
        // 2. 追加処理: 通知の送信
        // 自分のプロフィールを取得（送信者名として使用）
        let (myUserName, _, myAvatarURL) = try await loadUserProfile()  // ✅ アバターURLも取得
        print("func addReaction　👤 フォロー実行者: \(myUserName)")
        print("func addReaction　🖼️ アバターURL: \(myAvatarURL ?? "未設定")")
        
        let category: NotificationCategory = (oshiName != nil) ? .createdOshi : .me
        
        let notification = AppNotification(
            type: .reaction,
            senderId: UUID(uuidString: userId) ?? UUID(),
            senderName: myUserName,
            content: "あなたの投稿にいいねしました",
            relatedPostId: postId,
            category: category,
            targetOshiName: oshiName,
            senderAvatarURL: myAvatarURL  // ✅ 追加
        )
        
        try await sendNotification(to: postAuthorId, notification: notification)
    }

    /// 特定投稿のリアクションを全取得 (共有パスから)
    func loadReactions(for postId: UUID) async throws -> [Reaction] {
        do {
            // ✅ 共有パスから取得
            let snapshot = try await ref.child("post-reactions/\(postId.uuidString)").getData()

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
            if error.domain == "com.firebase.core" && error.code == 1 {
                return []
            }
            throw error
        }
    }

    /// リアクションを削除 (共有対応)
    func deleteReaction(_ reaction: Reaction, from postId: UUID) async throws {
        // 1. 共有パスから削除
        let reactionRef = ref.child("post-reactions/\(postId.uuidString)/\(reaction.id.uuidString)")
        try await reactionRef.removeValue()
        
        // 2. 「自分がいいねしたリスト」から削除
        let myLikeRef = ref.child("users/\(userId)/likes/\(postId.uuidString)")
        try await myLikeRef.removeValue()

        // 3. 共有投稿のreactionCountをデクリメント
        let countRef = ref.child("posts/\(postId.uuidString)/reactionCount")
        try await countRef.setValue(ServerValue.increment(-1))
    }
    
    // 古いメソッド互換用
    func removeReaction(oshiId: UUID, from postId: UUID) async throws {
        // IDが特定できない場合の削除用(現在は基本的にdeleteReactionを使用)
    }

    // MARK: - Comments (Shared)

    /// コメントを追加 (共有対応)
    func addComment(_ comment: Comment, to postId: UUID) async throws {
        // 1. コメントを共有パスに保存 (post-comments/{postId}/{commentId})
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

        // 2. 共有投稿のcommentCountをインクリメント
        let countRef = ref.child("posts/\(postId.uuidString)/commentCount")
        try await countRef.setValue(ServerValue.increment(1))
    }

    /// 特定投稿のコメントを取得 (共有パスから)
    func loadComments(for postId: UUID, limit: Int = 10, before: Date? = nil) async throws -> [Comment] {
        // ✅ 共有パスから取得
        var query = ref.child("post-comments/\(postId.uuidString)")
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

            return comments.sorted { $0.timestamp < $1.timestamp }
        } catch let error as NSError {
            if error.domain == "com.firebase.core" && error.code == 1 {
                return []
            }
            throw error
        }
    }

    /// コメントを削除 (共有対応)
    func removeComment(_ commentId: UUID, from postId: UUID) async throws {
        // 1. 共有パスから削除
        let commentRef = ref.child("post-comments/\(postId.uuidString)/\(commentId.uuidString)")
        try await commentRef.removeValue()

        // 2. 共有投稿のcommentCountをデクリメント
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
              let personalityText = data["personalityText"] as? String,
              let speechStyleText = data["speechStyleText"] as? String,
              let createdAtTimestamp = data["createdAt"] as? TimeInterval else {
            return nil
        }

        let genderRaw = data["gender"] as? String
        let gender = genderRaw.flatMap { Gender(rawValue: $0) }
        let speechCharacteristics = data["speechCharacteristics"] as? String ?? ""
        let userCallingName = data["userCallingName"] as? String ?? ""
        let totalInteractions = data["totalInteractions"] as? Int ?? 0
        let lastInteractionTimestamp = data["lastInteractionDate"] as? TimeInterval ?? 0
        let avatarImageURL = data["avatarImageURL"] as? String
        
        let isFollowingUser = data["isFollowingUser"] as? Bool ?? false
        let isFollowedByUser = data["isFollowedByUser"] as? Bool ?? false
        let isPublic = data["isPublic"] as? Bool ?? false
        
        let creatorId = data["creatorId"] as? String // 追加

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
        
        // 👇 追加: creatorIdを保存
        if let creatorId = oshi.creatorId {
            oshiData["creatorId"] = creatorId
        }

        if let gender = oshi.gender {
            oshiData["gender"] = gender.rawValue
        }

        try await oshiRef.updateChildValues(oshiData)
        print("✅ プリセット保存（公式）: \(oshi.name)")
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
        
        if let relatedPostId = notification.relatedPostId {
            data["relatedPostId"] = relatedPostId.uuidString
        }
        if let targetName = notification.targetOshiName {
            data["targetOshiName"] = targetName
        }
        if let avatarURL = notification.senderAvatarURL {  // ✅ 追加
            data["senderAvatarURL"] = avatarURL
        }
        
        try await notificationRef.setValue(data)
    }

    // 既存の saveNotification は「自分への保存」として残すか、上記メソッドを使う形に修正
    func saveNotification(_ notification: AppNotification) async throws {
        try await sendNotification(to: userId, notification: notification)
    }

    func fetchPresetOshis() async throws -> [OshiCharacter] {
        do {
            let snap = try await ref.child("presets/oshiList").getData()
            guard snap.exists() else { return [] }

            var items: [(Int, OshiCharacter)] = []

            for child in snap.children {
                guard let c = child as? DataSnapshot,
                      let v = c.value as? [String: Any] else { continue }

                guard
                    let idStr = v["id"] as? String,
                    let id = UUID(uuidString: idStr),
                    let name = v["name"] as? String,
                    let personalityText = v["personalityText"] as? String,
                    let speechStyleText = v["speechStyleText"] as? String
                else { continue }

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

        } catch {
            throw error
        }
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
        
        guard let value = snapshot.value as? [String: [String: Any]] else {
            return []
        }
        
        var notifications: [AppNotification] = []
        
        for (_, data) in value {
            if let notification = parseNotification(from: data) {
                notifications.append(notification)
            }
        }
        
        return notifications.sorted { $0.timestamp > $1.timestamp }
    }
    
    func deleteOldNotifications(olderThan date: Date) async throws {
        let timestamp = date.timeIntervalSince1970
        let query = ref.child("users/\(userId)/notifications")
            .queryOrdered(byChild: "timestamp")
            .queryEnding(atValue: timestamp)
            
        let snapshot = try await query.getData()
        guard let value = snapshot.value as? [String: [String: Any]] else { return }
        
        for (key, data) in value {
            if let itemTimestamp = data["timestamp"] as? TimeInterval, itemTimestamp <= timestamp {
                try await ref.child("users/\(userId)/notifications/\(key)").removeValue()
            }
        }
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
    
    func updateNotificationReadStatus(_ notificationId: UUID, isRead: Bool) async throws {
        try await ref.child("users/\(userId)/notifications/\(notificationId.uuidString)")
            .updateChildValues(["isRead": isRead])
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
              let timestampInterval = data["timestamp"] as? TimeInterval else {
            return nil
        }
        
        let timestamp = Date(timeIntervalSince1970: timestampInterval)
        let isRead = data["isRead"] as? Bool ?? false
        let relatedPostId = (data["relatedPostId"] as? String).flatMap { UUID(uuidString: $0) }
        let categoryString = data["category"] as? String
        let category = categoryString.flatMap { NotificationCategory(rawValue: $0) } ?? .me
        let targetOshiName = data["targetOshiName"] as? String
        let senderAvatarURL = data["senderAvatarURL"] as? String  // ✅ 追加
        
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
            senderAvatarURL: senderAvatarURL  // ✅ 追加
        )
    }

    // MARK: - Parsers

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
        let repostCount = data["repostCount"] as? Int ?? 0
        
        let authorAvatarURL = data["authorAvatarURL"] as? String
        let imageURLs = data["imageURLs"] as? [String] ?? []
        
        // 👇 追加: creatorIdの取得
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
            creatorId: creatorId // 👇 追加
        )

        post.reactionCount = reactionCount
        post.commentCount = commentCount
        post.repostCount = repostCount

        return post
    }
    
    func repostPost(postId: UUID) async throws {
        // 1. ユーザーのリツイートリストに追加
        let repostRef = ref.child("users/\(userId)/reposts/\(postId.uuidString)")
        try await repostRef.setValue(Date().timeIntervalSince1970)

        // 2. 共有投稿のrepostCountをインクリメント
        // ✅ users/{userId}/posts ではなく root/posts を更新
        let countRef = ref.child("posts/\(postId.uuidString)/repostCount")
        try await countRef.setValue(ServerValue.increment(1))
    }

    func unrepostPost(postId: UUID) async throws {
        // 1. ユーザーのリツイートリストから削除
        let repostRef = ref.child("users/\(userId)/reposts/\(postId.uuidString)")
        try await repostRef.removeValue()

        // 2. 共有投稿のrepostCountをデクリメント
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

    /// 「いいね」した投稿のID一覧を取得 (高速化版)
    func loadUserLikedPostIDs() async throws -> [UUID] {
        // ✅ users/{userId}/likes から取得するように変更
        let snapshot = try await ref.child("users/\(userId)/likes").getData()
        
        guard let value = snapshot.value as? [String: TimeInterval] else {
            return []
        }
        
        // IDのみ抽出
        return value.keys.compactMap { UUID(uuidString: $0) }
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

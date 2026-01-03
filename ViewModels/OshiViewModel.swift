// ViewModels/OshiViewModel.swift (修正版 - おすすめタイムライン修正)

import Foundation
import Combine
import UIKit

@MainActor
class OshiViewModel: ObservableObject {
    @Published var oshiList: [OshiCharacter] = []
    @Published var posts: [Post] = []
    @Published var chatRooms: [ChatRoom] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var recommendedOshis: [OshiCharacter] = []
    @Published var notifications: [AppNotification] = []
    @Published var userProfileName: String = "あなた"
    @Published var userProfileAvatarURL: String? = nil
    @Published var bookmarkedPostIDs: Set<UUID> = []
    @Published var bookmarkedPosts: [Post] = []
    @Published var repostedPostIDs: Set<UUID> = []
    @Published var likedPostIDs: Set<UUID> = []
    @Published var publicTimelinePosts: [Post] = []
    @Published var followingRemoteOshiIDs: Set<UUID> = []
    
    // ✅ 投稿の詳細情報(必要な時だけ取得)
    @Published var postDetails: [UUID: PostDetails] = [:]
    
    private let aiService = AIService.shared
    private let dbManager = FirebaseDatabaseManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var autoPostTimer: Timer?
    private var autoFollowTimer: Timer?

    var unreadNotificationCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    var followingCount: Int {
        oshiList.filter { $0.isFollowedByUser }.count
    }

    var followerCount: Int {
        oshiList.filter { $0.isFollowingUser }.count
    }

    var mutualFollowCount: Int {
        oshiList.filter { $0.isMutualFollow }.count
    }
    
    var followingOshiIds: Set<UUID> {
        Set(oshiList.filter { $0.isFollowedByUser }.map { $0.id })
    }
    
    var timelinePosts: [Post] {
        // 1. ベースは自分の投稿(posts)
        var combined = posts
        
        // 2. 公開タイムライン(publicTimelinePosts)から、フォローしている人の投稿を抽出して追加
        let followedPosts = publicTimelinePosts.filter { post in
            guard let authorId = post.authorId else { return false }
            
            // ローカルの推し、またはリモートでフォローしている推しなら表示
            let isLocalOshi = oshiList.contains(where: { $0.id == authorId })
            let isRemoteFollow = followingRemoteOshiIDs.contains(authorId)
            
            return isLocalOshi || isRemoteFollow
        }
        
        combined.append(contentsOf: followedPosts)
        
        // 3. 重複排除（念のため）と日付順ソート
        // PostがHashable準拠でない場合はIDで重複排除
        let uniquePosts = Array(Dictionary(grouping: combined, by: { $0.id }).values.compactMap { $0.first })
        
        return uniquePosts.sorted { $0.timestamp > $1.timestamp }
    }
    
    // ✅ 修正: 公開タイムラインの投稿をそのまま返すように変更
    // これにより、他のユーザーが作成した共有(公開)推しの投稿が表示されるようになります
    var recommendedPosts: [Post] {
        return publicTimelinePosts.sorted { $0.timestamp > $1.timestamp }
    }
    
    init() {
        Task {
            await loadData()
        }
        startAutoPosting()
        startAutoFollowing()
    }
    
    convenience init(mock: Bool) {
        self.init(skipLoadAndTimers: true)
        guard mock else { return }
        
        var oshi1 = OshiCharacter(
            name: "レン",
            personalityText: "クールで無口。たまに甘い",
            speechStyleText: "タメ口。語尾は短め"
        )
        
        var oshi2 = OshiCharacter(
            name: "ユイ",
            personalityText: "優しくて面倒見がいい",
            speechStyleText: "敬語寄りで丁寧"
        )
        
        self.oshiList = [oshi1, oshi2]
        
        var room1 = ChatRoom(oshiId: oshi1.id)
        var room2 = ChatRoom(oshiId: oshi2.id)
        
        room1.addMessage(Message(content: "おはよ!今日もえらい!", isFromUser: false, oshiId: oshi1.id))
        room1.addMessage(Message(content: "ありがとう!", isFromUser: true))
        
        room2.addMessage(Message(content: "今日なにしてた?", isFromUser: false, oshiId: oshi2.id))
        
        self.chatRooms = [room1, room2]
    }
    
    func followOshi(_ oshi: OshiCharacter) async {
        guard let index = oshiList.firstIndex(where: { $0.id == oshi.id }) else { return }
        
        oshiList[index].isFollowedByUser = true  // ← これだけ
        
        do {
            try await dbManager.saveOshi(oshiList[index])
            
            // 相互フォローになった場合、挨拶メッセージを送る
            if oshiList[index].isMutualFollow {
                await sendMutualFollowMessage(to: oshiList[index])
            }
            
            print("✅ \(oshi.name)をフォローしました")
        } catch {
            errorMessage = "フォローに失敗しました"
            print("❌ フォローエラー: \(error)")
        }
    }
    
    func isReposted(_ post: Post) -> Bool {
        return repostedPostIDs.contains(post.id)
    }

    /// リツイート情報の初期読み込み（.taskなどで呼ぶ）
    func loadUserReposts() async {
        do {
            let ids = try await dbManager.loadUserRepostIDs()
            await MainActor.run {
                self.repostedPostIDs = Set(ids)
            }
        } catch {
            print("❌ リツイート情報読み込みエラー: \(error)")
        }
    }

    /// リツイート切り替え
    func toggleRepost(for post: Post) {
        let isCurrentlyReposted = repostedPostIDs.contains(post.id)
        
        // 1. UIを即時更新 (楽観的UI更新)
        if isCurrentlyReposted {
            repostedPostIDs.remove(post.id)
            if let idx = posts.firstIndex(where: { $0.id == post.id }) {
                posts[idx].repostCount = max(0, posts[idx].repostCount - 1)
            }
        } else {
            repostedPostIDs.insert(post.id)
            if let idx = posts.firstIndex(where: { $0.id == post.id }) {
                posts[idx].repostCount += 1
            }
        }
        
        // 振動フィードバック
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // 2. 非同期でDB更新
        Task {
            do {
                if isCurrentlyReposted {
                    try await dbManager.unrepostPost(postId: post.id)
                } else {
                    try await dbManager.repostPost(postId: post.id)
                }
            } catch {
                print("❌ リツイート処理エラー: \(error)")
                // エラー時はUIを戻す処理を入れるのが丁寧ですが、ここでは省略
            }
        }
    }

    // アプリ起動時などに呼び出してブックマーク状態を同期する
    func loadUserBookmarks() async {
        do {
            let ids = try await dbManager.loadBookmarkIDs()
            await MainActor.run {
                self.bookmarkedPostIDs = Set(ids)
            }
        } catch {
            print("❌ ブックマークID読み込みエラー: \(error)")
        }
    }

    /// 投稿がブックマーク済みかチェック
    func isBookmarked(_ post: Post) -> Bool {
        return bookmarkedPostIDs.contains(post.id)
    }

    /// ブックマークの切り替え（保存/削除）
    func toggleBookmark(for post: Post) {
        if bookmarkedPostIDs.contains(post.id) {
            // 削除処理
            bookmarkedPostIDs.remove(post.id)
            // 一覧データからも削除
            if let index = bookmarkedPosts.firstIndex(where: { $0.id == post.id }) {
                bookmarkedPosts.remove(at: index)
            }
            
            Task {
                try? await dbManager.deleteBookmark(postId: post.id)
            }
        } else {
            // 保存処理
            bookmarkedPostIDs.insert(post.id)
            
            Task {
                try? await dbManager.saveBookmark(postId: post.id)
            }
        }
        // 振動フィードバック
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// ブックマーク一覧画面用のデータを取得（IDリストから投稿実体を取得）
    func fetchBookmarkedPosts() async {
        do {
            // 1. 最新のIDリストを取得
            let ids = try await dbManager.loadBookmarkIDs()
            
            await MainActor.run {
                self.bookmarkedPostIDs = Set(ids)
            }
            
            guard !ids.isEmpty else {
                await MainActor.run { self.bookmarkedPosts = [] }
                return
            }
            
            // 2. 投稿データをDBから取得
            let posts = try await dbManager.loadPosts(by: ids)
            
            await MainActor.run {
                self.bookmarkedPosts = posts
            }
        } catch {
            print("❌ ブックマーク一覧取得エラー: \(error)")
        }
    }

    /// ユーザーから推しをフォロー解除
    func unfollowOshi(_ oshi: OshiCharacter) async {
        guard let index = oshiList.firstIndex(where: { $0.id == oshi.id }) else { return }
        
        oshiList[index].isFollowedByUser = false
        
        do {
            try await dbManager.saveOshi(oshiList[index])
            print("✅ \(oshi.name)のフォローを解除しました")
        } catch {
            errorMessage = "フォロー解除に失敗しました"
            print("❌ フォロー解除エラー: \(error)")
        }
    }

    /// 推しからユーザーへのフォロー（自動実行）
    func oshiFollowsUser(_ oshi: OshiCharacter) async {
        guard let index = oshiList.firstIndex(where: { $0.id == oshi.id }) else { return }
        
        oshiList[index].isFollowingUser = true
        
        do {
            try await dbManager.saveOshi(oshiList[index])
            
            // フォロー通知を作成
            createFollowNotification(from: oshiList[index])
            
            // 相互フォローになった場合、挨拶メッセージを送る
            if oshiList[index].isMutualFollow {
                await sendMutualFollowMessage(to: oshiList[index])
            }
            
            print("✅ \(oshi.name)があなたをフォローしました")
        } catch {
            print("❌ フォローエラー: \(error)")
        }
    }

    /// 相互フォローになった時の挨拶メッセージ
    private func sendMutualFollowMessage(to oshi: OshiCharacter) async {
        // 1. チャットルームを探す、なければ作る
        var roomIndex = chatRooms.firstIndex(where: { $0.oshiId == oshi.id })
        
        if roomIndex == nil {
            // ルームがない場合は新規作成
            let newRoom = ChatRoom(oshiId: oshi.id)
            chatRooms.append(newRoom)
            roomIndex = chatRooms.count - 1 // 追加した末尾のインデックス
            
            do {
                try await dbManager.saveChatRoom(newRoom)
                print("✅ チャットルームを自動作成しました: \(oshi.name)")
            } catch {
                print("❌ チャットルーム作成エラー: \(error)")
                return
            }
        }
        
        // インデックスを確定
        guard let index = roomIndex else { return }
        
        do {
            // 2. AIによる挨拶メッセージ生成
            let greeting = try await aiService.generateGreeting(
                type: .mutualFollow,
                by: oshi,
                userName: userProfileName
            )
            
            // 3. メッセージの作成と保存
            let message = Message(content: greeting, isFromUser: false, oshiId: oshi.id)
            
            // ローカルのチャットルームに追加
            chatRooms[index].addMessage(message)
            
            // Firebaseに保存
            try await dbManager.addMessage(to: oshi.id, message: message)
            
            // 通知を作成
            createChatNotification(oshi: oshi, message: message)
            
            print("✅ 相互フォローメッセージ送信完了: \(greeting)")
            
        } catch {
            print("❌ 相互フォロー挨拶エラー: \(error)")
        }
    }
    
    private func startAutoFollowing() {
        // 30分〜2時間に1回、ランダムなプリセット推しからフォローされる
        autoFollowTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: TimingConfig.AutoEvent.followIntervalRange), repeats: true) { [weak self] _ in
                Task { @MainActor in
                    await self?.randomPresetFollow()
                }
            }
        
        // 初回実行(30秒〜5分後にランダム実行)
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 5...5)) {
            Task { @MainActor in
                await self.randomPresetFollow()
            }
        }
    }

    /// ランダムなプリセット推しからフォローされる
    private func randomPresetFollow() async {
        // まだフォローしていないプリセット推しを取得
        let unfollowedPresets = recommendedOshis.filter { preset in
            !oshiList.contains(where: { $0.id == preset.id })
        }
        
        guard !unfollowedPresets.isEmpty else {
            print("⚠️ すべてのプリセット推しをフォロー済み")
            return
        }
        
        // ランダムに1人選択
        guard let selectedPreset = unfollowedPresets.randomElement() else { return }
        
        print("🎉 \(selectedPreset.name)からフォローされました!")
        
        // フォロー処理（推しがユーザーをフォロー）
        var newOshi = selectedPreset
        newOshi.isFollowingUser = true
        
        try? await dbManager.saveOshi(newOshi)
    
        oshiList.insert(newOshi, at: 0)
        
        // フォロー通知を作成
        createFollowNotification(from: newOshi)
    }

    /// フォロー通知を作成
    private func createFollowNotification(from oshi: OshiCharacter) {
        let notification = AppNotification(
            type: .follow,
            senderId: oshi.id,
            senderName: oshi.name,
            content: ""
        )
        addNotification(notification)
    }
    
    private convenience init(skipLoadAndTimers: Bool) {
        self.init()
        if skipLoadAndTimers {
            autoPostTimer?.invalidate()
            autoPostTimer = nil
            cancellables.removeAll()
            
            self.oshiList = []
            self.posts = []
            self.chatRooms = []
        }
    }

    func followRecommended(_ preset: OshiCharacter) async {
        do {
            if oshiList.contains(where: { $0.id == preset.id }) { return }

            var followedOshi = preset
            followedOshi.isFollowingUser = true
            followedOshi.isFollowedByUser = true

            try await dbManager.saveOshi(followedOshi)
            oshiList.insert(followedOshi, at: 0)
            
            // リロードして反映
            let reloadedList = try await dbManager.loadOshiList()
            if let reloaded = reloadedList.first(where: { $0.id == preset.id }),
               let idx = oshiList.firstIndex(where: { $0.id == preset.id }) {
                oshiList[idx] = reloaded
            }

            if !chatRooms.contains(where: { $0.oshiId == preset.id }) {
                let room = ChatRoom(id: UUID(), oshiId: preset.id, messages: [], lastMessageDate: nil, unreadCount: 0)
                try await dbManager.saveChatRoom(room)
                chatRooms.append(room)
            }
            
            // ✅ 修正: 初期メッセージ生成にAIを使用するか、固定文言でも呼び名を反映
            // ここでは簡易的に呼び名メソッドを使用
            let callingName = followedOshi.callingName(userName: userProfileName)
            let welcome = Message(
                id: UUID(),
                content: "フォローありがとう、\(callingName)! これからたくさん話そう☺️",
                isFromUser: false,
                oshiId: preset.id,
                timestamp: Date(),
                isRead: false
            )

            try await dbManager.addMessage(to: preset.id, message: welcome)
            if let idx = chatRooms.firstIndex(where: { $0.oshiId == preset.id }) {
                var room = chatRooms[idx]
                room.messages.append(welcome)
                room.lastMessageDate = welcome.timestamp
                room.unreadCount += 1
                chatRooms[idx] = room
            }

        } catch {
            print("❌ followRecommended error: \(error)")
        }
    }
    
    @MainActor
    func updatePresetOshi(_ oshi: OshiCharacter) async {
        do {
            print("🛠️ updatePresetOshi start id=\(oshi.id.uuidString) name=\(oshi.name)")
            try await dbManager.savePresetOshi(oshi)
            print("✅ updatePresetOshi success id=\(oshi.id.uuidString)")

            if let idx = recommendedOshis.firstIndex(where: { $0.id == oshi.id }) {
                recommendedOshis[idx] = oshi
            }
        } catch {
            print("❌ updatePresetOshi failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            async let oshiListTask = dbManager.loadOshiList()
            async let myPostsTask = dbManager.loadMyPosts(limit: 50)
            async let publicPostsTask = dbManager.loadPublicPosts(limit: 50)
            async let chatRoomsTask = dbManager.loadChatRooms()
            async let userProfileTask = dbManager.loadUserProfile()
            async let followingTask = dbManager.loadFollowingIds() // 1. タスク定義

            // 2. タプルに loadedFollowingIDs と followingTask を追加
            let (loadedOshi, loadedMyPosts, loadedPublicPosts, loadedRooms, profile, loadedFollowingIDs) =
                try await (oshiListTask, myPostsTask, publicPostsTask, chatRoomsTask, userProfileTask, followingTask)

            oshiList = loadedOshi
            posts = loadedMyPosts
            publicTimelinePosts = loadedPublicPosts
            
            // 3. これで変数が使えるようになります
            followingRemoteOshiIDs = Set(loadedFollowingIDs)
            
            chatRooms = loadedRooms
            userProfileName = profile.userName
            userProfileAvatarURL = profile.avatarImageURL

        } catch {
            errorMessage = "データの読み込みに失敗しました: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func toggleFollowRemoteOshi(oshiId: UUID) {
        if followingRemoteOshiIDs.contains(oshiId) {
            // 解除
            followingRemoteOshiIDs.remove(oshiId)
            Task {
                try? await dbManager.unfollowRemoteOshi(oshiId: oshiId)
            }
        } else {
            // フォロー
            followingRemoteOshiIDs.insert(oshiId)
            Task {
                try? await dbManager.followRemoteOshi(oshiId: oshiId)
            }
        }
        // 振動フィードバック
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// フォロー状態確認用ヘルパー
    func isFollowing(oshiId: UUID) -> Bool {
        // ローカルにいるか、リモートリストにあるか
        return oshiList.contains(where: { $0.id == oshiId }) || followingRemoteOshiIDs.contains(oshiId)
    }

    /// ✅ 通知だけを個別に読み込む関数を追加
    func fetchNotifications() async {
        do {
            // 1. 最新の通知を取得して表示 (最大100件)
            let loadedNotifications = try await dbManager.loadNotifications(limit: 100)
            
            await MainActor.run {
                self.notifications = loadedNotifications
            }
            
            // 2. 古いデータの削除を実行 (バックグラウンド)
            Task {
                await deleteOldNotifications()
            }
            
        } catch {
            print("⚠️ 通知の読み込みに失敗: \(error.localizedDescription)")
        }
    }

    private func deleteOldNotifications() async {
        // 現在時刻から30日引く (秒数計算)
        // 確実に「過去」の日付になっていることを確認
        let thirtyDaysAgo = Date().addingTimeInterval(-(60 * 60 * 24 * 30))
        
        do {
            // Firebaseから削除
            try await dbManager.deleteOldNotifications(olderThan: thirtyDaysAgo)
            
            // 現在表示中のリストからも、もし古いものが混ざっていれば削除
            await MainActor.run {
                notifications.removeAll { notification in
                    notification.timestamp < thirtyDaysAgo
                }
            }
        } catch {
            print("⚠️ 古い通知の削除に失敗: \(error)")
        }
    }
    // MARK: - 推し管理
    
    func addOshi(_ oshi: OshiCharacter, isPublic: Bool = false) {
        Task {
            do {
                var newOshi = oshi
                newOshi.isPublic = isPublic // ✅ 共有フラグを設定
                newOshi.isFollowedByUser = true
                
                // ✅ 追加: 最初から推しもユーザーをフォローしている状態にする（相互フォロー）
                newOshi.isFollowingUser = true
                
                // 1. ローカルリストに追加
                oshiList.append(newOshi)
                try await dbManager.saveOshi(newOshi)
                
                // 2. チャットルーム作成
                let chatRoom = ChatRoom(oshiId: newOshi.id)
                chatRooms.append(chatRoom)
                try await dbManager.saveChatRoom(chatRoom)
                
                // 3. 挨拶
                await sendInitialGreeting(to: newOshi)
                
                print("✅ ユーザー推し追加完了: \(newOshi.name) (共有: \(isPublic))")
            } catch {
                print("❌ 推し追加エラー: \(error)")
                errorMessage = "推しの保存に失敗しました"
            }
        }
    }
    
    func updateOshi(_ oshi: OshiCharacter) {
        Task {
            do {
                if let index = oshiList.firstIndex(where: { $0.id == oshi.id }) {
                    oshiList[index] = oshi
                    try await dbManager.saveOshi(oshi)
                    print("✅ 推し更新成功: \(oshi.name)")
                }
            } catch {
                errorMessage = "推しの更新に失敗しました: \(error.localizedDescription)"
                print("❌ 推し更新エラー: \(error)")
            }
        }
    }
    
    func deleteOshi(_ oshi: OshiCharacter) {
        Task {
            do {
                oshiList.removeAll { $0.id == oshi.id }
                chatRooms.removeAll { $0.oshiId == oshi.id }
                posts.removeAll { $0.authorId == oshi.id }
                
                try await dbManager.deleteOshi(oshi.id)
                
                print("✅ 推し削除成功: \(oshi.name)")
                
            } catch {
                errorMessage = "推しの削除に失敗しました: \(error.localizedDescription)"
                print("❌ 推し削除エラー: \(error)")
            }
        }
    }
    
    // MARK: - タイムライン(最適化版)
    
    func createUserPost(content: String) {
        let post = Post(authorName: "あなた", content: content, isUserPost: true)
        posts.insert(post, at: 0)
        
        // ✅ 空のPostDetailsを作成(即座に表示できるように)
        postDetails[post.id] = PostDetails(post: post, reactions: [], comments: [], hasMoreComments: false)
        
        Task {
            do {
                try await dbManager.savePost(post)
                
                // すべての推しが反応(遅延実行)
                try await Task.sleep(nanoseconds: UInt64.random(in: TimingConfig.nanoseconds(TimingConfig.Reaction.startDelayRange)))
                await generateReactionsForPost(post)
                
            } catch {
                errorMessage = "投稿の保存に失敗しました: \(error.localizedDescription)"
                print("❌ 投稿保存エラー: \(error)")
            }
        }
    }
    
    // ✅ 最適化版: リアクション・コメントを個別に保存し、即座にUIに反映
    private func generateReactionsForPost(_ post: Post) async {
        guard let postIndex = posts.firstIndex(where: { $0.id == post.id }) else { return }
        
        // analyzeMoodは String を返すようになっています
        let mood = aiService.analyzeMood(from: post.content)
        
        let commentersCount = min(Int.random(in: 2...3), oshiList.count)
        let selectedCommenters = selectCommentersWithIntimacy(count: commentersCount)
        
        for oshi in oshiList {
            try? await Task.sleep(nanoseconds: UInt64.random(in: TimingConfig.nanoseconds(TimingConfig.Reaction.likeDelayRange)))
            // いいね処理 (変更なし)
            if Double.random(in: 0...1) < Double.random(in: 0.6...0.9) {
                let reaction = Reaction(oshiId: oshi.id, oshiName: oshi.name)
                try? await dbManager.addReaction(reaction, to: post.id)
                if post.isUserPost { createReactionNotification(oshi: oshi, post: post) }
                if let idx = posts.firstIndex(where: { $0.id == post.id }) { posts[idx].reactionCount += 1 }
                if var details = postDetails[post.id] {
                    details.reactions.append(reaction)
                    postDetails[post.id] = details
                }
            }
            
            // コメント処理
            if selectedCommenters.contains(where: { $0.id == oshi.id }) {
                do {
                    try await Task.sleep(nanoseconds: UInt64.random(in: TimingConfig.nanoseconds(TimingConfig.Reaction.commentDelayRange)))
                    
                    // ✅ 修正: mood は String なので .rawValue は不要
                    let commentText = try await aiService.generateComment(
                        for: post,
                        by: oshi,
                        userMood: mood, // ← ここを修正
                        userName: userProfileName
                    )
                    
                    let comment = Comment(oshiId: oshi.id, oshiName: oshi.name, content: commentText)
                    try await dbManager.addComment(comment, to: post.id)
                    
                    if post.isUserPost { createCommentNotification(oshi: oshi, post: post, commentContent: commentText) }
                    if let idx = posts.firstIndex(where: { $0.id == post.id }) { posts[idx].commentCount += 1 }
                    if var details = postDetails[post.id] {
                        details.comments.append(comment)
                        postDetails[post.id] = details
                    }
                    if let oshiIdx = oshiList.firstIndex(where: { $0.id == oshi.id }) {
                        oshiList[oshiIdx].increaseIntimacy(by: 2)
                        try await dbManager.saveOshi(oshiList[oshiIdx])
                    }
                } catch {
                    print("❌ コメント生成エラー: \(error)")
                }
            }
        }
    }
    
    func deleteRecommendedOshi(_ oshi: OshiCharacter) async {
        do {
            // Firestoreから削除
            try await dbManager.deletePresetOshi(oshi.id)
            
            // ローカルリストから削除
            recommendedOshis.removeAll { $0.id == oshi.id }
            
            print("✅ おすすめ削除成功: \(oshi.name)")
        } catch {
            print("❌ おすすめ削除エラー: \(error)")
            errorMessage = "おすすめの削除に失敗しました"
        }
    }

    // ✅ 親密度ベースの重み付き抽選システム
    private func selectCommentersWithIntimacy(count: Int) -> [OshiCharacter] {
        guard !oshiList.isEmpty else { return [] }
        
        // 親密度をベースにした重み計算
        let weighedOshis: [(oshi: OshiCharacter, weight: Double)] = oshiList.map { oshi in
            // 基本重み: 親密度による重み(1〜10)
            let intimacyWeight = max(1.0, Double(oshi.totalInteractions) / 10.0)
            
            // ランダム要素: 0.5〜1.5倍のランダムブースト(決まった人だけにならないように)
            let randomBoost = Double.random(in: 0.5...1.5)
            
            // 最終重み
            let finalWeight = intimacyWeight * randomBoost
            
            return (oshi, finalWeight)
        }
        
        // 重みが高い順にソート
        let sortedOshis = weighedOshis.sorted { $0.weight > $1.weight }
        
        // 上位から選択(ただし完全に上位だけでなく、若干のランダム性を持たせる)
        var selected: [OshiCharacter] = []
        
        for (index, item) in sortedOshis.enumerated() {
            if selected.count >= count { break }
            
            // 上位ほど選ばれやすいが、下位にもチャンスを与える
            let selectionProbability: Double
            if index == 0 {
                selectionProbability = 0.9  // 1位: 90%
            } else if index == 1 {
                selectionProbability = 0.8  // 2位: 80%
            } else if index == 2 {
                selectionProbability = 0.6  // 3位: 60%
            } else {
                selectionProbability = 0.3  // 4位以降: 30%
            }
            
            if Double.random(in: 0...1) < selectionProbability {
                selected.append(item.oshi)
            }
        }
        
        // もし誰も選ばれなかった場合は、トップ2を強制選択
        if selected.isEmpty {
            selected = Array(sortedOshis.prefix(min(2, sortedOshis.count)).map { $0.oshi })
        }
        
        return selected
    }
    
    func addUserComment(to post: Post, content: String) {
        // ユーザーを表す固定UUID（いいね機能と同じIDを使用）
        let userId = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()
        
        // Commentモデルを作成（oshiNameには現在のユーザー名を使用）
        let comment = Comment(
            oshiId: userId,
            oshiName: userProfileName,
            content: content
        )
        
        Task {
            do {
                // 1. Firebaseに保存
                try await dbManager.addComment(comment, to: post.id)
                
                // 2. ローカルの表示を即時更新
                await MainActor.run {
                    if var details = postDetails[post.id] {
                        details.comments.append(comment)
                        postDetails[post.id] = details
                    } else {
                        // 詳細が未ロードの場合（稀なケース）
                        postDetails[post.id] = PostDetails(post: post, comments: [comment])
                    }
                    
                    // 投稿一覧のコメント数カウントも更新
                    if let idx = posts.firstIndex(where: { $0.id == post.id }) {
                        posts[idx].commentCount += 1
                    }
                }
                
                print("✅ コメント投稿成功: \(content)")
                
                // 必要であれば、推しからの返信ロジックなどをここに追記可能
                
            } catch {
                print("❌ コメント投稿エラー: \(error)")
                await MainActor.run {
                    errorMessage = "コメントの投稿に失敗しました"
                }
            }
        }
    }
    
    func createOshiPost(by oshi: OshiCharacter) {
        Task {
            do {
                let content = try await aiService.generateOshiPost(by: oshi)
                
                let post = Post(
                    authorId: oshi.id,
                    authorName: oshi.name,
                    content: content,
                    isUserPost: false
                )
                
                // UIへの即時反映
                posts.insert(post, at: 0)
                
                // ✅ 追加: 公開推しの場合は、公開タイムライン(おすすめ)にも即時反映
                if oshi.isPublic {
                    publicTimelinePosts.insert(post, at: 0)
                }
                
                // 保存: ここで isPublic フラグを使用
                try await dbManager.savePost(post, isPublic: oshi.isPublic)
                
                // ✅ 修正: 相互フォローの場合のみ通知を作成
                if oshi.isMutualFollow {
                    createOshiPostNotification(oshi: oshi, post: post)
                }
                
                print("✅ 推しの投稿作成成功: \(oshi.name)")
                
            } catch {
                errorMessage = "推しの投稿作成に失敗しました: \(error.localizedDescription)"
                print("❌ 推しの投稿作成エラー: \(error)")
            }
        }
    }
    
    func reactToOshiPost(_ post: Post) {
        guard let oshiId = post.authorId,
              let oshiIndex = oshiList.firstIndex(where: { $0.id == oshiId }) else { return }
        
        Task {
            do {
                oshiList[oshiIndex].increaseIntimacy(by: 1)
                try await dbManager.saveOshi(oshiList[oshiIndex])
            } catch {
                print("❌ 親密度更新エラー: \(error)")
            }
        }
    }
    
    func createUserPost(content: String, imageURLs: [String] = []) {
        print("📝 createUserPost開始")
        print("  - テキスト: \(content)")
        print("  - 画像数: \(imageURLs.count)")
        
        let post = Post(
            authorName: "あなた",
            content: content,
            isUserPost: true,
            imageURLs: imageURLs
        )
        
        posts.insert(post, at: 0)
        
        // ✅ 空のPostDetailsを作成(即座に表示できるように)
        postDetails[post.id] = PostDetails(
            post: post,
            reactions: [],
            comments: [],
            hasMoreComments: false
        )
        
        print("✅ ローカルに投稿追加完了")
        
        Task {
            do {
                print("💾 Firebaseに保存中...")
                try await dbManager.savePost(post)
                print("✅ Firebase保存完了")
                
                // すべての推しが反応(遅延実行)
                let delay = UInt64.random(in: 60_000_000_000...300_000_000_000)
                print("⏱️ \(Double(delay) / 1_000_000_000)秒後に反応生成開始")
                try await Task.sleep(nanoseconds: delay)
                
                await generateReactionsForPost(post)
                print("✅ 反応生成完了")
                
            } catch {
                await MainActor.run {
                    errorMessage = "投稿の保存に失敗しました: \(error.localizedDescription)"
                    print("❌ 投稿保存エラー: \(error)")
                }
            }
        }
    }
    
    // MARK: - ユーザーからのいいね
    
    /// ユーザーが投稿にいいねする
    func toggleUserReaction(on post: Post) {
        Task {
            // 1. UIの即時反映（IDリストの更新）
            // 現在の状態を確認して反転させる
            let isLiking = !likedPostIDs.contains(post.id)
            
            if isLiking {
                likedPostIDs.insert(post.id)
            } else {
                likedPostIDs.remove(post.id)
            }

            // 振動フィードバック
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

            do {
                // ユーザーを表す固定ID
                let userId = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()

                // 詳細データがまだない場合はロードする
                if postDetails[post.id] == nil {
                    await loadPostDetails(for: post.id)
                }

                // ロード後に再度確認
                if var details = postDetails[post.id] {
                    // 既にいいねしているか確認
                    if let existingIndex = details.reactions.firstIndex(where: { $0.oshiId == userId }) {
                        // 既にいいね済み -> 削除処理
                        // (もしUI操作がいいね追加だった場合、ここで矛盾が生じるが、基本的には同期する)
                        let removedReaction = details.reactions.remove(at: existingIndex)
                        postDetails[post.id] = details // ローカル更新
                        
                        try await dbManager.deleteReaction(removedReaction, from: post.id)
                        
                        // 投稿一覧のカウント更新
                        if let idx = posts.firstIndex(where: { $0.id == post.id }) {
                             posts[idx].reactionCount = max(0, posts[idx].reactionCount - 1)
                        }
                    } else {
                        // いいねしていない -> 追加処理
                        let reaction = Reaction(oshiId: userId, oshiName: "あなた")
                        details.reactions.append(reaction)
                        postDetails[post.id] = details // ローカル更新
                        
                        try await dbManager.addReaction(reaction, to: post.id)
                        
                        // 投稿一覧のカウント更新
                         if let idx = posts.firstIndex(where: { $0.id == post.id }) {
                             posts[idx].reactionCount += 1
                        }
                    }
                }
            } catch {
                // エラー時はUIを元の状態に戻す
                if isLiking {
                     likedPostIDs.remove(post.id)
                } else {
                     likedPostIDs.insert(post.id)
                }
                print("❌ いいね処理エラー: \(error)")
            }
        }
    }
    
    func loadUserLikes() async {
        do {
            let ids = try await dbManager.loadUserLikedPostIDs()
            await MainActor.run {
                self.likedPostIDs = Set(ids)
            }
        } catch {
            print("❌ いいね情報読み込みエラー: \(error)")
        }
    }
    
    /// ユーザーがすでにいいねしているかチェック
    func hasUserReacted(to post: Post) -> Bool {
        // 詳細データがロードされていなくても、IDリストにあれば「いいね済み」と判定
        return likedPostIDs.contains(post.id)
    }
    
    // MARK: - 投稿詳細の取得
    
    /// 投稿の詳細(リアクション・コメント)を取得
    func loadPostDetails(for postId: UUID) async {
        // すでに読み込み済みならスキップ
        if postDetails[postId] != nil {
            return
        }
        
        do {
            async let reactionsTask = dbManager.loadReactions(for: postId)
            async let commentsTask = dbManager.loadComments(for: postId, limit: 10)
            
            let (reactions, comments) = try await (reactionsTask, commentsTask)
            
            if let post = posts.first(where: { $0.id == postId }) {
                let hasMore = comments.count >= 10
                postDetails[postId] = PostDetails(
                    post: post,
                    reactions: reactions,
                    comments: comments,
                    hasMoreComments: hasMore
                )
            }
            
        } catch {
            print("⚠️ 投稿詳細の読み込みスキップ: \(error.localizedDescription)")
            // エラー時は空のPostDetailsを作成
            if let post = posts.first(where: { $0.id == postId }) {
                postDetails[postId] = PostDetails(
                    post: post,
                    reactions: [],
                    comments: [],
                    hasMoreComments: false
                )
            }
        }
    }
    
    /// さらにコメントを読み込む
    func loadMoreComments(for postId: UUID) async {
        guard var details = postDetails[postId],
              let lastComment = details.comments.last else { return }
        
        do {
            let moreComments = try await dbManager.loadComments(
                for: postId,
                limit: 10,
                before: lastComment.timestamp
            )
            
            details.comments.append(contentsOf: moreComments)
            details.hasMoreComments = moreComments.count >= 10
            postDetails[postId] = details
            
        } catch {
            print("❌ 追加コメントの読み込みエラー: \(error)")
        }
    }
    
    // MARK: - チャット
    
    func sendMessage(to oshiId: UUID, content: String) {
        guard let roomIndex = chatRooms.firstIndex(where: { $0.oshiId == oshiId }),
              let oshi = oshiList.first(where: { $0.id == oshiId }) else { return }
        
        let userMessage = Message(content: content, isFromUser: true)
        chatRooms[roomIndex].addMessage(userMessage)
        
        Task {
            do {
                try await dbManager.addMessage(to: oshiId, message: userMessage)
                if let oshiIndex = oshiList.firstIndex(where: { $0.id == oshiId }) {
                    oshiList[oshiIndex].increaseIntimacy(by: 3)
                    try await dbManager.saveOshi(oshiList[oshiIndex])
                }
                
                try await Task.sleep(nanoseconds: UInt64.random(in: TimingConfig.nanoseconds(TimingConfig.Chat.replyDelayRange)))
                
                // ✅ 修正: userNameを渡す
                let reply = try await aiService.generateChatReply(
                    for: content,
                    by: oshi,
                    conversationHistory: chatRooms[roomIndex].messages,
                    userName: userProfileName
                )
                
                let aiMessage = Message(content: reply, isFromUser: false, oshiId: oshiId)
                chatRooms[roomIndex].addMessage(aiMessage)
                try await dbManager.addMessage(to: oshiId, message: aiMessage)
                createChatNotification(oshi: oshi, message: aiMessage)
                
            } catch {
                errorMessage = "メッセージ送信エラー"
            }
        }
    }
    
    func markChatAsRead(oshiId: UUID) {
        if let roomIndex = chatRooms.firstIndex(where: { $0.oshiId == oshiId }) {
            chatRooms[roomIndex].markAllAsRead()
            
            Task {
                do {
                    try await dbManager.markChatAsRead(oshiId: oshiId)
                } catch {
                    print("❌ 既読更新エラー: \(error)")
                }
            }
        }
    }
    
    private func sendInitialGreeting(to oshi: OshiCharacter) async {
        guard let roomIndex = chatRooms.firstIndex(where: { $0.oshiId == oshi.id }) else { return }
        
        do {
            // ✅ 修正: userNameを渡す
            let aiGreeting = try await aiService.generateInitialGreeting(
                for: oshi,
                userName: userProfileName
            )
            
            let message = Message(content: aiGreeting, isFromUser: false, oshiId: oshi.id)
            chatRooms[roomIndex].addMessage(message)
            try await dbManager.addMessage(to: oshi.id, message: message)
            createChatNotification(oshi: oshi, message: message)
        } catch {
            print("❌ 初回挨拶エラー: \(error)")
        }
    }
    
    // MARK: - 自動投稿
    
    private func startAutoPosting() {
        autoPostTimer = Timer.scheduledTimer(withTimeInterval: TimingConfig.AutoEvent.postInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.randomOshiPost()
            }
        }
    }
    
    private func randomOshiPost() async {
        guard !oshiList.isEmpty else { return }
        
        if let randomOshi = oshiList.randomElement() {
            createOshiPost(by: randomOshi)
        }
    }
    
    private func addNotification(_ notification: AppNotification) {
        // ローカルに追加
        notifications.insert(notification, at: 0)
        
        // 100件を超えたらUI上は古いものを削除
        if notifications.count > 100 {
            notifications = Array(notifications.prefix(100))
        }
        
        // ✅ Firebaseに保存
        Task {
            do {
                try await dbManager.saveNotification(notification)
            } catch {
                print("❌ 通知の保存に失敗: \(error)")
            }
        }
    }

    /// 通知を既読にする
    func markNotificationAsRead(_ notificationId: UUID) {
        if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
            notifications[index].isRead = true
            
            // ✅ 保存データの既読状態も更新
            Task {
                try? await dbManager.updateNotificationReadStatus(notificationId, isRead: true)
            }
        }
    }

    /// すべての通知を既読にする
    func markAllNotificationsAsRead() {
        for index in notifications.indices {
            // まだ既読でないものだけ更新処理へ
            if !notifications[index].isRead {
                notifications[index].isRead = true
                let id = notifications[index].id
                Task {
                    try? await dbManager.updateNotificationReadStatus(id, isRead: true)
                }
            }
        }
    }

    /// すべての通知を削除
    func clearAllNotifications() {
        notifications.removeAll()
        
        // ✅ Firebaseからも全削除
        Task {
            try? await dbManager.clearAllNotifications()
        }
    }

    /// リアクション通知を作成
    private func createReactionNotification(oshi: OshiCharacter, post: Post) {
        let notification = AppNotification(
            type: .reaction,
            senderId: oshi.id,
            senderName: oshi.name,
            content: "",
            relatedPostId: post.id
        )
        addNotification(notification)
    }

    /// コメント通知を作成
    private func createCommentNotification(oshi: OshiCharacter, post: Post, commentContent: String) {
        let notification = AppNotification(
            type: .comment,
            senderId: oshi.id,
            senderName: oshi.name,
            content: commentContent,
            relatedPostId: post.id
        )
        addNotification(notification)
    }

    /// 推しの投稿通知を作成
    private func createOshiPostNotification(oshi: OshiCharacter, post: Post) {
        let notification = AppNotification(
            type: .oshiPost,
            senderId: oshi.id,
            senderName: oshi.name,
            content: post.content,
            relatedPostId: post.id
        )
        addNotification(notification)
    }

    /// チャットメッセージ通知を作成
    private func createChatNotification(oshi: OshiCharacter, message: Message) {
        let notification = AppNotification(
            type: .chat,
            senderId: oshi.id,
            senderName: oshi.name,
            content: message.content
        )
        addNotification(notification)
    }
    
    // MARK: - 高親密度での自発的メッセージ
    
    func checkProactiveMessages() {
        let hour = Calendar.current.component(.hour, from: Date())
        
        Task {
            for oshi in oshiList {
                guard let roomIndex = chatRooms.firstIndex(where: { $0.oshiId == oshi.id }) else { continue }
                
                if hour >= 7 && hour < 9 {
                    let lastMessage = chatRooms[roomIndex].messages.last
                    let isToday = Calendar.current.isDateInToday(lastMessage?.timestamp ?? Date.distantPast)
                    
                    if !isToday {
                        do {
                            // ✅ 修正: userNameを渡す
                            let greeting = try await aiService.generateGreeting(
                                type: .morning,
                                by: oshi,
                                userName: userProfileName
                            )
                            let message = Message(content: greeting, isFromUser: false, oshiId: oshi.id)
                            chatRooms[roomIndex].addMessage(message)
                            try await dbManager.addMessage(to: oshi.id, message: message)
                        } catch { print("挨拶エラー") }
                    }
                }
                
                if hour >= 22 && hour < 23 {
                    // 夜のロジックも同様に修正できるが、頻度制限など必要なら追加
                    do {
                         let nightMessage = try await aiService.generateGreeting(
                            type: .night,
                            by: oshi,
                            userName: userProfileName
                        )
                         // 保存処理...
                    } catch {}
                }
            }
        }
    }
}

// ViewModels/OshiViewModel.swift (修正版 - いいね機能追加)

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
    
    var timelinePosts: [Post] {
        posts.filter { post in
            // ユーザーの投稿は常に表示
            if post.isUserPost {
                return true
            }

            // 推しの投稿は自分がフォローしている場合のみ表示
            guard let authorId = post.authorId,
                  let oshi = oshiList.first(where: { $0.id == authorId }) else {
                return false
            }

            // 変更前: return oshi.isMutualFollow
            return oshi.isFollowedByUser // ✅ 修正: 自分がフォローしていれば表示
        }
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
        guard let roomIndex = chatRooms.firstIndex(where: { $0.oshiId == oshi.id }) else { return }
        
        do {
            let greeting = try await aiService.generateGreeting(type: .mutualFollow, by: oshi)
            
            let message = Message(
                content: greeting,
                isFromUser: false,
                oshiId: oshi.id
            )
            
            chatRooms[roomIndex].addMessage(message)
            try await dbManager.addMessage(to: oshi.id, message: message)
            
            createChatNotification(oshi: oshi, message: message)
            
            print("✅ 相互フォロー挨拶送信: \(oshi.name)")
        } catch {
            print("❌ 相互フォロー挨拶エラー: \(error)")
        }
    }
    
    private func startAutoFollowing() {
        // 30分〜2時間に1回、ランダムなプリセット推しからフォローされる
        autoFollowTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 1800...7200), repeats: true) { [weak self] _ in
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
            // すでにフォロー済みなら何もしない
            if oshiList.contains(where: { $0.id == preset.id }) { return }

            // ✅ 相互フォロー扱いにする
            var followedOshi = preset
            followedOshi.isFollowingUser = true  // 推しがユーザーをフォロー
            followedOshi.isFollowedByUser = true // ユーザーが推しをフォロー

            // 1) 推しを保存 & リスト反映
            try await dbManager.saveOshi(followedOshi)
            oshiList.insert(followedOshi, at: 0)
            let reloadedList = try await dbManager.loadOshiList()
            if let reloaded = reloadedList.first(where: { $0.id == preset.id }) {
                
                // ✅ ローカルリストも更新
                if let idx = oshiList.firstIndex(where: { $0.id == preset.id }) {
                    oshiList[idx] = reloaded
                }
            }

            // 2) チャットルームが無ければ作る(空メッセージでOK)
            if !chatRooms.contains(where: { $0.oshiId == preset.id }) {
                let room = ChatRoom(id: UUID(), oshiId: preset.id, messages: [], lastMessageDate: nil, unreadCount: 0)
                try await dbManager.saveChatRoom(room)
                chatRooms.append(room)
            }

            // 3) 推しから「最初の1通」を送る(保存されるのでチャットに出る)
            let welcome = Message(
                id: UUID(),
                content: "フォローありがとう、\(preset.userCallingName.isEmpty ? "ねえ" : preset.userCallingName)!これからたくさん話そう☺️",
                isFromUser: false,
                oshiId: preset.id,
                timestamp: Date(),
                isRead: false
            )

            try await dbManager.addMessage(to: preset.id, message: welcome)

            // 4) ローカルの chatRooms も即時反映(一覧にすぐ出すため)
            if let idx = chatRooms.firstIndex(where: { $0.oshiId == preset.id }) {
                var room = chatRooms[idx]
                room.messages.append(welcome)
                room.lastMessageDate = welcome.timestamp
                room.unreadCount += 1
                chatRooms[idx] = room
            }

        } catch {
            self.errorMessage = error.localizedDescription
            print("❌ followRecommended error: \(error.localizedDescription)")
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
            async let postsTask = dbManager.loadPosts(limit: 50)
            async let chatRoomsTask = dbManager.loadChatRooms()
            async let presetsTask = dbManager.fetchPresetOshis()
            async let userProfileTask = dbManager.loadUserProfile()
            // ❌ 通知の読み込み（notificationsTask）をここから削除

            let (loadedOshi, loadedPosts, loadedRooms, presets, profile) =
                try await (oshiListTask, postsTask, chatRoomsTask, presetsTask, userProfileTask)

            oshiList = loadedOshi
            recommendedOshis = presets
            posts = loadedPosts
            chatRooms = loadedRooms
            userProfileName = profile.userName
            userProfileAvatarURL = profile.avatarImageURL
            // notifications = loadedNotifications // ❌ ここも削除

            print("✅ データ読み込み成功: 推し\(oshiList.count)人, 投稿\(posts.count)件")
            
        } catch {
            errorMessage = "データの読み込みに失敗しました: \(error.localizedDescription)"
            print("❌ データ読み込みエラー: \(error)")
        }

        isLoading = false
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
    
    func addOshi(_ oshi: OshiCharacter) {
        Task {
            do {
                var newOshi = oshi
                
                oshiList.append(newOshi)
                
                try await dbManager.saveOshi(newOshi)
                
                let chatRoom = ChatRoom(oshiId: newOshi.id)
                chatRooms.append(chatRoom)
                try await dbManager.saveChatRoom(chatRoom)
                
                await sendInitialGreeting(to: newOshi)
                
                print("✅ 推し追加成功: \(newOshi.name)")
                
            } catch {
                errorMessage = "推しの追加に失敗しました: \(error.localizedDescription)"
                print("❌ 推し追加エラー: \(error)")
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
                try await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...3_000_000_000))
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
        
        let mood = aiService.analyzeMood(from: post.content)
        
        // ✅ コメントする人数をランダムに決定(2〜3人、推しが少ない場合は全員)
        let commentersCount = min(Int.random(in: 2...3), oshiList.count)
        
        // ✅ 親密度ベースの重み付き抽選
        let selectedCommenters = selectCommentersWithIntimacy(count: commentersCount)
        
        for oshi in oshiList {
            // ✅ いいね(全員が60〜90%の確率で反応)
            if Double.random(in: 0...1) < Double.random(in: 0.6...0.9) {
                let reaction = Reaction(oshiId: oshi.id, oshiName: oshi.name)
                
                do {
                    try await dbManager.addReaction(reaction, to: post.id)
                    
                    if post.isUserPost {
                        createReactionNotification(oshi: oshi, post: post)
                    }
                    
                    if let idx = posts.firstIndex(where: { $0.id == post.id }) {
                        posts[idx].reactionCount += 1
                    }
                    
                    if var details = postDetails[post.id] {
                        details.reactions.append(reaction)
                        postDetails[post.id] = details
                    }
                } catch {
                    print("❌ リアクション追加エラー: \(error)")
                }
            }
            
            // ✅ コメント(選ばれた推しのみ)
            if selectedCommenters.contains(where: { $0.id == oshi.id }) {
                do {
                    // ランダムな遅延(1〜5秒)
                    try await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...5_000_000_000))
                    
                    let commentText = try await aiService.generateComment(for: post, by: oshi, userMood: mood)
                    let comment = Comment(oshiId: oshi.id, oshiName: oshi.name, content: commentText)
                    
                    try await dbManager.addComment(comment, to: post.id)
                    
                    if post.isUserPost {
                        createCommentNotification(oshi: oshi, post: post, commentContent: commentText)
                    }
                    
                    if let idx = posts.firstIndex(where: { $0.id == post.id }) {
                        posts[idx].commentCount += 1
                    }
                    
                    if var details = postDetails[post.id] {
                        details.comments.append(comment)
                        postDetails[post.id] = details
                    } else {
                        if let currentPost = posts.first(where: { $0.id == post.id }) {
                            postDetails[post.id] = PostDetails(
                                post: currentPost,
                                reactions: postDetails[post.id]?.reactions ?? [],
                                comments: [comment],
                                hasMoreComments: false
                            )
                        }
                    }
                    
                    // 親密度アップ
                    if let oshiIdx = oshiList.firstIndex(where: { $0.id == oshi.id }) {
                        oshiList[oshiIdx].increaseIntimacy(by: 2)
                        try await dbManager.saveOshi(oshiList[oshiIdx])
                    }
                    
                } catch {
                    print("❌ \(oshi.name)のコメント生成失敗: \(error.localizedDescription)")
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
                let post = Post(authorId: oshi.id, authorName: oshi.name,
                               content: content, isUserPost: false)
                posts.insert(post, at: 0)
                
                try await dbManager.savePost(post)
                
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
                let delay = UInt64.random(in: 1_000_000_000...3_000_000_000)
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
            do {
                // ユーザーのいいねを表す特別なID
                let userId = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()
                
                // すでにいいねしているかチェック
                if var details = postDetails[post.id] {
                    if let existingIndex = details.reactions.firstIndex(where: { $0.oshiId == userId }) {
                        // いいね取り消し
                        let removedReaction = details.reactions.remove(at: existingIndex)
                        try await dbManager.deleteReaction(removedReaction, from: post.id)
                        
                        if let idx = posts.firstIndex(where: { $0.id == post.id }) {
                            posts[idx].reactionCount = max(0, posts[idx].reactionCount - 1)
                        }
                        
                        postDetails[post.id] = details
                    } else {
                        // いいね追加
                        let reaction = Reaction(
                            oshiId: userId,
                            oshiName: "あなた"
                        )
                        
                        try await dbManager.addReaction(reaction, to: post.id)
                        
                        if let idx = posts.firstIndex(where: { $0.id == post.id }) {
                            posts[idx].reactionCount += 1
                        }
                        
                        details.reactions.insert(reaction, at: 0)
                        postDetails[post.id] = details
                        
                        // 推しの投稿にいいねした場合は親密度アップ
                        if !post.isUserPost {
                            reactToOshiPost(post)
                        }
                    }
                } else {
                    // 詳細が未読み込みの場合は、まずロードしてからいいね
                    await loadPostDetails(for: post.id)
                    
                    // 再帰的に呼び出し
                    await toggleUserReaction(on: post)
                }
                
            } catch {
                print("❌ いいね処理エラー: \(error)")
                errorMessage = "いいねに失敗しました"
            }
        }
    }
    
    /// ユーザーがすでにいいねしているかチェック
    func hasUserReacted(to post: Post) -> Bool {
        let userId = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()
        
        guard let details = postDetails[post.id] else {
            return false
        }
        
        return details.reactions.contains(where: { $0.oshiId == userId })
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
                
                try await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...3_000_000_000))
                
                let reply = try await aiService.generateChatReply(
                    for: content,
                    by: oshi,
                    conversationHistory: chatRooms[roomIndex].messages
                )
                
                let aiMessage = Message(content: reply, isFromUser: false, oshiId: oshiId)
                chatRooms[roomIndex].addMessage(aiMessage)
                
                try await dbManager.addMessage(to: oshiId, message: aiMessage)
                
                if let oshi = oshiList.first(where: { $0.id == oshiId }) {
                    createChatNotification(oshi: oshi, message: aiMessage)
                }
                
                print("✅ チャット返信成功")
                
            } catch {
                errorMessage = "メッセージの送信に失敗しました。APIキーを確認してください。"
                print("❌ メッセージ送信エラー: \(error.localizedDescription)")
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
            let aiGreeting = try await aiService.generateInitialGreeting(for: oshi)
            
            let message = Message(content: aiGreeting, isFromUser: false, oshiId: oshi.id)
            chatRooms[roomIndex].addMessage(message)
            
            try await dbManager.addMessage(to: oshi.id, message: message)
            
            createChatNotification(oshi: oshi, message: message)
            
            print("✅ 初回挨拶成功: \(oshi.name)")
            
        } catch {
            print("❌ 初回挨拶エラー: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 自動投稿
    
    private func startAutoPosting() {
        autoPostTimer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
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
                            let greeting = try await aiService.generateGreeting(type: .morning, by: oshi)
                            let message = Message(content: greeting, isFromUser: false, oshiId: oshi.id)
                            chatRooms[roomIndex].addMessage(message)
                            try await dbManager.addMessage(to: oshi.id, message: message)
                        } catch {
                            print("❌ \(oshi.name)の朝の挨拶エラー: \(error.localizedDescription)")
                        }
                    }
                }
                
                if hour >= 22 && hour < 23 {
                    do {
                        let nightMessage = try await aiService.generateGreeting(type: .night, by: oshi)
                        let message = Message(content: nightMessage, isFromUser: false, oshiId: oshi.id)
                        chatRooms[roomIndex].addMessage(message)
                        try await dbManager.addMessage(to: oshi.id, message: message)
                    } catch {
                        print("❌ \(oshi.name)の夜の挨拶エラー: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

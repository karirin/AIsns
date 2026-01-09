// ViewModels/OshiViewModel.swift (修正版 - おすすめタイムライン修正 + 通知フラッシュ対策)

import Foundation
import Combine
import UIKit
import SwiftUI

@MainActor
class OshiViewModel: ObservableObject {
    @Published var oshiList: [OshiCharacter] = []
    @Published var followingOshis: [OshiCharacter] = []
    @Published var isLoadingList = false
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
    @Published var blockedUserIDs: Set<String> = []
    @Published var messageCount: Int = 0
    private let maxMessageLimit = 10
    
    // ✅ 投稿の詳細情報(必要な時だけ取得)
    @Published var postDetails: [UUID: PostDetails] = [:]
    
    private let aiService = AIService.shared
    private let dbManager = FirebaseDatabaseManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var autoPostTimer: Timer?
    private var autoFollowTimer: Timer?
    private let notificationsStorageKey = "local_notifications_v1"
    
    var isMessageLimitReached: Bool {
        AppConfig.adGateEnabled && messageCount >= maxMessageLimit
    }

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
        return posts // ViewModel内ですでにマージ・ソート済み
    }
    
    // ✅ 修正: 公開タイムラインの投稿をそのまま返すように変更
    // これにより、他のユーザーが作成した共有(公開)推しの投稿が表示されるようになります
    var recommendedPosts: [Post] {
        return publicTimelinePosts
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
    
    func resetMessageLimit() {
        messageCount = 0
    }
    
    func blockUser(creatorId: String?, authorId: UUID?) {
        // creatorIdがあればそれを、なければauthorId(AI自身のID)をブロック対象とする
        guard let targetId = creatorId ?? authorId?.uuidString else { return }
        
        Task {
            do {
                try await dbManager.blockUser(targetUserId: targetId)
                
                await MainActor.run {
                    self.blockedUserIDs.insert(targetId)
                    
                    // 即座にリストから除外してUIに反映
                    self.applyBlockFilter()
                    
                    // フォロー中であれば解除
                    if let uuid = UUID(uuidString: targetId) {
                        if followingRemoteOshiIDs.contains(uuid) {
                           toggleFollowRemoteOshi(OshiCharacter(id: uuid, name: "", isPublic: true)) // 簡易的な解除呼び出し
                        }
                    }
                }
                print("✅ Blocked user: \(targetId)")
            } catch {
                print("❌ Block failed: \(error)")
                errorMessage = "ブロックに失敗しました"
            }
        }
    }
    
    /// ブロック状態を適用してリストをフィルタリングするヘルパー
    private func applyBlockFilter() {
        // タイムラインのフィルタリング
        self.posts = self.posts.filter { !isBlocked(post: $0) }
        self.publicTimelinePosts = self.publicTimelinePosts.filter { !isBlocked(post: $0) }
        
        // おすすめ推しのフィルタリング
        self.recommendedOshis = self.recommendedOshis.filter { !isBlocked(oshi: $0) }
    }
    
    private func isBlocked(post: Post) -> Bool {
        if let cid = post.creatorId, blockedUserIDs.contains(cid) { return true }
        if let aid = post.authorId?.uuidString, blockedUserIDs.contains(aid) { return true }
        return false
    }
    
    private func isBlocked(oshi: OshiCharacter) -> Bool {
        if let cid = oshi.creatorId, blockedUserIDs.contains(cid) { return true }
        if blockedUserIDs.contains(oshi.id.uuidString) { return true }
        return false
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
        let result = repostedPostIDs.contains(post.id)
        print("🔍 isReposted(\(post.id.uuidString.prefix(8))...) = \(result), repostedPostIDs.count = \(repostedPostIDs.count)")
        return result
    }

    /// リツイート情報の初期読み込み（.taskなどで呼ぶ）
    func loadUserReposts() async {
        do {
            let ids = try await dbManager.loadUserRepostIDs()
            print("🔄 [Debug] loadUserReposts: 取得したID数 = \(ids.count)")
            print("🔄 [Debug] loadUserReposts: IDs = \(ids)")
            await MainActor.run {
                self.repostedPostIDs = Set(ids)
                print("🔄 [Debug] loadUserReposts: repostedPostIDs更新後 = \(self.repostedPostIDs.count)件")
            }
        } catch {
            print("❌ リツイート情報読み込みエラー: \(error)")
        }
    }

    private func updatePostInAllLists(postId: UUID, update: (inout Post) -> Void) {
        // 1. 自分のタイムライン / フォロー中
        if let idx = posts.firstIndex(where: { $0.id == postId }) {
            update(&posts[idx])
        }
        
        // 2. おすすめ (公開タイムライン) ← これが重要！
        if let idx = publicTimelinePosts.firstIndex(where: { $0.id == postId }) {
            update(&publicTimelinePosts[idx])
        }
        
        // 3. ブックマーク一覧 (表示中であれば)
        if let idx = bookmarkedPosts.firstIndex(where: { $0.id == postId }) {
            update(&bookmarkedPosts[idx])
        }
    }

    /// リツイート切り替え (修正版)
    func toggleRepost(for post: Post) {
        let isCurrentlyReposted = repostedPostIDs.contains(post.id)
        
        // 1. IDリスト更新
        if isCurrentlyReposted {
            repostedPostIDs.remove(post.id)
        } else {
            repostedPostIDs.insert(post.id)
        }
        
        // 2. 全リストの投稿オブジェクトを更新 (カウントの増減)
        updatePostInAllLists(postId: post.id) { post in
            if isCurrentlyReposted {
                post.repostCount = max(0, post.repostCount - 1)
            } else {
                post.repostCount += 1
            }
        }
        
        // 振動フィードバック
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // 3. 非同期でDB更新
        Task {
            do {
                if isCurrentlyReposted {
                    try await dbManager.unrepostPost(postId: post.id)
                } else {
                    try await dbManager.repostPost(postId: post.id)
                }
            } catch {
                print("❌ リツイート処理エラー: \(error)")
            }
        }
    }
    
    /// ユーザーが投稿にいいねする (修正版)
    func toggleUserReaction(on post: Post) {
        Task {
            let isLiking = !likedPostIDs.contains(post.id)
            
            // 1. IDリスト更新
            if isLiking {
                likedPostIDs.insert(post.id)
            } else {
                likedPostIDs.remove(post.id)
            }
            
            // 2. 全リストの投稿オブジェクトを更新 (カウントの増減)
            await MainActor.run {
                updatePostInAllLists(postId: post.id) { post in
                    if isLiking {
                        post.reactionCount += 1
                    } else {
                        post.reactionCount = max(0, post.reactionCount - 1)
                    }
                }
            }

            // 振動フィードバック
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

            do {
                // 3. 詳細データの更新 (DB処理)
                // 自分のID（本来はFirebaseAuth等のID）
                let userId = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()

                if postDetails[post.id] == nil {
                    await loadPostDetails(for: post.id)
                }

                if var details = postDetails[post.id] {
                    if let existingIndex = details.reactions.firstIndex(where: { $0.oshiId == userId }) {
                        // 削除処理
                        let removedReaction = details.reactions.remove(at: existingIndex)
                        postDetails[post.id] = details
                        try await dbManager.deleteReaction(removedReaction, from: post.id)
                    } else {
                        // 追加処理
                        let reaction = Reaction(oshiId: userId, oshiName: "あなた")
                        details.reactions.append(reaction)
                        postDetails[post.id] = details
                        
                        // ✅ 修正箇所: 足りない引数 (postAuthorId, oshiName) を追加
                        // post.authorId が通知先になります
                        let targetAuthorId = post.authorId?.uuidString ?? ""
                        // ユーザーの投稿でなければ、AI名として authorName を渡す
                        let targetOshiName = post.isUserPost ? nil : post.authorName
                        
                        try await dbManager.addReaction(
                            reaction,
                            to: post.id,
                            postAuthorId: targetAuthorId,
                            oshiName: targetOshiName
                        )
                    }
                }
            } catch {
                print("❌ いいね処理エラー: \(error)")
            }
        }
    }
    
    /// ユーザーコメントの追加 (修正版)
    func addUserComment(to post: Post, content: String) {
        let userId = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()
        
        let comment = Comment(
            oshiId: userId,
            oshiName: userProfileName,
            content: content
        )
        
        Task {
            do {
                try await dbManager.addComment(comment, to: post.id)
                
                await MainActor.run {
                    // 詳細データの更新
                    if var details = postDetails[post.id] {
                        details.comments.append(comment)
                        postDetails[post.id] = details
                    } else {
                        postDetails[post.id] = PostDetails(post: post, comments: [comment])
                    }
                    
                    // 全リストのコメント数を更新
                    updatePostInAllLists(postId: post.id) { post in
                        post.commentCount += 1
                    }
                }
                print("✅ コメント投稿成功")
                
                // ✅ 追加: AIの投稿に対するコメントなら、50%の確率で返信する
                if !post.isUserPost, let authorId = post.authorId {
                    // 投稿者の推し情報を検索 (ローカルリストから)
                    if let oshi = self.oshiList.first(where: { $0.id == authorId }) {
                        await attemptAiReplyToComment(post: post, userComment: content, oshi: oshi)
                    }
                }
                
            } catch {
                print("❌ コメント投稿エラー: \(error)")
                await MainActor.run {
                    errorMessage = "コメントの投稿に失敗しました"
                }
            }
        }
    }
    
    private func attemptAiReplyToComment(post: Post, userComment: String, oshi: OshiCharacter) async {
        guard Double.random(in: 0...1) < 0.5 else {
            print("🎲 AI返信スキップ (確率)")
            return
        }
        
        print("🤖 AI返信プロセス開始: \(oshi.name)")
        
        do {
            try await Task.sleep(nanoseconds: UInt64.random(in: 3_000_000_000...8_000_000_000))
            
            let replyText = try await aiService.generateReplyToUserComment(
                comment: userComment,
                on: post,
                by: oshi,
                userName: userProfileName
            )
            
            // ✅ 修正: replyToName にユーザー名を設定
            let replyComment = Comment(
                oshiId: oshi.id,
                oshiName: oshi.name,
                content: replyText,
                replyToName: userProfileName // ← ここで指定
            )
            
            try await dbManager.addComment(replyComment, to: post.id)
            
            await MainActor.run {
                if var details = postDetails[post.id] {
                    details.comments.append(replyComment)
                    postDetails[post.id] = details
                }
                
                updatePostInAllLists(postId: post.id) { post in
                    post.commentCount += 1
                }
                
                if let index = oshiList.firstIndex(where: { $0.id == oshi.id }) {
                    oshiList[index].increaseIntimacy(by: 1)
                    let oshiToSave = oshiList[index]
                    Task { try? await dbManager.saveOshi(oshiToSave) }
                }
            }
            print("✅ AI返信成功: \(replyText)")
            
        } catch {
            print("❌ AI返信エラー: \(error)")
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
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 30...300)) {
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
            content: "",
            senderAvatarURL: oshi.avatarImageURL
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
    
    func fetchOshi(oshiId: UUID) async -> OshiCharacter? {
        // 1. まず自分の推しリストから検索
        if let oshi = oshiList.first(where: { $0.id == oshiId }) { return oshi }
        
        // 2. おすすめリスト（プリセット）から検索
        if let oshi = recommendedOshis.first(where: { $0.id == oshiId }) { return oshi }
        
        // 3. DBからユーザープロフィールとして取得
        do {
            if let oshi = try await dbManager.fetchUserProfile(userId: oshiId.uuidString) {
                // フォロー状態をローカル情報で上書き（リモートフォロー中かどうか）
                var fetchedOshi = oshi
                fetchedOshi.isFollowedByUser = followingRemoteOshiIDs.contains(oshiId)
                return fetchedOshi
            }
            
            // 4. それでもなければプリセットリストを再取得して検索する等の処理も考えられるが、一旦ここまで
        } catch {
            print("❌ fetchOshi error: \(error)")
        }
        
        return nil
    }

    func fetchPost(postId: UUID) async -> Post? {
        // 1. まずメモリ内の既存リストから検索（高速）
        if let post = posts.first(where: { $0.id == postId }) { return post }
        if let post = publicTimelinePosts.first(where: { $0.id == postId }) { return post }
        if let post = bookmarkedPosts.first(where: { $0.id == postId }) { return post }
        
        // 2. なければDBから取得
        do {
            let fetchedPosts = try await dbManager.loadPosts(by: [postId])
            return fetchedPosts.first
        } catch {
            print("❌ fetchPost error: \(error)")
            return nil
        }
    }

    func followRecommended(_ preset: OshiCharacter) async {
        // 既にリストにある場合は、フラグ更新のみ行う（重複追加防止）
        if let index = oshiList.firstIndex(where: { $0.id == preset.id }) {
            // リストにあるがフォロー表示になっていない場合の保険
            if !oshiList[index].isFollowedByUser {
                oshiList[index].isFollowedByUser = true
            }
            return
        }

        var followedOshi = preset
        followedOshi.isFollowingUser = true
        followedOshi.isFollowedByUser = true
        // 必要に応じて作成者IDなども設定
        followedOshi.creatorId = dbManager.currentUserId

        // 1. 【重要】通信を待たず、先にローカルのリストを更新して見た目を即座に変える
        withAnimation {
            oshiList.insert(followedOshi, at: 0)
        }
        
        // 2. バックグラウンドでDB保存などを実行
        do {
            try await dbManager.saveOshi(followedOshi)

            // チャットルームの初期化など
            if !chatRooms.contains(where: { $0.oshiId == preset.id }) {
                let room = ChatRoom(id: UUID(), oshiId: preset.id, messages: [], lastMessageDate: nil, unreadCount: 0)
                try await dbManager.saveChatRoom(room)
                
                // チャットルームリストへの反映も必要であればここで行う
                // (OshiViewModelのchatRoomsプロパティへの追加)
                if !chatRooms.contains(where: { $0.oshiId == preset.id }) {
                     chatRooms.append(room)
                }
            }
            
            // 挨拶メッセージの送信（AI生成または固定文）
            // 注意: userProfileNameなどのプロパティがMainActor内であることを確認
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
            
            // チャットルームの最新メッセージ更新
            if let idx = chatRooms.firstIndex(where: { $0.oshiId == preset.id }) {
                var room = chatRooms[idx]
                room.messages.append(welcome)
                room.lastMessageDate = welcome.timestamp
                room.unreadCount += 1
                chatRooms[idx] = room
            }

            try? await dbManager.followRemoteOshi(oshi: preset)
            
            print("✅ followRecommended success: \(preset.name)")

        } catch {
            print("❌ followRecommended error: \(error)")
            
            // 3. 【ロールバック】保存に失敗した場合は、リストから削除して元の状態に戻す
            withAnimation {
                if let index = oshiList.firstIndex(where: { $0.id == preset.id }) {
                    oshiList.remove(at: index)
                }
            }
            // エラーメッセージをユーザーに通知
            errorMessage = "フォローに失敗しました。通信環境を確認してください。"
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
        print("🔍 [Debug] loadData: 開始")
        isLoading = true
        errorMessage = nil

        do {
            // 1. 各種リストの並列ロード (★ blockedTask を追加)
            async let oshiListTask = dbManager.loadOshiList()
            async let chatRoomsTask = dbManager.loadChatRooms()
            async let userProfileTask = dbManager.loadUserProfile()
            async let followingTask = dbManager.loadFollowingIds()
            async let presetsTask = dbManager.fetchPresetOshis()
            async let blockedTask = dbManager.fetchBlockedUsers() // ✅ 追加
            
            async let myPostsTask = dbManager.loadMyPosts(limit: 50)
            async let publicPostsTask = dbManager.loadPublicPosts(limit: 50)

            // 結果の取り出し (★ loadedBlocked を追加)
            let (loadedOshi, loadedMyPosts, loadedPublicPosts, loadedRooms, profile, loadedFollowingIDs, loadedPresets, loadedBlocked) =
                try await (oshiListTask, myPostsTask, publicPostsTask, chatRoomsTask, userProfileTask, followingTask, presetsTask, blockedTask)

            // 3. データ反映
            oshiList = loadedOshi
            followingRemoteOshiIDs = Set(loadedFollowingIDs)
            chatRooms = loadedRooms
            userProfileName = profile.userName
            userProfileAvatarURL = profile.avatarImageURL
            
            // ✅ ブロックリストの設定
            blockedUserIDs = Set(loadedBlocked)
            
            // ✅ フィルタリングしながら代入
            recommendedOshis = loadedPresets.filter { !self.blockedUserIDs.contains($0.creatorId ?? "") && !self.blockedUserIDs.contains($0.id.uuidString) }
            
            publicTimelinePosts = loadedPublicPosts.filter { !self.isBlocked(post: $0) }

            // 4. フォロー中タイムラインの構築
            let localOshiIds = oshiList.map { $0.id }
            let remoteOshiIds = Array(followingRemoteOshiIDs)
            let allFollowingIds = Set(localOshiIds + remoteOshiIds)
            
            let followingPosts = try await dbManager.loadFollowingPosts(followingIds: Array(allFollowingIds))
            
            let mergedPosts = (loadedMyPosts + followingPosts)
                .reduce(into: [Post]()) { res, post in
                    if !res.contains(where: { $0.id == post.id }) { res.append(post) }
                }
                .sorted { $0.timestamp > $1.timestamp }
            
            // ✅ 自分のタイムラインもフィルタリング
            self.posts = mergedPosts.filter { !self.isBlocked(post: $0) }
            
            Task {
                try? await dbManager.deleteOldNotifications(olderThan: Date().addingTimeInterval(-60*60*24*30))
            }

        } catch {
            print("❌ [Debug] loadData: エラー発生 - \(error)")
            errorMessage = "データの読み込みに失敗しました: \(error.localizedDescription)"
        }
        isLoading = false
        print("🏁 [Debug] loadData: 完了")
    }
    
    func loadFollowingList() async {
        await MainActor.run { isLoadingList = true }
        do {
            let oshis = try await FirebaseDatabaseManager.shared.fetchFollowingOshis()
            await MainActor.run {
                self.followingOshis = oshis
                self.isLoadingList = false
            }
        } catch {
            print("Error loading following list: \(error)")
            await MainActor.run { isLoadingList = false }
        }
    }

    // 修正: 引数を oshiId: UUID から oshi: OshiCharacter に変更
    func toggleFollowRemoteOshi(_ oshi: OshiCharacter) {
        let oshiId = oshi.id
        
        if followingRemoteOshiIDs.contains(oshiId) {
            // フォロー解除処理
            followingRemoteOshiIDs.remove(oshiId)
            Task {
                // 解除はIDだけで可能（FirebaseDatabaseManagerのunfollowは変更していないため）
                try? await dbManager.unfollowRemoteOshi(oshiId: oshiId)
            }
        } else {
            // フォロー処理
            followingRemoteOshiIDs.insert(oshiId)
            Task {
                // ✅ ここでエラーが出ていた箇所
                // オブジェクトごと渡すことで、内部でcreatorIdを参照し通知を送れるようになります
                try? await dbManager.followRemoteOshi(oshi: oshi)
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

    /// ✅ 通知だけを個別に読み込む関数を追加 (修正: 既読状態の維持)
    func fetchNotifications() async {
        print("📲 [Debug] ViewModel: fetchNotifications 開始")
        
        // 1. 【追加】サーバー通信前にローカルキャッシュを読み込む
        // これにより、アプリ起動直後でも「既読状態」をメモリ上に復元し、
        // サーバーからの未読データをマージする際の比較対象として利用できるようにする。
        await MainActor.run {
            if self.notifications.isEmpty {
                if let data = UserDefaults.standard.data(forKey: notificationsStorageKey),
                   let decoded = try? JSONDecoder().decode([AppNotification].self, from: data) {
                    print("📲 [Debug] ViewModel: ローカルキャッシュを先行ロード (\(decoded.count)件)")
                    self.notifications = decoded
                }
            }
        }

        do {
            // Firebaseから通知を取得
            let fetchedNotifications = try await dbManager.loadNotifications(limit: 100)
            
            print("📲 [Debug] ViewModel: 取得成功 - \(fetchedNotifications.count)件")
            
            await MainActor.run {
                // ✅ ローカルの既読状態をマージする
                // 先ほどロードしたキャッシュ(self.notifications)の情報を使って、サーバーデータの未読を上書きする
                
                // 現在のローカル通知の既読状態マップを作成
                let currentReadStatus = Dictionary(
                    self.notifications.map { ($0.id, $0.isRead) },
                    uniquingKeysWith: { (first, _) in first }
                )
                
                self.notifications = fetchedNotifications.map { notification in
                    var newNotification = notification
                    // ローカルですでに既読なら、サーバーが未読でも既読として扱う
                    if let isReadLocally = currentReadStatus[notification.id], isReadLocally {
                        newNotification.isRead = true
                    }
                    return newNotification
                }
                
                // ローカルにも保存（オフライン対応）
                saveNotificationsToLocal()
                print("📲 [Debug] ViewModel: UI更新完了")
            }
        } catch {
            print("❌ [Debug] 通知取得エラー: \(error)")
            // エラー時はローカルから取得（すでに冒頭でロードしているが、念のため再確認）
            await MainActor.run {
                if self.notifications.isEmpty,
                   let data = UserDefaults.standard.data(forKey: notificationsStorageKey) {
                    if let decoded = try? JSONDecoder().decode([AppNotification].self, from: data) {
                        print("📲 [Debug] ViewModel: エラーのためローカルキャッシュを表示 (\(decoded.count)件)")
                        self.notifications = decoded
                        return
                    }
                }
                // キャッシュもなければ空のまま
            }
        }
    }

    private func deleteOldNotifications() async {
        let thirtyDaysAgo = Date().addingTimeInterval(-(60 * 60 * 24 * 30))
        
        await MainActor.run {
            let initialCount = notifications.count
            notifications.removeAll { $0.timestamp < thirtyDaysAgo }
            
            // 変更があれば保存
            if notifications.count != initialCount {
                saveNotificationsToLocal()
            }
        }
    }
    // MARK: - 推し管理
    
    func addOshi(_ oshi: OshiCharacter, isPublic: Bool = false) {
        Task {
            do {
                var newOshi = oshi
                newOshi.isPublic = isPublic
                newOshi.isFollowedByUser = true
                newOshi.isFollowingUser = true
                // 追加: 作成者IDを設定
                newOshi.creatorId = dbManager.currentUserId
                
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
    
    func createUserPost(content: String, imageURLs: [String] = []) {
        let post = Post(
            authorName: "あなた",
            content: content,
            isUserPost: true,
            imageURLs: imageURLs
        )
        
        // UI即時反映
        posts.insert(post, at: 0)
        postDetails[post.id] = PostDetails(post: post, reactions: [], comments: [], hasMoreComments: false)
        
        Task {
            do {
                try await dbManager.savePost(post)
                await generateReactionsForPost(post)
            } catch {
                errorMessage = "保存失敗: \(error.localizedDescription)"
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
                let targetAuthorId = post.authorId?.uuidString ?? dbManager.currentUserId
                let targetOshiName = post.isUserPost ? nil : post.authorName
                
                try? await dbManager.addReaction(
                    reaction,
                    to: post.id,
                    postAuthorId: targetAuthorId,
                    oshiName: targetOshiName
                )
                
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
    
    func createOshiPost(by oshi: OshiCharacter) {
        Task {
            do {
                let content = try await aiService.generateOshiPost(by: oshi)
                
                // 修正: Post作成時にcreatorIdを渡す
                let post = Post(
                    authorId: oshi.id,
                    authorName: oshi.name,
                    content: content,
                    isUserPost: false,
                    authorAvatarURL: oshi.avatarImageURL,
                    creatorId: oshi.creatorId // 👈 ここを追加！
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
        guard !isMessageLimitReached else { return }

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
        
        messageCount += 1
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
        let mutualFollows = oshiList.filter { $0.isMutualFollow }
        
        guard !mutualFollows.isEmpty else { return }

        if let randomOshi = mutualFollows.randomElement() {
            createOshiPost(by: randomOshi)
        }
    }
    
    private func addNotification(_ notification: AppNotification) {
        // ローカルに追加（UI即時反映）
        withAnimation {
            notifications.insert(notification, at: 0)
        }
        
        // 100件制限
        if notifications.count > 100 {
            notifications = Array(notifications.prefix(100))
        }
        
        // 端末(UserDefaults)に保存
        saveNotificationsToLocal()
        
        // ✅ 追加: Firebaseにも保存する
        // これがないと、次に画面を開いた時にデータが消えてしまいます
        Task {
            do {
                try await dbManager.saveNotification(notification)
            } catch {
                print("❌ [Debug] 通知のFirebase保存に失敗: \(error)")
            }
        }
    }
    
    /// UserDefaultsへ保存するヘルパー
    private func saveNotificationsToLocal() {
        if let encoded = try? JSONEncoder().encode(notifications) {
            UserDefaults.standard.set(encoded, forKey: notificationsStorageKey)
        }
    }

    /// 通知を既読にする
    func markNotificationAsRead(_ notificationId: UUID) {
        if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
            notifications[index].isRead = true
            // 保存
            saveNotificationsToLocal()
        }
    }

    /// すべての通知を既読にする (修正: サーバー同期の信頼性向上)
    func markAllNotificationsAsRead() {
        var hasChange = false

        for index in notifications.indices {
            if !notifications[index].isRead {
                notifications[index].isRead = true
                hasChange = true
            }
        }
        
        // ローカルに変更があれば保存
        if hasChange {
            saveNotificationsToLocal()
        }
        
        // ✅ 変更の有無に関わらず、念のためサーバー側も既読にするリクエストを送る
        // （前回アプリ終了時などに同期失敗していた場合、ここですべて既読にする）
        Task {
            do {
                try await dbManager.markAllNotificationsAsRead()
                print("✅ 全ての通知を既読にしました (Server synced)")
            } catch {
                print("❌ 既読更新エラー: \(error)")
            }
        }
    }

    /// すべての通知を削除
    func clearAllNotifications() {
        notifications.removeAll()
        saveNotificationsToLocal()
        // Firebase削除コードは削除
    }

    // MARK: - 通知生成メソッドの修正

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

    /// 推しの投稿通知を作成 -> 廃止
    private func createOshiPostNotification(oshi: OshiCharacter, post: Post) {
        // 何もしない (通知を作成しない)
    }

    /// チャットメッセージ通知を作成 -> 廃止
    private func createChatNotification(oshi: OshiCharacter, message: Message) {
        // 何もしない (通知を作成しない)
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

import Foundation

enum AppConfig {
    /// 審査通過まで false（無制限送信）
    static let adGateEnabled = false
}

// ViewModels/OshiViewModel.swift (修正版)

import Foundation
import Combine

@MainActor
class OshiViewModel: ObservableObject {
    @Published var oshiList: [OshiCharacter] = []
    @Published var posts: [Post] = []
    @Published var chatRooms: [ChatRoom] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var recommendedOshis: [OshiCharacter] = []
    
    // ✅ 投稿の詳細情報（必要な時だけ取得）
    @Published var postDetails: [UUID: PostDetails] = [:]
    
    private let aiService = AIService.shared
    private let dbManager = FirebaseDatabaseManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var autoPostTimer: Timer?
    
    init() {
        Task {
            await loadData()
        }
        startAutoPosting()
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
        
        room1.addMessage(Message(content: "おはよ！今日もえらい！", isFromUser: false, oshiId: oshi1.id))
        room1.addMessage(Message(content: "ありがとう！", isFromUser: true))
        
        room2.addMessage(Message(content: "今日なにしてた？", isFromUser: false, oshiId: oshi2.id))
        
        self.chatRooms = [room1, room2]
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

            // 1) 推しを保存 & リスト反映
            try await dbManager.saveOshi(preset)
            oshiList.insert(preset, at: 0)

            // 2) チャットルームが無ければ作る（空メッセージでOK）
            if !chatRooms.contains(where: { $0.oshiId == preset.id }) {
                let room = ChatRoom(id: UUID(), oshiId: preset.id, messages: [], lastMessageDate: nil, unreadCount: 0)
                try await dbManager.saveChatRoom(room)
                chatRooms.append(room)
            }

            // 3) 推しから「最初の1通」を送る（保存されるのでチャットに出る）
            let welcome = Message(
                id: UUID(),
                content: "フォローありがとう、\(preset.userCallingName.isEmpty ? "ねえ" : preset.userCallingName)！これからたくさん話そう☺️",
                isFromUser: false,
                oshiId: preset.id,
                timestamp: Date(),
                isRead: false
            )

            try await dbManager.addMessage(to: preset.id, message: welcome)

            // 4) ローカルの chatRooms も即時反映（一覧にすぐ出すため）
            if let idx = chatRooms.firstIndex(where: { $0.oshiId == preset.id }) {
                var room = chatRooms[idx]
                room.messages.append(welcome)
                room.lastMessageDate = welcome.timestamp
                room.unreadCount += 1
                chatRooms[idx] = room
            }

        } catch {
            self.errorMessage = error.localizedDescription
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

    
    // MARK: - Data Loading
    
    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            async let oshiListTask = dbManager.loadOshiList()
            async let postsTask = dbManager.loadPosts(limit: 50)
            async let chatRoomsTask = dbManager.loadChatRooms()
            async let presetsTask = dbManager.fetchPresetOshis()   // ✅ 追加（おすすめも並列で取る）

            let (loadedOshi, loadedPosts, loadedRooms, presets) =
                try await (oshiListTask, postsTask, chatRoomsTask, presetsTask)  // ✅ 変更

            oshiList = loadedOshi
            recommendedOshis = presets    // ✅ ここだけにする（2重ロード削除）
            posts = loadedPosts
            chatRooms = loadedRooms

            print("✅ データ読み込み成功: 推し\(oshiList.count)人, 投稿\(posts.count)件")
        } catch {
            errorMessage = "データの読み込みに失敗しました: \(error.localizedDescription)"
            print("❌ データ読み込みエラー: \(error)")
        }

        isLoading = false
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
    
    // MARK: - タイムライン（最適化版）
    
    func createUserPost(content: String) {
        let post = Post(authorName: "あなた", content: content, isUserPost: true)
        posts.insert(post, at: 0)
        
        // ✅ 空のPostDetailsを作成（即座に表示できるように）
        postDetails[post.id] = PostDetails(post: post, reactions: [], comments: [], hasMoreComments: false)
        
        Task {
            do {
                try await dbManager.savePost(post)
                
                // すべての推しが反応（遅延実行）
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
        
        // ✅ コメントする人数をランダムに決定（2〜3人、推しが少ない場合は全員）
        let commentersCount = min(Int.random(in: 2...3), oshiList.count)
        
        // ✅ 親密度ベースの重み付き抽選
        let selectedCommenters = selectCommentersWithIntimacy(count: commentersCount)
        
        for oshi in oshiList {
            // ✅ いいね（全員が60〜90%の確率で反応）
            if Double.random(in: 0...1) < Double.random(in: 0.6...0.9) {
                let reaction = Reaction(oshiId: oshi.id, oshiName: oshi.name)
                
                do {
                    try await dbManager.addReaction(reaction, to: post.id)
                    
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
            
            // ✅ コメント（選ばれた推しのみ）
            if selectedCommenters.contains(where: { $0.id == oshi.id }) {
                do {
                    // ランダムな遅延（1〜5秒）
                    try await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...5_000_000_000))
                    
                    let commentText = try await aiService.generateComment(for: post, by: oshi, userMood: mood)
                    let comment = Comment(oshiId: oshi.id, oshiName: oshi.name, content: commentText)
                    
                    try await dbManager.addComment(comment, to: post.id)
                    
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

    // ✅ 親密度ベースの重み付き抽選システム
    private func selectCommentersWithIntimacy(count: Int) -> [OshiCharacter] {
        guard !oshiList.isEmpty else { return [] }
        
        // 親密度をベースにした重み計算
        let weighedOshis: [(oshi: OshiCharacter, weight: Double)] = oshiList.map { oshi in
            // 基本重み: 親密度による重み（1〜10）
            let intimacyWeight = max(1.0, Double(oshi.totalInteractions) / 10.0)
            
            // ランダム要素: 0.5〜1.5倍のランダムブースト（決まった人だけにならないように）
            let randomBoost = Double.random(in: 0.5...1.5)
            
            // 最終重み
            let finalWeight = intimacyWeight * randomBoost
            
            return (oshi, finalWeight)
        }
        
        // 重みが高い順にソート
        let sortedOshis = weighedOshis.sorted { $0.weight > $1.weight }
        
        // 上位から選択（ただし完全に上位だけでなく、若干のランダム性を持たせる）
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
                let post = Post(authorId: oshi.id, authorName: oshi.name,
                               content: content, isUserPost: false)
                posts.insert(post, at: 0)
                
                try await dbManager.savePost(post)
                
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
    
    // MARK: - 投稿詳細の取得
    
    /// 投稿の詳細（リアクション・コメント）を取得
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

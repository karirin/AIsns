import Foundation
import Combine

class OshiViewModel: ObservableObject {
    @Published var oshiList: [OshiCharacter] = []
    @Published var posts: [Post] = []
    @Published var chatRooms: [ChatRoom] = []
    
    private let aiService = AIService.shared
    private var cancellables = Set<AnyCancellable>()
    private var autoPostTimer: Timer?
    
    init() {
        loadData()
        startAutoPosting()
    }
    
    // 追加：OshiViewModel の中に追記

    convenience init(mock: Bool) {
        self.init(skipLoadAndTimers: true)
        guard mock else { return }

        var oshi1 = OshiCharacter(
            name: "レン",
            personality: .cool,
            speechStyle: .casual,
            relationshipDistance: .lover,
            worldSetting: .fantasy,
            avatarColor: "#4F46E5"
        )
        oshi1.intimacyLevel = 12

        var oshi2 = OshiCharacter(
            name: "ユイ",
            personality: .cool,
            speechStyle: .polite,
            relationshipDistance: .bestFriend,
            worldSetting: .fantasy,
            avatarColor: "#EC4899"
        )
        oshi2.intimacyLevel = 7

        self.oshiList = [oshi1, oshi2]

        // チャットルーム（各推しに紐づく）
        var room1 = ChatRoom(oshiId: oshi1.id)
        var room2 = ChatRoom(oshiId: oshi2.id)

        // メッセージ（room.messages.last が表示に効く）
        room1.addMessage(Message(content: "おはよ！今日もえらい！", isFromUser: false, oshiId: oshi1.id))
        room1.addMessage(Message(content: "ありがとう！", isFromUser: true))

        room2.addMessage(Message(content: "今日なにしてた？", isFromUser: false, oshiId: oshi2.id))

        // 未読バッジ確認用
        // （ChatRoom に unreadCount を直接触れるならここで設定、無理なら addMessage の実装側で増える想定）
        // room1.unreadCount = 2

        self.chatRooms = [room1, room2]

        // 並び替え用に lastMessageDate を更新する実装ならここは不要（addMessageで更新されるならOK）
    }

    // 追加：OshiViewModel の中に追記

    private convenience init(skipLoadAndTimers: Bool) {
        self.init()
        if skipLoadAndTimers {
            autoPostTimer?.invalidate()
            autoPostTimer = nil
            cancellables.removeAll()

            // init() 内で loadData/startAutoPosting が走るので、ここで上書きして実質無効化
            self.oshiList = []
            self.posts = []
            self.chatRooms = []
        }
    }

    
    // MARK: - 推し管理
    
    func addOshi(_ oshi: OshiCharacter) {
        var newOshi = oshi
        newOshi.intimacyLevel = 0
        oshiList.append(newOshi)
        
        // チャットルーム作成
        let chatRoom = ChatRoom(oshiId: newOshi.id)
        chatRooms.append(chatRoom)
        
        saveData()
        
        // 初回メッセージ
        sendInitialGreeting(to: newOshi)
    }
    
    func updateOshi(_ oshi: OshiCharacter) {
        if let index = oshiList.firstIndex(where: { $0.id == oshi.id }) {
            oshiList[index] = oshi
            saveData()
        }
    }
    
    func deleteOshi(_ oshi: OshiCharacter) {
        oshiList.removeAll { $0.id == oshi.id }
        chatRooms.removeAll { $0.oshiId == oshi.id }
        posts.removeAll { $0.authorId == oshi.id }
        saveData()
    }
    
    // MARK: - タイムライン
    
    func createUserPost(content: String) {
        let post = Post(authorName: "あなた", content: content, isUserPost: true)
        posts.insert(post, at: 0)
        
        // すべての推しが反応
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1...3)) {
            self.generateReactionsForPost(post)
        }
        
        saveData()
    }
    
    private func generateReactionsForPost(_ post: Post) {
        guard let postIndex = posts.firstIndex(where: { $0.id == post.id }) else { return }
        
        let mood = aiService.analyzeMood(from: post.content)
        
        for oshi in oshiList {
            // いいね
            let reaction = Reaction(oshiId: oshi.id, oshiName: oshi.name)
            posts[postIndex].reactions.append(reaction)
            
            // コメント（ランダムに80%の確率）
            if Double.random(in: 0...1) < 0.8 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2...5)) {
                    let commentText = self.aiService.generateComment(for: post, by: oshi, userMood: mood)
                    let comment = Comment(oshiId: oshi.id, oshiName: oshi.name, content: commentText)
                    
                    if let idx = self.posts.firstIndex(where: { $0.id == post.id }) {
                        self.posts[idx].comments.append(comment)
                        
                        // 親密度アップ
                        if let oshiIdx = self.oshiList.firstIndex(where: { $0.id == oshi.id }) {
                            self.oshiList[oshiIdx].increaseIntimacy(by: 2)
                        }
                    }
                    self.saveData()
                }
            }
        }
        
        saveData()
    }
    
    func createOshiPost(by oshi: OshiCharacter) {
        let content = aiService.generateOshiPost(by: oshi)
        let post = Post(authorId: oshi.id, authorName: oshi.name, 
                       content: content, isUserPost: false)
        posts.insert(post, at: 0)
        saveData()
    }
    
    func reactToOshiPost(_ post: Post) {
        guard let postIndex = posts.firstIndex(where: { $0.id == post.id }),
              let oshiId = post.authorId,
              let oshiIndex = oshiList.firstIndex(where: { $0.id == oshiId }) else { return }
        
        // 親密度アップ
        oshiList[oshiIndex].increaseIntimacy(by: 1)
        saveData()
    }
    
    // MARK: - チャット
    
    func sendMessage(to oshiId: UUID, content: String) {
        guard let roomIndex = chatRooms.firstIndex(where: { $0.oshiId == oshiId }),
              let oshi = oshiList.first(where: { $0.id == oshiId }) else { return }
        
        // ユーザーメッセージ
        let userMessage = Message(content: content, isFromUser: true)
        chatRooms[roomIndex].addMessage(userMessage)
        
        // 親密度アップ
        if let oshiIndex = oshiList.firstIndex(where: { $0.id == oshiId }) {
            oshiList[oshiIndex].increaseIntimacy(by: 3)
        }
        
        saveData()
        
        // AI返信（1-3秒後）
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1...3)) {
            let reply = self.aiService.generateChatReply(
                for: content, 
                by: oshi, 
                conversationHistory: self.chatRooms[roomIndex].messages
            )
            
            let aiMessage = Message(content: reply, isFromUser: false, oshiId: oshiId)
            self.chatRooms[roomIndex].addMessage(aiMessage)
            self.saveData()
        }
    }
    
    func markChatAsRead(oshiId: UUID) {
        if let roomIndex = chatRooms.firstIndex(where: { $0.oshiId == oshiId }) {
            chatRooms[roomIndex].markAllAsRead()
            saveData()
        }
    }
    
    private func sendInitialGreeting(to oshi: OshiCharacter) {
        guard let roomIndex = chatRooms.firstIndex(where: { $0.oshiId == oshi.id }) else { return }
        
        var greeting = ""
        switch oshi.relationshipDistance {
        case .lover:
            greeting = "よろしくね！これから一緒に過ごせるの楽しみ"
        case .bestFriend:
            greeting = "よろしく！仲良くしようね"
        case .fanAndIdol:
            greeting = "応援ありがとう！これからもよろしくね"
        }
        
        greeting = aiService.generateChatReply(for: greeting, by: oshi, conversationHistory: [])
        
        let message = Message(content: greeting, isFromUser: false, oshiId: oshi.id)
        chatRooms[roomIndex].addMessage(message)
        saveData()
    }
    
    // MARK: - 自動投稿
    
    private func startAutoPosting() {
        // 30分ごとに推しがランダムに投稿
        autoPostTimer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            self?.randomOshiPost()
        }
    }
    
    private func randomOshiPost() {
        guard !oshiList.isEmpty else { return }
        
        // ランダムに1人選んで投稿
        if let randomOshi = oshiList.randomElement() {
            createOshiPost(by: randomOshi)
        }
    }
    
    // MARK: - 高親密度での自発的メッセージ
    
    func checkProactiveMessages() {
        let hour = Calendar.current.component(.hour, from: Date())
        
        for oshi in oshiList where oshi.intimacyLevel >= 70 {
            guard let roomIndex = chatRooms.firstIndex(where: { $0.oshiId == oshi.id }) else { continue }
            
            // 朝（7-9時）おはようメッセージ
            if hour >= 7 && hour < 9 {
                let lastMessage = chatRooms[roomIndex].messages.last
                let isToday = Calendar.current.isDateInToday(lastMessage?.timestamp ?? Date.distantPast)
                
                if !isToday {
                    let greeting = aiService.generateGreeting(type: .morning, by: oshi)
                    let message = Message(content: greeting, isFromUser: false, oshiId: oshi.id)
                    chatRooms[roomIndex].addMessage(message)
                }
            }
            
            // 夜（22-23時）おやすみメッセージ
            if hour >= 22 && hour < 23 {
                let nightMessage = aiService.generateGreeting(type: .night, by: oshi)
                let message = Message(content: nightMessage, isFromUser: false, oshiId: oshi.id)
                chatRooms[roomIndex].addMessage(message)
            }
        }
        
        saveData()
    }
    
    // MARK: - データ永続化
    
    private func saveData() {
        if let encoded = try? JSONEncoder().encode(oshiList) {
            UserDefaults.standard.set(encoded, forKey: "oshiList")
        }
        if let encoded = try? JSONEncoder().encode(posts) {
            UserDefaults.standard.set(encoded, forKey: "posts")
        }
        if let encoded = try? JSONEncoder().encode(chatRooms) {
            UserDefaults.standard.set(encoded, forKey: "chatRooms")
        }
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: "oshiList"),
           let decoded = try? JSONDecoder().decode([OshiCharacter].self, from: data) {
            oshiList = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "posts"),
           let decoded = try? JSONDecoder().decode([Post].self, from: data) {
            posts = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "chatRooms"),
           let decoded = try? JSONDecoder().decode([ChatRoom].self, from: data) {
            chatRooms = decoded
        }
    }
}

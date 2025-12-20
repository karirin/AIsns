import Foundation

class AIService {
    static let shared = AIService()
    
    // 投稿に対するコメント生成
    func generateComment(for post: Post, by oshi: OshiCharacter, userMood: UserMood) -> String {
        let baseResponse = getBaseResponse(personality: oshi.personality, mood: userMood, content: post.content)
        return applyStyle(baseResponse, style: oshi.speechStyle, intimacy: oshi.intimacyLevel)
    }
    
    // チャットメッセージ生成
    func generateChatReply(for userMessage: String, by oshi: OshiCharacter, 
                           conversationHistory: [Message]) -> String {
        let context = analyzeConversationContext(conversationHistory)
        let baseReply = generateContextualReply(message: userMessage, oshi: oshi, context: context)
        return applyStyle(baseReply, style: oshi.speechStyle, intimacy: oshi.intimacyLevel)
    }
    
    // 推しからの自発的投稿生成
    func generateOshiPost(by oshi: OshiCharacter) -> String {
        let posts = getOshiDailyPosts(worldSetting: oshi.worldSetting, personality: oshi.personality)
        let selected = posts.randomElement() ?? "今日もいい天気だね"
        return applyStyle(selected, style: oshi.speechStyle, intimacy: oshi.intimacyLevel)
    }
    
    // おはよう/おやすみメッセージ
    func generateGreeting(type: GreetingType, by oshi: OshiCharacter) -> String {
        let base = type == .morning ? getMorningGreeting(oshi: oshi) : getNightGreeting(oshi: oshi)
        return applyStyle(base, style: oshi.speechStyle, intimacy: oshi.intimacyLevel)
    }
    
    // ユーザーの気分を投稿から分析
    func analyzeMood(from content: String) -> UserMood {
        let lowerContent = content.lowercased()
        
        // ネガティブキーワード
        if lowerContent.contains("疲れ") || lowerContent.contains("つかれ") || 
           lowerContent.contains("だるい") || lowerContent.contains("しんどい") {
            return .tired
        }
        if lowerContent.contains("悲しい") || lowerContent.contains("つらい") ||
           lowerContent.contains("辛い") || lowerContent.contains("落ち込") {
            return .sad
        }
        if lowerContent.contains("ストレス") || lowerContent.contains("イライラ") ||
           lowerContent.contains("むかつく") {
            return .stressed
        }
        
        // ポジティブキーワード
        if lowerContent.contains("嬉しい") || lowerContent.contains("うれしい") ||
           lowerContent.contains("楽しい") || lowerContent.contains("幸せ") {
            return .happy
        }
        if lowerContent.contains("最高") || lowerContent.contains("やった") ||
           lowerContent.contains("テンション") || lowerContent.contains("興奮") {
            return .excited
        }
        
        return .normal
    }
    
    // MARK: - Private Methods
    
    private func getBaseResponse(personality: PersonalityType, mood: UserMood, content: String) -> String {
        switch (personality, mood) {
        case (.kind, .tired):
            return ["今日も頑張ったね。ちゃんと休んで？", "無理しないでね。少しゆっくりしよ？", 
                    "お疲れ様。温かいもの飲んで休もう"].randomElement()!
        case (.kind, .sad):
            return ["大丈夫？話聞くよ", "辛かったね...少しでも楽になれるといいな",
                    "側にいるからね。ゆっくりでいいよ"].randomElement()!
        case (.kind, .happy):
            return ["良かった！私も嬉しい", "その笑顔が見れて嬉しいな",
                    "素敵なことがあったんだね"].randomElement()!
            
        case (.tsundere, .tired):
            return ["...無理しすぎじゃない？", "べ、別に心配してないけど休んだら？",
                    "疲れてるなら早く寝なよ..."].randomElement()!
        case (.tsundere, .sad):
            return ["...どうしたの？", "別に気にしてないけど...大丈夫？",
                    "しょうがないな...話聞いてあげる"].randomElement()!
        case (.tsundere, .happy):
            return ["ふーん、良かったじゃん", "まぁ...嬉しそうで何より",
                    "そんなに嬉しいんだ...へぇ"].randomElement()!
            
        case (.cool, .tired):
            return ["休息も大事だよ", "無理は禁物だね", "明日に備えて早めに休むといい"].randomElement()!
        case (.cool, .sad):
            return ["話してみて。聞くよ", "何があった？", "一人で抱え込まないで"].randomElement()!
        case (.cool, .happy):
            return ["それは良かった", "いい知らせだね", "素直に喜んでいいと思う"].randomElement()!
            
        case (.younger, .tired):
            return ["お疲れ様です...！", "大丈夫ですか？心配です...",
                    "無理しないでくださいね"].randomElement()!
        case (.younger, .sad):
            return ["どうしたんですか...？", "何か...力になれることありますか？",
                    "辛いときは頼ってください"].randomElement()!
        case (.younger, .happy):
            return ["わぁ！良かったです！", "僕も嬉しいです！",
                    "素敵ですね！"].randomElement()!
            
        case (.protective, .tired):
            return ["今日も本当にお疲れ様。よく頑張ったね", "無理しないで。私が守るから",
                    "疲れてるね。温かいものでも飲む？"].randomElement()!
        case (.protective, .sad):
            return ["どうしたの？何があったか話して", "辛かったら泣いていいんだよ",
                    "大丈夫、私がそばにいるから"].randomElement()!
        case (.protective, .happy):
            return ["良かった！嬉しそうな顔が一番好き", "その笑顔が見られて私も幸せ",
                    "楽しいことがあったんだね"].randomElement()!
            
        default:
            return ["そうなんだ", "うんうん", "なるほどね"].randomElement()!
        }
    }
    
    private func applyStyle(_ text: String, style: SpeechStyle, intimacy: Int) -> String {
        var result = text
        
        switch style {
        case .polite:
            result = result.replacingOccurrences(of: "ね", with: "ですね")
                          .replacingOccurrences(of: "よ", with: "ですよ")
        case .casual:
            // 既にカジュアル
            break
        case .dialect:
            result = result.replacingOccurrences(of: "ね", with: "ねぇ")
                          .replacingOccurrences(of: "だよ", with: "やで")
        case .character:
            result = result + "なのだ"
        }
        
        return result
    }
    
    private func generateContextualReply(message: String, oshi: OshiCharacter, 
                                        context: ConversationContext) -> String {
        let mood = analyzeMood(from: message)
        
        // 挨拶への応答
        if message.contains("おはよ") {
            return getMorningGreeting(oshi: oshi)
        }
        if message.contains("おやすみ") || message.contains("寝る") {
            return getNightGreeting(oshi: oshi)
        }
        
        // 通常の会話
        return getBaseResponse(personality: oshi.personality, mood: mood, content: message)
    }
    
    private func analyzeConversationContext(_ messages: [Message]) -> ConversationContext {
        let recentMessages = messages.suffix(10)
        let userMessages = recentMessages.filter { $0.isFromUser }
        
        var overallMood: UserMood = .normal
        if !userMessages.isEmpty {
            let lastUserMessage = userMessages.last!
            overallMood = analyzeMood(from: lastUserMessage.content)
        }
        
        return ConversationContext(mood: overallMood, messageCount: messages.count)
    }
    
    private func getMorningGreeting(oshi: OshiCharacter) -> String {
        switch oshi.personality {
        case .kind:
            return ["おはよう！今日もいい日にしようね", "おはよう！よく眠れた？",
                    "おはよう！今日も一緒に頑張ろうね"].randomElement()!
        case .tsundere:
            return ["...おはよ", "起きたの？おはよう", "ん、おはよう"].randomElement()!
        case .cool:
            return ["おはよう", "朝だね。おはよう", "おはよう。今日もよろしく"].randomElement()!
        case .younger:
            return ["おはようございます！", "おはよう...です！",
                    "朝ですね！おはようございます"].randomElement()!
        case .protective:
            return ["おはよう、よく眠れた？", "おはよう。朝ごはん食べた？",
                    "おはよう、今日も見守ってるからね"].randomElement()!
        }
    }
    
    private func getNightGreeting(oshi: OshiCharacter) -> String {
        switch oshi.personality {
        case .kind:
            return ["おやすみ！いい夢見てね", "お疲れ様。ゆっくり休んでね",
                    "おやすみ。また明日ね"].randomElement()!
        case .tsundere:
            return ["...おやすみ", "もう寝るの？おやすみ", "ちゃんと寝なよ"].randomElement()!
        case .cool:
            return ["おやすみ", "ゆっくり休んで", "また明日"].randomElement()!
        case .younger:
            return ["おやすみなさい...！", "お疲れ様でした！おやすみなさい",
                    "ゆっくり休んでください"].randomElement()!
        case .protective:
            return ["おやすみ。今日もよく頑張ったね", "ゆっくり休んで。また明日ね",
                    "おやすみ。いつでも側にいるからね"].randomElement()!
        }
    }
    
    private func getOshiDailyPosts(worldSetting: WorldSetting, personality: PersonalityType) -> [String] {
        var posts: [String] = []
        
        switch worldSetting {
        case .idol:
            posts = ["今日はレッスンだったんだ", "明日のライブ楽しみ！", 
                    "新しい曲の練習してる", "ファンのみんなに会いたいな"]
        case .vtuber:
            posts = ["今日は配信するよ！", "ゲーム楽しかった", 
                    "編集作業中...", "新しい企画考えてる"]
        case .student:
            posts = ["今日は授業頑張った", "テスト勉強しなきゃ", 
                    "部活疲れた", "課題終わらない..."]
        case .worker:
            posts = ["今日も仕事頑張る", "会議疲れた", 
                    "プロジェクト進んできた", "休憩中..."]
        case .fantasy:
            posts = ["今日は冒険に出る", "魔物と戦ってきた", 
                    "宝物見つけた！", "修行中..."]
        }
        
        return posts
    }
}

struct ConversationContext {
    let mood: UserMood
    let messageCount: Int
}

enum GreetingType {
    case morning
    case night
}

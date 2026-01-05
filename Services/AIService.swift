// Services/AIService.swift

import Foundation

class AIService {
    static let shared = AIService()
    private let openAI = OpenAIService.shared
    
    // デフォルト設定
    private let defaultPersonality = "明るく親しみやすい性格。ユーザーの良き友人として振る舞う。少しユーモアがある。"
    private let defaultSpeechStyle = "親しい友人に話しかけるような口調。堅苦しい敬語は使わず、タメ口で話す。絵文字を適度に使用して感情豊かに表現する。"
    
    // MARK: - Format Helpers
    
    /// 性格と口調の設定を取得（空の場合はデフォルト値を適用）
    private func getEffectiveSettings(for oshi: OshiCharacter) -> (personality: String, speech: String) {
        let personality = oshi.personalityText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? defaultPersonality
            : oshi.personalityText
            
        let speech = oshi.speechStyleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? defaultSpeechStyle
            : oshi.speechStyleText
            
        return (personality, speech)
    }
    
    /// 会話履歴をAIが理解しやすい文字列形式に変換する
    private func formatHistory(_ history: [Message]) -> String {
        let recentMessages = history.suffix(10)
        return recentMessages.map { message in
            let sender = message.isFromUser ? "ユーザー" : "キャラクター"
            return "\(sender): \(message.content)"
        }.joined(separator: "\n")
    }

    // MARK: - Comment Generation

    // 投稿に対するコメント生成 (UserMood Enum版 - 修正済み)
    func generateComment(for post: Post, by oshi: OshiCharacter, userMood: UserMood) async throws -> String {
        let moodString: String
        switch userMood {
        case .happy:    moodString = "喜んでいる"
        case .tired:    moodString = "疲れている"
        case .sad:      moodString = "落ち込んでいる"
        case .excited:  moodString = "テンションが高い"
        case .normal:   moodString = "普通"
        case .stressed: moodString = "イライラしている"
        }
        return try await generateComment(for: post, by: oshi, userMood: moodString, userName: "あなた")
    }
    
    // 投稿に対するコメント生成 (String版)
    func generateComment(for post: Post, by oshi: OshiCharacter, userMood: String, userName: String) async throws -> String {
        let settings = getEffectiveSettings(for: oshi)
        let callingName = oshi.callingName(userName: userName)
        
        let prompt = """
        あなたは「\(oshi.name)」として、ユーザー（\(callingName)）の投稿にコメントしてください。
        
        【キャラクター設定】
        性格: \(settings.personality)
        口調: \(settings.speech)
        ユーザーの呼び方: \(callingName)
        
        【ユーザーの投稿】
        "\(post.content)"
        
        【ユーザーの感情分析】
        \(userMood)
        
        ユーザーの感情に寄り添い、キャラクター設定（特に口調）を厳守して、30文字以内の短いコメントを返してください。
        "私はAIです"などの自己言及は禁止です。
        """
        
        return try await generateResponse(prompt: prompt, errorType: { AIServiceError.commentGenerationFailed($0) })
    }
    
    // MARK: - Reply Generation (New Feature)
    
    // ✅ 追加: ユーザーのコメントに対する返信生成
    func generateReplyToUserComment(comment: String, on post: Post, by oshi: OshiCharacter, userName: String) async throws -> String {
        let settings = getEffectiveSettings(for: oshi)
        let callingName = oshi.callingName(userName: userName)
        
        let prompt = """
        あなたは「\(oshi.name)」です。あなたがSNSに投稿した内容に対して、ユーザー（\(callingName)）からコメントが届きました。
        そのコメントに対して、会話が弾むような返信をしてください。
        
        【キャラクター設定】
        性格: \(settings.personality)
        口調: \(settings.speech)
        ユーザーの呼び方: \(callingName)
        
        【あなたの元の投稿】
        "\(post.content)"
        
        【ユーザーからのコメント】
        "\(comment)"
        
        上記のコメントに対する自然な返信を、40文字以内で作成してください。
        キャラクター設定（特に口調）を厳守してください。
        """
        
        return try await generateResponse(prompt: prompt, errorType: { AIServiceError.commentGenerationFailed($0) })
    }

    // MARK: - Chat Generation

    // チャットメッセージ生成
    func generateChatReply(for message: String, by oshi: OshiCharacter, conversationHistory: [Message], userName: String) async throws -> String {
        let settings = getEffectiveSettings(for: oshi)
        let callingName = oshi.callingName(userName: userName)
        
        let prompt = """
        あなたは「\(oshi.name)」というキャラクターになりきって、ユーザー（\(callingName)）と会話してください。
        
        【キャラクター設定】
        名前: \(oshi.name)
        性格: \(settings.personality)
        口調: \(settings.speech)
        話し方の特徴: \(oshi.speechCharacteristics.isEmpty ? "特になし" : oshi.speechCharacteristics)
        一人称: 私（またはキャラ設定に合わせる）
        ユーザーの呼び方: \(callingName)
        
        【会話の履歴】
        \(formatHistory(conversationHistory))
        
        【ユーザーの最新メッセージ】
        \(message)
        
        上記のキャラクター設定を厳守し、短めの文章（1〜3文程度）で親しみを込めて返信してください。
        AIアシスタントとしての振る舞いや、"お手伝いしましょうか？"といった定型句は禁止です。
        """
        
        return try await generateResponse(prompt: prompt, errorType: { AIServiceError.chatReplyFailed($0) })
    }
    
    // MARK: - Greeting Generation
    
    // 挨拶生成
    func generateGreeting(type: GreetingType, by oshi: OshiCharacter, userName: String = "") async throws -> String {
        let settings = getEffectiveSettings(for: oshi)
        let callingName = oshi.callingName(userName: userName)
        
        var context = ""
        switch type {
        case .morning:
            context = "朝の挨拶。爽やかに、あるいは眠そうに。"
        case .night:
            context = "夜の挨拶。一日の労い、またはおやすみ。"
        case .mutualFollow:
            context = "相互フォローになった時の最初の喜びの挨拶。これから仲良くしたい気持ち。"
        }
        
        let prompt = """
        あなたは「\(oshi.name)」です。ユーザー（\(callingName)）に対して挨拶をしてください。
        
        【設定】
        性格: \(settings.personality)
        口調: \(settings.speech)
        ユーザーの呼び方: \(callingName)
        シチュエーション: \(context)
        
        短く（一言〜二言）、キャラクター設定を反映して話しかけてください。
        事務的な挨拶は避け、親近感を持たせてください。
        """
        
        return try await generateResponse(prompt: prompt, errorType: { AIServiceError.greetingFailed($0) })
    }
    
    // 初回挨拶生成
    func generateInitialGreeting(for oshi: OshiCharacter, userName: String) async throws -> String {
        let settings = getEffectiveSettings(for: oshi)
        let callingName = oshi.callingName(userName: userName)
        
        let prompt = """
        あなたは「\(oshi.name)」です。新しく友達になったユーザー（\(callingName)）に最初の挨拶をしてください。
        
        【設定】
        性格: \(settings.personality)
        口調: \(settings.speech)
        ユーザーの呼び方: \(callingName)
        
        自己紹介を含めて、これからの関係を楽しみにしている感じで短く話しかけてください。
        堅苦しい挨拶（"はじめまして、私は..."など）は避け、設定された口調で自然に話してください。
        """
        
        return try await generateResponse(prompt: prompt, errorType: { AIServiceError.greetingFailed($0) })
    }
    
    // MARK: - Other AI Features

    // 推しからの自発的投稿生成
    func generateOshiPost(by oshi: OshiCharacter) async throws -> String {
        let settings = getEffectiveSettings(for: oshi)
        
        let prompt = """
        あなたは「\(oshi.name)」です。SNSに投稿するつぶやきを作成してください。
        
        【設定】
        性格: \(settings.personality)
        口調: \(settings.speech)
        
        【指示】
        ・日常の出来事、ふと思ったこと、あるいはフォロワーへの呼びかけなどを自由に発想してください。
        ・140文字以内で、キャラクター設定（特に口調）を厳守してください。
        ・ハッシュタグは使用しないでください。
        ・"私はAIです"などのメタ発言は禁止です。
        """
        
        return try await generateResponse(prompt: prompt, errorType: { AIServiceError.postGenerationFailed($0) })
    }
    
    // ユーザーの気分を投稿から分析
    func analyzeMood(from content: String) -> String {
        let lowerContent = content.lowercased()
        
        if lowerContent.contains("疲れ") || lowerContent.contains("つかれ") ||
           lowerContent.contains("だるい") || lowerContent.contains("しんどい") {
            return "疲れている"
        }
        if lowerContent.contains("悲しい") || lowerContent.contains("つらい") ||
           lowerContent.contains("辛い") || lowerContent.contains("落ち込") {
            return "悲しんでいる"
        }
        if lowerContent.contains("ストレス") || lowerContent.contains("イライラ") ||
           lowerContent.contains("むかつく") {
            return "イライラしている"
        }
        if lowerContent.contains("嬉しい") || lowerContent.contains("うれしい") ||
           lowerContent.contains("楽しい") || lowerContent.contains("幸せ") {
            return "喜んでいる"
        }
        if lowerContent.contains("最高") || lowerContent.contains("やった") ||
           lowerContent.contains("テンション") || lowerContent.contains("興奮") {
            return "興奮している"
        }
        
        return "普通"
    }
    
    // MARK: - Private Helper
    
    private func generateResponse(prompt: String, errorType: (Error) -> AIServiceError) async throws -> String {
        do {
            return try await openAI.generateText(prompt: prompt)
        } catch {
            print("❌ OpenAI Error: \(error)")
            throw errorType(error)
        }
    }
}

enum GreetingType {
    case morning
    case night
    case mutualFollow
}

enum AIServiceError: LocalizedError {
    case commentGenerationFailed(Error)
    case chatReplyFailed(Error)
    case postGenerationFailed(Error)
    case greetingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .commentGenerationFailed(let error):
            return "コメント生成に失敗しました: \(error.localizedDescription)"
        case .chatReplyFailed(let error):
            return "返信生成に失敗しました: \(error.localizedDescription)"
        case .postGenerationFailed(let error):
            return "投稿生成に失敗しました: \(error.localizedDescription)"
        case .greetingFailed(let error):
            return "挨拶生成に失敗しました: \(error.localizedDescription)"
        }
    }
}

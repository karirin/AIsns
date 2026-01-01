// Services/AIService.swift

import Foundation

class AIService {
    static let shared = AIService()
    private let openAI = OpenAIService.shared
    
    // MARK: - Format Helpers
    
    /// 会話履歴をAIが理解しやすい文字列形式に変換する
    private func formatHistory(_ history: [Message]) -> String {
        // 最近の10件のみを使用（トークン節約のため）
        let recentMessages = history.suffix(10)
        return recentMessages.map { message in
            let sender = message.isFromUser ? "ユーザー" : "キャラクター"
            return "\(sender): \(message.content)"
        }.joined(separator: "\n")
    }

    // MARK: - Comment Generation

    // 投稿に対するコメント生成 (UserMood Enum版 - 既存コード互換)
    func generateComment(for post: Post, by oshi: OshiCharacter, userMood: UserMood) async throws -> String {
        // 既存のプロンプト生成ロジックを使用
        let prompt = openAI.createCommentPrompt(
            character: oshi,
            postContent: post.content,
            userMood: userMood
        )
        
        return try await generateResponse(prompt: prompt, errorType: { AIServiceError.commentGenerationFailed($0) })
    }
    
    // 投稿に対するコメント生成 (String版 & ユーザー名対応 - 新機能)
    func generateComment(for post: Post, by oshi: OshiCharacter, userMood: String, userName: String) async throws -> String {
        let callingName = oshi.callingName(userName: userName)
        
        let prompt = """
        あなたは「\(oshi.name)」として、ユーザー（\(callingName)）の投稿にコメントしてください。
        
        【キャラクター設定】
        性格: \(oshi.personalityText)
        口調: \(oshi.speechStyleText)
        ユーザーの呼び方: \(callingName)
        
        【ユーザーの投稿】
        "\(post.content)"
        
        【ユーザーの感情分析】
        \(userMood)
        
        ユーザーの感情に寄り添い、キャラクターらしい反応を短く（30文字以内）返してください。
        """
        
        return try await generateResponse(prompt: prompt, errorType: { AIServiceError.commentGenerationFailed($0) })
    }
    
    // MARK: - Chat Generation

    // チャットメッセージ生成
    func generateChatReply(for message: String, by oshi: OshiCharacter, conversationHistory: [Message], userName: String) async throws -> String {
        // 呼び名を決定
        let callingName = oshi.callingName(userName: userName)
        
        let prompt = """
        あなたは「\(oshi.name)」というキャラクターになりきって、ユーザー（\(callingName)）と会話してください。
        
        【キャラクター設定】
        名前: \(oshi.name)
        性格: \(oshi.personalityText)
        口調: \(oshi.speechStyleText)
        話し方の特徴: \(oshi.speechCharacteristics)
        一人称: 私（またはキャラに合わせる）
        ユーザーの呼び方: \(callingName)
        
        【会話の履歴】
        \(formatHistory(conversationHistory))
        
        【ユーザーの最新メッセージ】
        \(message)
        
        上記のキャラクター設定を厳守し、短めの文章（1〜3文程度）で親しみを込めて返信してください。
        """
        
        return try await generateResponse(prompt: prompt, errorType: { AIServiceError.chatReplyFailed($0) })
    }
    
    // MARK: - Greeting Generation
    
    // 挨拶生成 (ユーザー名対応版)
    func generateGreeting(type: GreetingType, by oshi: OshiCharacter, userName: String = "") async throws -> String {
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
        性格: \(oshi.personalityText)
        口調: \(oshi.speechStyleText)
        ユーザーの呼び方: \(callingName)
        シチュエーション: \(context)
        
        短く（一言〜二言）、キャラクターらしさを出して話しかけてください。
        """
        
        return try await generateResponse(prompt: prompt, errorType: { AIServiceError.greetingFailed($0) })
    }
    
    // 初回挨拶生成 (ユーザー名対応版)
    func generateInitialGreeting(for oshi: OshiCharacter, userName: String) async throws -> String {
        let callingName = oshi.callingName(userName: userName)
        
        let prompt = """
        あなたは「\(oshi.name)」です。新しく友達になったユーザー（\(callingName)）に最初の挨拶をしてください。
        
        【設定】
        性格: \(oshi.personalityText)
        口調: \(oshi.speechStyleText)
        ユーザーの呼び方: \(callingName)
        
        自己紹介を含めて、これからの関係を楽しみにしている感じで短く話しかけてください。
        """
        
        return try await generateResponse(prompt: prompt, errorType: { AIServiceError.greetingFailed($0) })
    }
    
    // MARK: - Other AI Features

    // 推しからの自発的投稿生成
    func generateOshiPost(by oshi: OshiCharacter) async throws -> String {
        let prompt = openAI.createOshiPostPrompt(character: oshi)
        return try await generateResponse(prompt: prompt, errorType: { AIServiceError.postGenerationFailed($0) })
    }
    
    // ユーザーの気分を投稿から分析
    func analyzeMood(from content: String) -> String {
        let lowerContent = content.lowercased()
        
        // 簡易的なキーワードマッチング（必要に応じてAI判定に置き換え可能）
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
    
    /// 共通のエラーハンドリングを行う実行メソッド
    private func generateResponse(prompt: String, errorType: (Error) -> AIServiceError) async throws -> String {
        do {
            // ✅ 修正: sendRequest ではなく generateText を使用
            return try await openAI.generateText(prompt: prompt)
        } catch {
            print("❌ OpenAI Error: \(error)")
            throw errorType(error)
        }
    }
}

// MARK: - Enums & Errors

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

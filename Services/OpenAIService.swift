import Foundation

class OpenAIService {
    static let shared = OpenAIService()
    
    // 環境変数またはInfo.plistから取得
    private var apiKey: String {
        // 1. 環境変数から取得を試みる
        if let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !key.isEmpty {
            return key
        }
        
        // 2. Info.plistから取得を試みる
        if let key = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String, !key.isEmpty {
            return key
        }
        
        // 3. ハードコードされた値（開発用のみ - 本番では削除）
        return "YOUR_OPENAI_API_KEY_HERE"
    }
    
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    private init() {}
    
    // APIキーが設定されているか確認
    var isConfigured: Bool {
        return apiKey != "YOUR_OPENAI_API_KEY_HERE" && !apiKey.isEmpty
    }
    
    // OpenAI APIでテキスト生成
    func generateText(prompt: String) async throws -> String {
        guard isConfigured else {
            print("⚠️ OpenAI APIキーが設定されていません")
            print("📝 設定方法:")
            print("   1. Config.xcconfig.template を Config.xcconfig にコピー")
            print("   2. OpenAI APIキーを設定")
            print("   3. または、OpenAIService.swift で直接設定")
            throw OpenAIError.apiKeyNotSet
        }
        
        let url = URL(string: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "gpt-4.1-nano-2025-04-14",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.8,
            "max_tokens": 150
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            
            // エラーの詳細をログ出力
            if httpResponse.statusCode == 401 {
                print("❌ OpenAI API認証エラー: APIキーが無効です")
            } else if httpResponse.statusCode == 429 {
                print("❌ OpenAI APIレート制限エラー: リクエストが多すぎます")
            } else {
                print("❌ OpenAI APIエラー (Status \(httpResponse.statusCode)): \(errorMessage)")
            }
            
            throw OpenAIError.requestFailed(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        let decoder = JSONDecoder()
        let openAIResponse = try decoder.decode(OpenAIResponse.self, from: data)
        
        return openAIResponse.choices.first?.message.content ?? ""
    }
    
    func createInitialGreetingPrompt(character: OshiCharacter) -> String {
        var prompt = """
        あなたは\(character.name)として、初めて会ったユーザーに挨拶をします。
        
        【キャラクター設定】
        - 性格: \(character.personality.rawValue)
        """
        
        if !character.speechCharacteristics.isEmpty {
            prompt += "\n- 話し方: \(character.speechCharacteristics)"
        }
        
        prompt += """
        
        - 口調: \(character.speechStyle.rawValue)
        
        自己紹介を含めた、親しみやすい初回の挨拶を50文字以内で返してください。
        キャラクターの性格と口調を忠実に再現してください。
        """
        
        return prompt
    }
    
    // キャラクター設定を含むプロンプト生成
    func createCharacterPrompt(
        character: OshiCharacter,
        userMessage: String,
        conversationHistory: [Message] = []
    ) -> String {
        var prompt = """
        あなたは以下の設定のキャラクターとして振る舞ってください:
        
        【キャラクター設定】
        - 名前: \(character.name)
        - 性格: \(character.personality.rawValue)
        - 口調: \(character.speechStyle.rawValue)（例: \(character.speechStyle.example)）
        """
        
        prompt += "\n\n【重要な指示】"
        prompt += "\n- キャラクターになりきって、設定通りの性格と口調で返答してください"
        prompt += "\n- 返答は150文字以内の自然な会話にしてください"
        prompt += "\n- 親密度が高いほど親しげな態度で接してください"
        
        // 会話履歴を追加（最新5件）
        if !conversationHistory.isEmpty {
            prompt += "\n\n【会話履歴】"
            let recentMessages = conversationHistory.suffix(5)
            for message in recentMessages {
                let speaker = message.isFromUser ? "ユーザー" : character.name
                prompt += "\n\(speaker): \(message.content)"
            }
        }
        
        prompt += "\n\n【ユーザーからのメッセージ】\n\(userMessage)"
        prompt += "\n\n上記の設定に基づいて、\(character.name)として返答してください。"
        
        return prompt
    }
    
    // 投稿に対するコメント生成用プロンプト
    func createCommentPrompt(
        character: OshiCharacter,
        postContent: String,
        userMood: UserMood
    ) -> String {
        var prompt = """
        あなたは\(character.name)として、ユーザーの投稿にコメントします。
        
        【キャラクター設定】
        - 性格: \(character.personality.rawValue)
        - 口調: \(character.speechStyle.rawValue)
        
        【ユーザーの投稿】
        \(postContent)
        
        【ユーザーの気分】
        \(userMood.rawValue)
        
        キャラクターの性格に合った、温かく共感的なコメントを50文字以内で返してください。
        """
        
        return prompt
    }
    
    // 推しの自発的投稿生成用プロンプト
    func createOshiPostPrompt(character: OshiCharacter) -> String {
        let prompt = """
        あなたは\(character.name)として、SNSに日常の投稿をします。
        
        【キャラクター設定】
        - 性格: \(character.personality.rawValue)
        - 口調: \(character.speechStyle.rawValue)
        
        自然な日常投稿を80文字以内で作成してください。
        """
        
        return prompt
    }
}

// MARK: - Response Models

struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
        
        struct Message: Codable {
            let content: String
        }
    }
}

enum OpenAIError: LocalizedError {
    case apiKeyNotSet
    case invalidResponse
    case requestFailed(statusCode: Int, message: String)
    
    var errorDescription: String? {
        switch self {
        case .apiKeyNotSet:
            return "OpenAI APIキーが設定されていません。README.mdの手順に従って設定してください。"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .requestFailed(let statusCode, let message):
            return "リクエスト失敗 (Status: \(statusCode)): \(message)"
        }
    }
}

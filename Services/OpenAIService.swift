/*
　AppStoreのリリースしたアプリが
  AIの返答が返ってこないため直に記述する
 */

//import Foundation
//
//class OpenAIService {
//    static let shared = OpenAIService()
//    
//    // 環境変数またはInfo.plistから取得
//    private var apiKey: String {
//        // 1. 環境変数から取得を試みる
//        if let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !key.isEmpty {
//            return key
//        }
//        
//        // 2. Info.plistから取得を試みる
//        if let key = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String, !key.isEmpty {
//            return key
//        }
//        
//        // 3. ハードコードされた値（開発用のみ - 本番では削除）
//        return "YOUR_OPENAI_API_KEY_HERE"
//    }
//    
//    private let baseURL = "https://api.openai.com/v1/chat/completions"
//    
//    private init() {}
//    
//    // APIキーが設定されているか確認
//    var isConfigured: Bool {
//        return apiKey != "YOUR_OPENAI_API_KEY_HERE" && !apiKey.isEmpty
//    }
//    
//    // OpenAI APIでテキスト生成
//    func generateText(prompt: String) async throws -> String {
//        guard isConfigured else {
//            print("⚠️ OpenAI APIキーが設定されていません")
//            print("📝 設定方法:")
//            print("   1. Config.xcconfig.template を Config.xcconfig にコピー")
//            print("   2. OpenAI APIキーを設定")
//            print("   3. または、OpenAIService.swift で直接設定")
//            throw OpenAIError.apiKeyNotSet
//        }
//        
//        let url = URL(string: baseURL)!
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        let requestBody: [String: Any] = [
//            "model": "gpt-4.1-nano-2025-04-14",
//            "messages": [
//                ["role": "user", "content": prompt]
//            ],
//            "temperature": 0.8,
//            "max_tokens": 150
//        ]
//        
//        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
//        
//        let (data, response) = try await URLSession.shared.data(for: request)
//        
//        guard let httpResponse = response as? HTTPURLResponse else {
//            throw OpenAIError.invalidResponse
//        }
//        
//        guard httpResponse.statusCode == 200 else {
//            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
//            
//            // エラーの詳細をログ出力
//            if httpResponse.statusCode == 401 {
//                print("❌ OpenAI API認証エラー: APIキーが無効です")
//            } else if httpResponse.statusCode == 429 {
//                print("❌ OpenAI APIレート制限エラー: リクエストが多すぎます")
//            } else {
//                print("❌ OpenAI APIエラー (Status \(httpResponse.statusCode)): \(errorMessage)")
//            }
//            
//            throw OpenAIError.requestFailed(statusCode: httpResponse.statusCode, message: errorMessage)
//        }
//        
//        let decoder = JSONDecoder()
//        let openAIResponse = try decoder.decode(OpenAIResponse.self, from: data)
//        
//        return openAIResponse.choices.first?.message.content ?? ""
//    }
//    
//    func createInitialGreetingPrompt(character: OshiCharacter) -> String {
//        var prompt = """
//        あなたは\(character.name)として、初めて会ったユーザーに挨拶をします。
//        
//        【キャラクター設定】
//        - 性格: \(character.personalityText)
//        """
//        
//        if !character.speechCharacteristics.isEmpty {
//            prompt += "\n- 話し方: \(character.speechCharacteristics)"
//        }
//        
//        prompt += """
//        
//        - 口調: \(character.speechStyleText)
//        
//        自己紹介を含めた、親しみやすい初回の挨拶を50文字以内で返してください。
//        キャラクターの性格と口調を忠実に再現してください。
//        """
//        
//        return prompt
//    }
//    
//    // キャラクター設定を含むプロンプト生成
//    func createCharacterPrompt(
//        character: OshiCharacter,
//        userMessage: String,
//        conversationHistory: [Message] = []
//    ) -> String {
//        var prompt = """
//        あなたは以下の設定のキャラクター「\(character.name)」になりきって会話してください。
//        AI言語モデルとしての自覚は一切持たないでください。
//        
//        【キャラクター設定】
//        - 名前: \(character.name)
//        - 性格: \(character.personalityText)
//        - 口調: \(character.speechStyleText)
//        """
//        
//        prompt += "\n\n【重要な指示】"
//        // 変更点: よりリアルな会話のための指示を追加
//        prompt += "\n- 設定通りの性格と口調を厳守してください。敬語キャラでないなら敬語は使わないでください。"
//        prompt += "\n- ユーザーの質問に答えるだけでなく、自分から話題を振ったり、短く相槌を打ったりして、会話のリズムを作ってください。"
//        prompt += "\n- 優等生的な回答は求めていません。キャラによっては不機嫌だったり、適当だったりする反応もOKです。"
//        prompt += "\n- 返答は長くなりすぎないよう、SNSのチャットとして自然な長さ（1〜3文程度）に収めてください。"
//        
//        // 会話履歴を追加
//        if !conversationHistory.isEmpty {
//            prompt += "\n\n【直近の会話履歴】"
//            let recentMessages = conversationHistory.suffix(5)
//            for message in recentMessages {
//                let speaker = message.isFromUser ? "ユーザー" : character.name
//                prompt += "\n\(speaker): \(message.content)"
//            }
//        }
//        
//        prompt += "\n\n【ユーザーからのメッセージ】\n\(userMessage)"
//        prompt += "\n\n\(character.name)として返答:"
//        
//        return prompt
//    }
//    
//    // 投稿に対するコメント生成用プロンプト
//    func createCommentPrompt(
//        character: OshiCharacter,
//        postContent: String,
//        userMood: UserMood
//    ) -> String {
//        // 変更点: より具体的な指示と制約を追加
//        var prompt = """
//        あなたは\(character.name)という実在する人物として、ユーザーのSNS投稿にリプライ（返信）をします。
//        AIアシスタントとしての振る舞いは忘れ、親しいフォロワーとして接してください。
//        
//        【キャラクター設定】
//        - 性格: \(character.personalityText)
//        - 口調: \(character.speechStyleText)
//        
//        【ユーザーの投稿】
//        \(postContent)
//        
//        【ユーザーの気分（参考）】
//        \(userMood.rawValue)
//        
//        【重要：より人間らしく振る舞うためのルール】
//        1. AIのような「状況の説明」や「まとめ」は絶対にしないでください。
//        2. ユーザーの言葉をオウム返ししないでください。いきなり感想やツッコミを入れてください。
//        3. 文法的な正しさよりも、SNSらしい「ノリ」や「短さ」を重視してください。
//        4. 「です・ます」調は、キャラ設定で敬語になっていない限り禁止です。フランクな口語体（タメ口、スラング含む）で話してください。
//        5. 50文字以内の短文で返してください。
//        
//        上記を守り、キャラの性格全開でコメントしてください。
//        """
//        
//        return prompt
//    }
//    
//    // 推しの自発的投稿生成用プロンプト
//    func createOshiPostPrompt(character: OshiCharacter) -> String {
//        let prompt = """
//        あなたは\(character.name)として、SNSに日常の投稿をします。
//        
//        【キャラクター設定】
//        - 性格: \(character.personalityText)
//        - 口調: \(character.speechStyleText)
//        
//        自然な日常投稿を80文字以内で作成してください。
//        """
//        
//        return prompt
//    }
//}
//
//// MARK: - Response Models
//
//struct OpenAIResponse: Codable {
//    let choices: [Choice]
//    
//    struct Choice: Codable {
//        let message: Message
//        
//        struct Message: Codable {
//            let content: String
//        }
//    }
//}
//
//enum OpenAIError: LocalizedError {
//    case apiKeyNotSet
//    case invalidResponse
//    case requestFailed(statusCode: Int, message: String)
//    
//    var errorDescription: String? {
//        switch self {
//        case .apiKeyNotSet:
//            return "OpenAI APIキーが設定されていません。README.mdの手順に従って設定してください。"
//        case .invalidResponse:
//            return "無効なレスポンスです"
//        case .requestFailed(let statusCode, let message):
//            return "リクエスト失敗 (Status: \(statusCode)): \(message)"
//        }
//    }
//}



import Foundation
import FirebaseFunctions

class OpenAIService {
    static let shared = OpenAIService()
    private let functions = Functions.functions(region: "asia-northeast1")
    
    private init() {}
    
    // MARK: - API Methods
    
    // OpenAI APIでテキスト生成
    /// - Parameter maxTokens: 長い出力が必要な時だけ指定する（サーバー側で150〜800に丸められる）。
    func generateText(prompt: String, maxTokens: Int? = nil) async throws -> String {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            throw OpenAIError.invalidPrompt
        }

        do {
            let options = HTTPSCallableOptions(requireLimitedUseAppCheckTokens: true)
            let callable = functions.httpsCallable("generateAIText", options: options)
            callable.timeoutInterval = 60
            var payload: [String: Any] = ["prompt": trimmedPrompt]
            if let maxTokens {
                payload["maxTokens"] = maxTokens
            }
            let result = try await callable.call(payload)

            guard let data = result.data as? [String: Any],
                  let text = data["text"] as? String,
                  !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw OpenAIError.invalidResponse
            }

            return text
        } catch let error as OpenAIError {
            throw error
        } catch {
            throw OpenAIError.backendUnavailable(error.localizedDescription)
        }
    }
    
    func createInitialGreetingPrompt(character: OshiCharacter) -> String {
        var prompt = """
        あなたは\(character.name)として、初めて会ったユーザーに挨拶をします。
        
        【キャラクター設定】
        - 性格: \(character.personalityText)
        - 外見: \(character.appearanceDescription.isEmpty ? "特になし" : character.appearanceDescription)
        - 背景設定: \(character.backgroundStory.isEmpty ? "特になし" : character.backgroundStory)
        """
        
        if !character.speechCharacteristics.isEmpty {
            prompt += "\n- 話し方: \(character.speechCharacteristics)"
        }
        
        prompt += """
        
        - 口調: \(character.speechStyleText)
        
        自己紹介を含めた、親しみやすい初回の挨拶を50文字以内で返してください。
        キャラクターの性格と口調を忠実に再現してください。
        """
        
        return prompt
    }
    
    func createCharacterPrompt(
        character: OshiCharacter,
        userMessage: String,
        conversationHistory: [Message] = []
    ) -> String {
        var prompt = """
        あなたは以下の設定のキャラクター「\(character.name)」になりきって会話してください。
        AI言語モデルとしての自覚は一切持たないでください。
        
        【キャラクター設定】
        - 名前: \(character.name)
        - 性格: \(character.personalityText)
        - 外見: \(character.appearanceDescription.isEmpty ? "特になし" : character.appearanceDescription)
        - 背景設定: \(character.backgroundStory.isEmpty ? "特になし" : character.backgroundStory)
        - 口調: \(character.speechStyleText)
        """
        
        prompt += "\n\n【重要な指示】"
        prompt += "\n- 設定通りの性格と口調を厳守してください。敬語キャラでないなら敬語は使わないでください。"
        prompt += "\n- ユーザーの質問に答えるだけでなく、自分から話題を振ったり、短く相槌を打ったりして、会話のリズムを作ってください。"
        prompt += "\n- 返答は長くなりすぎないよう、SNSのチャットとして自然な長さ（1〜3文程度）に収めてください。"
        prompt += "\n- 外見や背景設定は関係する話題でだけ自然に反映し、毎回説明しないでください。"
        
        if !conversationHistory.isEmpty {
            prompt += "\n\n【直近の会話履歴】"
            let recentMessages = conversationHistory.suffix(5)
            for message in recentMessages {
                let speaker = message.isFromUser ? "ユーザー" : character.name
                prompt += "\n\(speaker): \(message.content)"
            }
        }
        
        prompt += "\n\n【ユーザーからのメッセージ】\n\(userMessage)"
        prompt += "\n\n\(character.name)として返答:"
        
        return prompt
    }

    func createCommentPrompt(character: OshiCharacter, postContent: String, userMood: UserMood) -> String {
        return """
        あなたは\(character.name)という実在する人物として、ユーザーのSNS投稿にリプライをします。
        性格: \(character.personalityText)
        外見: \(character.appearanceDescription.isEmpty ? "特になし" : character.appearanceDescription)
        背景設定: \(character.backgroundStory.isEmpty ? "特になし" : character.backgroundStory)
        口調: \(character.speechStyleText)
        
        【ユーザーの投稿】
        \(postContent)
        
        【ルール】
        1. AI的な要約は禁止。
        2. フランクな口語体で50文字以内で返してください。
        """
    }
    
    func createOshiPostPrompt(character: OshiCharacter) -> String {
        return """
        あなたは\(character.name)として、SNSに日常の投稿をします。
        性格: \(character.personalityText)
        外見: \(character.appearanceDescription.isEmpty ? "特になし" : character.appearanceDescription)
        背景設定: \(character.backgroundStory.isEmpty ? "特になし" : character.backgroundStory)
        口調: \(character.speechStyleText)
        自然な日常投稿を80文字以内で作成してください。
        """
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
    case invalidPrompt
    case invalidResponse
    case backendUnavailable(String)
    case requestFailed(statusCode: Int, message: String)
    
    var errorDescription: String? {
        switch self {
        case .apiKeyNotSet: return "APIキーが設定されていません。"
        case .invalidPrompt: return "送信内容が空です。"
        case .invalidResponse: return "無効なレスポンスです。"
        case .backendUnavailable(let message): return "AIサーバーに接続できません: \(message)"
        case .requestFailed(let code, let msg): return "エラー(\(code)): \(msg)"
        }
    }
}

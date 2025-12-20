// Services/AIService.swift

import Foundation

class AIService {
    static let shared = AIService()
    private let openAI = OpenAIService.shared
    
    // 投稿に対するコメント生成（OpenAI使用）
    func generateComment(for post: Post, by oshi: OshiCharacter, userMood: UserMood) async throws -> String {
        let prompt = openAI.createCommentPrompt(
            character: oshi,
            postContent: post.content,
            userMood: userMood
        )
        
        do {
            let response = try await openAI.generateText(prompt: prompt)
            return response
        } catch {
            print("❌ OpenAI コメント生成エラー: \(error)")
            // エラー時は例外を再スロー
            throw AIServiceError.commentGenerationFailed(error)
        }
    }
    
    func generateInitialGreeting(for oshi: OshiCharacter) async throws -> String {
         let prompt = """
         あなたは\(oshi.name)として、初めて会ったユーザーに挨拶をします。
         
         【キャラクター設定】
         - 性格: \(oshi.personality.rawValue)
         - 口調: \(oshi.speechStyle.rawValue)
         - 関係性: \(oshi.relationshipDistance.rawValue)
         - 世界観: \(oshi.worldSetting.rawValue)
         
         自己紹介を含めた、親しみやすい初回の挨拶を50文字以内で返してください。
         キャラクターの性格と口調を忠実に再現してください。
         """
         
         do {
             let response = try await openAI.generateText(prompt: prompt)
             return response
         } catch {
             print("❌ OpenAI 初回挨拶エラー: \(error)")
             throw AIServiceError.greetingFailed(error)
         }
     }
    
    // チャットメッセージ生成（OpenAI使用）
    func generateChatReply(for userMessage: String, by oshi: OshiCharacter,
                           conversationHistory: [Message]) async throws -> String {
        let prompt = openAI.createCharacterPrompt(
            character: oshi,
            userMessage: userMessage,
            conversationHistory: conversationHistory
        )
        
        do {
            let response = try await openAI.generateText(prompt: prompt)
            return response
        } catch {
            print("❌ OpenAI チャット返信エラー: \(error)")
            throw AIServiceError.chatReplyFailed(error)
        }
    }
    
    // 推しからの自発的投稿生成（OpenAI使用）
    func generateOshiPost(by oshi: OshiCharacter) async throws -> String {
        let prompt = openAI.createOshiPostPrompt(character: oshi)
        
        do {
            let response = try await openAI.generateText(prompt: prompt)
            return response
        } catch {
            print("❌ OpenAI 投稿生成エラー: \(error)")
            throw AIServiceError.postGenerationFailed(error)
        }
    }
    
    // おはよう/おやすみメッセージ（OpenAI使用）
    func generateGreeting(type: GreetingType, by oshi: OshiCharacter) async throws -> String {
        let greetingType = type == .morning ? "朝の挨拶" : "おやすみの挨拶"
        
        let prompt = """
        あなたは\(oshi.name)として、\(greetingType)をします。
        
        【キャラクター設定】
        - 性格: \(oshi.personality.rawValue)
        - 口調: \(oshi.speechStyle.rawValue)
        - 親密度: \(oshi.intimacyLevel)/100
        
        性格と口調に合った自然な\(greetingType)を30文字以内で返してください。
        """
        
        do {
            let response = try await openAI.generateText(prompt: prompt)
            return response
        } catch {
            print("❌ OpenAI 挨拶生成エラー: \(error)")
            throw AIServiceError.greetingFailed(error)
        }
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
}

struct ConversationContext {
    let mood: UserMood
    let messageCount: Int
}

enum GreetingType {
    case morning
    case night
}

// エラー定義
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

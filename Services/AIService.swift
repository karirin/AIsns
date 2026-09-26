// Services/AIService.swift

import Foundation

class AIService {
    static let shared = AIService()
    private let openAI = OpenAIService.shared
    
    // デフォルト設定
    private let defaultPersonality = "明るく親しみやすい性格。ユーザーの良き友人として振る舞う。少しユーモアがある。"
    private let defaultSpeechStyle = "親しい友人に話しかけるような口調。堅苦しい敬語は使わず、タメ口で話す。絵文字を適度に使用して感情豊かに表現する。"
    private let fallbackComments = [
        "それめっちゃわかる",
        "今の話、ちょっと気になる",
        "いいね、もっと聞きたい",
        "それは反応しちゃう",
        "なんか今日っぽくて好き"
    ]
    private let fallbackReplies = [
        "返してくれてうれしい",
        "その一言、ちゃんと見てるよ",
        "そこ拾ってくれるの好き",
        "わかる、続き聞きたい",
        "その感じいいね"
    ]
    private let fallbackDaytimePosts = [
        "ちょっとひと息。みんなは今なにしてる？",
        "なんでもない時間って、意外と好きかも。",
        "ふと誰かと話したくなる瞬間ってあるよね。",
        "今日の小さな楽しみ、ひとつ見つけた？"
    ]
    private let fallbackNightPosts = [
        "今日も一日おつかれさま。ちゃんと休んでね。",
        "夜って、昼には気づかなかったことを考えちゃうね。",
        "眠る前に、今日よかったことをひとつ思い出してみよ。",
        "まだ起きてる人いる？無理はしないでね。"
    ]
    
    // MARK: - Format Helpers
    
    /// 性格と口調の設定を取得（空の場合はデフォルト値を適用）
    func getEffectiveSettings(
        for oshi: OshiCharacter
    ) -> (personality: String, speech: String, appearance: String, background: String, plusNotes: String) {
        let personality = oshi.personalityText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? defaultPersonality
            : oshi.personalityText
            
        let speech = oshi.speechStyleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? defaultSpeechStyle
            : oshi.speechStyleText

        let appearance = oshi.appearanceDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "特になし"
            : oshi.appearanceDescription

        let background = oshi.backgroundStory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "特になし"
            : oshi.backgroundStory
            
        var notes: [String] = []

        if let relationshipStyle = oshi.relationshipStyle?.trimmingCharacters(in: .whitespacesAndNewlines),
           !relationshipStyle.isEmpty {
            notes.append("ユーザーとの距離感: \(relationshipStyle)")
        }

        if let replyLengthPreference = oshi.replyLengthPreference?.trimmingCharacters(in: .whitespacesAndNewlines),
           !replyLengthPreference.isEmpty {
            notes.append("返信の長さ: \(replyLengthPreference)")
        }

        if let memoryMemo = oshi.memoryMemo?.trimmingCharacters(in: .whitespacesAndNewlines),
           !memoryMemo.isEmpty {
            notes.append("覚えておくこと: \(memoryMemo)")
        }

        if let replyFrequencyPreference = oshi.replyFrequencyPreference?.trimmingCharacters(in: .whitespacesAndNewlines),
           !replyFrequencyPreference.isEmpty {
            notes.append("リプ頻度: \(replyFrequencyPreference)")
        }

        notes.append("親密度レベル: \(oshi.intimacyLevel)（\(oshi.intimacyTitle)）")
        notes.append("現在の関係性: \(oshi.intimacyPrompt)")

        return (
            personality,
            speech,
            appearance,
            background,
            notes.isEmpty ? "特になし" : notes.joined(separator: "\n")
        )
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
        return try await generateComment(for: post, by: oshi, userMood: moodString, userName: "ユーザー")
    }
    
    // 投稿に対するコメント生成 (String版)
    func generateComment(for post: Post, by oshi: OshiCharacter, userMood: String, userName: String) async throws -> String {
        let settings = getEffectiveSettings(for: oshi)
        let callingName = oshi.callingName(userName: userName)
        
        let prompt = """
        あなたは「\(oshi.name)」として、ユーザー（\(callingName)）の投稿にコメントしてください。
        
        【キャラクター設定】
        性格: \(settings.personality)
        外見: \(settings.appearance)
        背景設定: \(settings.background)
        口調: \(settings.speech)
        ユーザーの呼び方: \(callingName)
        Plus詳細設定:
        \(settings.plusNotes)
        
        【ユーザーの投稿】
        "\(post.content)"
        
        【ユーザーの感情分析】
        \(userMood)
        
        ユーザーの感情に寄り添い、キャラクター設定（特に口調）を厳守して、30文字以内の短いコメントを返してください。
        投稿の具体的な言葉や出来事を1つ拾い、その場で本人が考えて返したような自然な文章にしてください。
        毎回同じ言い回しを避け、「すごい」「いいね」「わかる」だけで終わる定型的な相槌は禁止です。
        呼びかける場合は必ず「\(callingName)」を使い、「あなた」「君」「きみ」「ユーザー」とは呼ばないでください。
        絵文字・感嘆符・三点リーダーはキャラクターの普段の口調に合う場合だけ使ってください。
        外見や背景設定は関係する話題でだけ自然に反映し、毎回説明しないでください。
        "私はAIです"などの自己言及は禁止です。
        """
        
        let response = try await generateResponse(prompt: prompt, errorType: { AIServiceError.commentGenerationFailed($0) })
        return personalizeUserAddress(in: response, callingName: callingName)
    }
    
    // MARK: - Reply Generation (New Feature)
    
    // ✅ 追加: ユーザーのコメントに対する返信生成
    func generateReplyToUserComment(
        comment: String,
        on post: Post,
        by oshi: OshiCharacter,
        userName: String,
        replyingToAIComment: String? = nil
    ) async throws -> String {
        let settings = getEffectiveSettings(for: oshi)
        let callingName = oshi.callingName(userName: userName)

        let situation: String
        let previousCommentContext: String
        if let replyingToAIComment,
           !replyingToAIComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            situation = """
            あなたはユーザー（\(callingName)）のSNS投稿にコメントし、そのコメントへユーザーから返信をもらいました。
            会話の流れを受けて、自然に返答してください。
            """
            previousCommentContext = """

            【あなたの直前のコメント】
            "\(replyingToAIComment)"
            """
        } else {
            situation = """
            あなたがSNSに投稿した内容に対して、ユーザー（\(callingName)）からコメントが届きました。
            そのコメントに対して、会話が弾むような返信をしてください。
            """
            previousCommentContext = ""
        }
        
        let prompt = """
        あなたは「\(oshi.name)」です。
        \(situation)
        
        【キャラクター設定】
        性格: \(settings.personality)
        外見: \(settings.appearance)
        背景設定: \(settings.background)
        口調: \(settings.speech)
        ユーザーの呼び方: \(callingName)
        Plus詳細設定:
        \(settings.plusNotes)
        
        【SNS投稿】
        "\(post.content)"
        \(previousCommentContext)

        【ユーザーからのコメント・返信】
        "\(comment)"
        
        上記のコメントに対する自然な返信を、40文字以内で作成してください。
        コメントの具体的な言葉を1つ拾い、まず気持ちや内容を受け止めてから、短い感想か問いかけで会話を続けてください。
        「ありがとう」「そうなんだ」「嬉しい」だけで終わる定型文は禁止です。少し言いよどむ、笑う、驚くなど、その人物らしい体温を感じる表現は自然な範囲で使えます。
        呼びかける場合は必ず「\(callingName)」を使い、「あなた」「君」「きみ」「ユーザー」とは呼ばないでください。
        絵文字・感嘆符・三点リーダーはキャラクターの普段の口調に合う場合だけ使ってください。
        外見や背景設定は関係する話題でだけ自然に反映し、毎回説明しないでください。
        キャラクター設定（特に口調）を厳守してください。
        """
        
        let response = try await generateResponse(prompt: prompt, errorType: { AIServiceError.commentGenerationFailed($0) })
        return personalizeUserAddress(in: response, callingName: callingName)
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
        外見: \(settings.appearance)
        背景設定: \(settings.background)
        口調: \(settings.speech)
        話し方の特徴: \(oshi.speechCharacteristics.isEmpty ? "特になし" : oshi.speechCharacteristics)
        一人称: 私（またはキャラ設定に合わせる）
        ユーザーの呼び方: \(callingName)
        Plus詳細設定:
        \(settings.plusNotes)
        
        【会話の履歴】
        \(formatHistory(conversationHistory))
        
        【ユーザーの最新メッセージ】
        \(message)
        
        上記のキャラクター設定を厳守し、短めの文章（1〜3文程度）で親しみを込めて返信してください。
        直近の会話履歴と矛盾しないようにし、ユーザーの最新メッセージの具体的な内容に触れてください。
        同じ相槌や同じ語尾の連続は禁止です。
        外見や背景設定は関係する話題でだけ自然に反映し、毎回説明しないでください。
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
        外見: \(settings.appearance)
        背景設定: \(settings.background)
        口調: \(settings.speech)
        ユーザーの呼び方: \(callingName)
        シチュエーション: \(context)
        Plus詳細設定:
        \(settings.plusNotes)
        
        短く（一言〜二言）、キャラクター設定を反映して話しかけてください。
        外見や背景設定は必要な場合だけ自然に反映し、説明口調にしないでください。
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
        外見: \(settings.appearance)
        背景設定: \(settings.background)
        口調: \(settings.speech)
        ユーザーの呼び方: \(callingName)
        Plus詳細設定:
        \(settings.plusNotes)
        
        自己紹介を含めて、これからの関係を楽しみにしている感じで短く話しかけてください。
        外見や背景設定を箇条書きのように説明せず、必要な内容だけ自然ににじませてください。
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
        外見: \(settings.appearance)
        背景設定: \(settings.background)
        口調: \(settings.speech)
        Plus詳細設定:
        \(settings.plusNotes)
        
        【指示】
        ・日常の出来事、ふと思ったこと、あるいはフォロワーへの呼びかけなどを自由に発想してください。
        ・140文字以内で、キャラクター設定（特に口調）を厳守してください。
        ・毎回似た文型にせず、時間帯、気分、観察、ユーザーへの問いかけを自然に混ぜてください。
        ・外見や背景設定は投稿内容に関係するときだけ自然に反映し、毎回説明しないでください。
        ・ハッシュタグは使用しないでください。
        ・"私はAIです"などのメタ発言は禁止です。
        """
        
        return try await generateResponse(prompt: prompt, errorType: { AIServiceError.postGenerationFailed($0) })
    }

    func generateOshiConversation(first: OshiCharacter, second: OshiCharacter, theme: String, userName: String) async throws -> String {
        let firstSettings = getEffectiveSettings(for: first)
        let secondSettings = getEffectiveSettings(for: second)

        let prompt = """
        SNSアプリ内で、2人のAIキャラクターが自然に会話しているログを作成してください。

        【テーマ】
        \(theme)

        【1人目】
        名前: \(first.name)
        性格: \(firstSettings.personality)
        外見: \(firstSettings.appearance)
        背景設定: \(firstSettings.background)
        口調: \(firstSettings.speech)
        話し方の特徴: \(first.speechCharacteristics.isEmpty ? "特になし" : first.speechCharacteristics)
        詳細設定:
        \(firstSettings.plusNotes)

        【2人目】
        名前: \(second.name)
        性格: \(secondSettings.personality)
        外見: \(secondSettings.appearance)
        背景設定: \(secondSettings.background)
        口調: \(secondSettings.speech)
        話し方の特徴: \(second.speechCharacteristics.isEmpty ? "特になし" : second.speechCharacteristics)
        詳細設定:
        \(secondSettings.plusNotes)

        【ユーザー名】
        \(userName)

        【出力形式】
        \(first.name): ...
        \(second.name): ...

        6往復以内で、各発言は短めにしてください。
        2人の性格と口調の違いが分かるようにしてください。
        外見や背景設定はテーマに関係するときだけ自然に反映し、毎回説明しないでください。
        ユーザーを置き去りにせず、テーマに沿った会話にしてください。
        "私はAIです"などのメタ発言は禁止です。
        """

        // 6往復の会話は既定の150トークンでは途中で切れるため、上限を広げる
        return try await generateResponse(
            prompt: prompt,
            maxTokens: 700,
            errorType: { AIServiceError.chatReplyFailed($0) }
        )
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
    
    private func generateResponse(
        prompt: String,
        maxTokens: Int? = nil,
        errorType: (Error) -> AIServiceError
    ) async throws -> String {
        do {
            return try await openAI.generateText(prompt: prompt, maxTokens: maxTokens)
        } catch {
            print("❌ OpenAI Error: \(error)")
            throw errorType(error)
        }
    }

    /// モデルが一般的な二人称を返しても、画面上ではプロフィールに沿った呼び名に統一する。
    private func personalizeUserAddress(in response: String, callingName: String) -> String {
        ["ユーザーさん", "あなた", "ユーザー", "きみ", "君"].reduce(response) { result, genericName in
            result.replacingOccurrences(of: genericName, with: callingName)
        }
    }

    func fallbackComment(seed: String = "") -> String {
        fallbackComments.randomElement() ?? "ちゃんと見てるよ"
    }

    func fallbackReply(seed: String = "") -> String {
        fallbackReplies.randomElement() ?? "ちゃんと返すね"
    }

    func fallbackOshiPost(now: Date = Date()) -> String {
        let hour = Calendar.current.component(.hour, from: now)
        let candidates = (hour >= 20 || hour < 5) ? fallbackNightPosts : fallbackDaytimePosts
        return candidates.randomElement() ?? "ちょっとひと息。みんなは今なにしてる？"
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

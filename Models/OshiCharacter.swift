import Foundation
import SwiftUI

enum Gender: String, CaseIterable, Codable {
    case male = "男性"
    case female = "女性"
    case other = "その他"
    
    var icon: String {
        switch self {
        case .male: return "♂"
        case .female: return "♀"
        case .other: return "●"
        }
    }
}

enum PersonalityType: String, CaseIterable, Codable {
    case kind = "優しい"
    case tsundere = "ツンデレ"
    case cool = "クール"
    case younger = "年下"
    case protective = "保護者系"
    
    var emoji: String {
        switch self {
        case .kind: return "😊"
        case .tsundere: return "😤"
        case .cool: return "😎"
        case .younger: return "🥺"
        case .protective: return "🤗"
        }
    }
}

enum SpeechStyle: String, CaseIterable, Codable {
    case polite = "敬語"
    case casual = "タメ口"
    case dialect = "方言"
    case character = "キャラ口調"
    
    var example: String {
        switch self {
        case .polite: return "お疲れ様です"
        case .casual: return "おつかれ"
        case .dialect: return "おつかれさん"
        case .character: return "おつかれなのだ"
        }
    }
}

struct OshiCharacter: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var gender: Gender?
    var appearanceDescription: String
    var backgroundStory: String
    var personalityText: String
    var speechCharacteristics: String
    var userCallingName: String
    var speechStyleText: String
    var relationshipStyle: String?
    var replyLengthPreference: String?
    var memoryMemo: String?
    var replyFrequencyPreference: String?
    var createdAt: Date
    var totalInteractions: Int
    var lastInteractionDate: Date?
    var avatarImageURL: String?
    
    var isFollowingUser: Bool
    var isFollowedByUser: Bool
    var isPublic: Bool
    var isCreatedByUser: Bool
    
    // 追加: フォロワー数
    var followerCount: Int
    
    var creatorId: String?
    
    var isMutualFollow: Bool {
        isFollowingUser && isFollowedByUser
    }

    private static let intimacyThresholds = [0, 10, 30, 60, 100]

    var intimacyLevel: Int {
        let index = Self.intimacyThresholds.lastIndex(where: { totalInteractions >= $0 }) ?? 0
        return index + 1
    }

    var intimacyTitle: String {
        switch intimacyLevel {
        case 1: return "知り合い"
        case 2: return "話し相手"
        case 3: return "仲良し"
        case 4: return "大切な人"
        default: return "かけがえのない存在"
        }
    }

    var intimacyProgress: Double {
        let levelIndex = min(intimacyLevel - 1, Self.intimacyThresholds.count - 1)
        guard levelIndex < Self.intimacyThresholds.count - 1 else { return 1 }
        let lower = Self.intimacyThresholds[levelIndex]
        let upper = Self.intimacyThresholds[levelIndex + 1]
        return Double(totalInteractions - lower) / Double(upper - lower)
    }

    var interactionsUntilNextLevel: Int? {
        guard intimacyLevel < Self.intimacyThresholds.count else { return nil }
        return max(0, Self.intimacyThresholds[intimacyLevel] - totalInteractions)
    }

    var intimacyPrompt: String {
        switch intimacyLevel {
        case 1:
            return "まだ知り合ったばかり。優しく自然に距離を縮める。"
        case 2:
            return "会話に慣れてきた関係。以前より少しくだけた口調で話す。"
        case 3:
            return "気心の知れた仲良し。親しみのある呼び方や軽い冗談を自然に使える。"
        case 4:
            return "互いを大切に思う親密な関係。日々の変化を気にかけ、特別感のある言葉を時々使う。"
        default:
            return "かけがえのない深い関係。過度に依存的にならず、強い信頼と安心感が伝わる専用の言葉を使う。"
        }
    }

    @MainActor
    var avatarImage: UIImage? {
        get async {
            guard let urlString = avatarImageURL else { return nil }
            return try? await FirebaseStorageManager.shared.downloadImage(from: urlString)
        }
    }
    
    func callingName(userName: String) -> String {
        let customCallingName = userCallingName.trimmingCharacters(in: .whitespacesAndNewlines)
        let profileName = userName.trimmingCharacters(in: .whitespacesAndNewlines)

        // 「あなた」は旧データで使っていた既定値なので、プロフィール名を優先する。
        // 「姫」「先輩」など、ユーザーが明示した呼び方は引き続き尊重する。
        if !customCallingName.isEmpty && !Self.genericCallingNames.contains(customCallingName) {
            return customCallingName
        }

        if !profileName.isEmpty && !Self.genericCallingNames.contains(profileName) {
            if profileName.hasSuffix("さん") || profileName.hasSuffix("ちゃん") ||
                profileName.hasSuffix("くん") || profileName.hasSuffix("君") ||
                profileName.hasSuffix("様") {
                return profileName
            }
            if intimacyLevel >= 3 {
                return profileName
            }
            return "\(profileName)さん"
        }

        return "ユーザーさん"
    }

    private static let genericCallingNames: Set<String> = ["あなた", "きみ", "君", "ユーザー"]
    
    init(
        id: UUID = UUID(),
        name: String,
        gender: Gender? = nil,
        appearanceDescription: String = "",
        backgroundStory: String = "",
        personalityText: String = "",
        speechCharacteristics: String = "",
        userCallingName: String = "",
        speechStyleText: String = "",
        relationshipStyle: String? = nil,
        replyLengthPreference: String? = nil,
        memoryMemo: String? = nil,
        replyFrequencyPreference: String? = nil,
        avatarImageURL: String? = nil,
        createdAt: Date = Date(),
        totalInteractions: Int = 0,
        lastInteractionDate: Date? = nil,
        isFollowingUser: Bool = false,
        isFollowedByUser: Bool = false,
        isPublic: Bool = false,
        isCreatedByUser: Bool = false,
        followerCount: Int = 0,
        creatorId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.gender = gender
        self.appearanceDescription = appearanceDescription
        self.backgroundStory = backgroundStory
        self.personalityText = personalityText
        self.speechCharacteristics = speechCharacteristics
        self.userCallingName = userCallingName
        self.speechStyleText = speechStyleText
        self.relationshipStyle = relationshipStyle
        self.replyLengthPreference = replyLengthPreference
        self.memoryMemo = memoryMemo
        self.replyFrequencyPreference = replyFrequencyPreference
        self.avatarImageURL = avatarImageURL
        self.createdAt = createdAt
        self.totalInteractions = totalInteractions
        self.lastInteractionDate = lastInteractionDate
        self.isFollowingUser = isFollowingUser
        self.isFollowedByUser = isFollowedByUser
        self.isPublic = isPublic
        self.isCreatedByUser = isCreatedByUser
        self.followerCount = followerCount
        self.creatorId = creatorId
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case gender
        case appearanceDescription
        case backgroundStory
        case personalityText
        case speechCharacteristics
        case userCallingName
        case speechStyleText
        case relationshipStyle
        case replyLengthPreference
        case memoryMemo
        case replyFrequencyPreference
        case createdAt
        case totalInteractions
        case lastInteractionDate
        case avatarImageURL
        case isFollowingUser
        case isFollowedByUser
        case isPublic
        case isCreatedByUser
        case followerCount
        case creatorId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            name: try container.decode(String.self, forKey: .name),
            gender: try container.decodeIfPresent(Gender.self, forKey: .gender),
            appearanceDescription: try container.decodeIfPresent(String.self, forKey: .appearanceDescription) ?? "",
            backgroundStory: try container.decodeIfPresent(String.self, forKey: .backgroundStory) ?? "",
            personalityText: try container.decodeIfPresent(String.self, forKey: .personalityText) ?? "",
            speechCharacteristics: try container.decodeIfPresent(String.self, forKey: .speechCharacteristics) ?? "",
            userCallingName: try container.decodeIfPresent(String.self, forKey: .userCallingName) ?? "",
            speechStyleText: try container.decodeIfPresent(String.self, forKey: .speechStyleText) ?? "",
            relationshipStyle: try container.decodeIfPresent(String.self, forKey: .relationshipStyle),
            replyLengthPreference: try container.decodeIfPresent(String.self, forKey: .replyLengthPreference),
            memoryMemo: try container.decodeIfPresent(String.self, forKey: .memoryMemo),
            replyFrequencyPreference: try container.decodeIfPresent(String.self, forKey: .replyFrequencyPreference),
            avatarImageURL: try container.decodeIfPresent(String.self, forKey: .avatarImageURL),
            createdAt: try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date(),
            totalInteractions: try container.decodeIfPresent(Int.self, forKey: .totalInteractions) ?? 0,
            lastInteractionDate: try container.decodeIfPresent(Date.self, forKey: .lastInteractionDate),
            isFollowingUser: try container.decodeIfPresent(Bool.self, forKey: .isFollowingUser) ?? false,
            isFollowedByUser: try container.decodeIfPresent(Bool.self, forKey: .isFollowedByUser) ?? false,
            isPublic: try container.decodeIfPresent(Bool.self, forKey: .isPublic) ?? false,
            isCreatedByUser: try container.decodeIfPresent(Bool.self, forKey: .isCreatedByUser) ?? false,
            followerCount: try container.decodeIfPresent(Int.self, forKey: .followerCount) ?? 0,
            creatorId: try container.decodeIfPresent(String.self, forKey: .creatorId)
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(gender, forKey: .gender)
        try container.encode(appearanceDescription, forKey: .appearanceDescription)
        try container.encode(backgroundStory, forKey: .backgroundStory)
        try container.encode(personalityText, forKey: .personalityText)
        try container.encode(speechCharacteristics, forKey: .speechCharacteristics)
        try container.encode(userCallingName, forKey: .userCallingName)
        try container.encode(speechStyleText, forKey: .speechStyleText)
        try container.encodeIfPresent(relationshipStyle, forKey: .relationshipStyle)
        try container.encodeIfPresent(replyLengthPreference, forKey: .replyLengthPreference)
        try container.encodeIfPresent(memoryMemo, forKey: .memoryMemo)
        try container.encodeIfPresent(replyFrequencyPreference, forKey: .replyFrequencyPreference)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(totalInteractions, forKey: .totalInteractions)
        try container.encodeIfPresent(lastInteractionDate, forKey: .lastInteractionDate)
        try container.encodeIfPresent(avatarImageURL, forKey: .avatarImageURL)
        try container.encode(isFollowingUser, forKey: .isFollowingUser)
        try container.encode(isFollowedByUser, forKey: .isFollowedByUser)
        try container.encode(isPublic, forKey: .isPublic)
        try container.encode(isCreatedByUser, forKey: .isCreatedByUser)
        try container.encode(followerCount, forKey: .followerCount)
        try container.encodeIfPresent(creatorId, forKey: .creatorId)
    }
    
    mutating func increaseIntimacy(by amount: Int = 1) {
        totalInteractions += max(0, amount)
        lastInteractionDate = Date()
    }
}

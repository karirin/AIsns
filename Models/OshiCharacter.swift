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

struct OshiCharacter: Identifiable, Codable {
    let id: UUID
    var name: String
    var gender: Gender?
    var personality: PersonalityType
    var speechCharacteristics: String
    var userCallingName: String
    var speechStyle: SpeechStyle
    var createdAt: Date
    var totalInteractions: Int
    var lastInteractionDate: Date?
    var avatarImageURL: String?
    
    // UIImageに変換
    @MainActor
    var avatarImage: UIImage? {
        get async {
            guard let urlString = avatarImageURL else { return nil }
            return try? await FirebaseStorageManager.shared.downloadImage(from: urlString)
        }
    }
    
    // 親密度に応じた呼び方（既存のロジックは保持）
    var callingName: String {
        // カスタム呼び方が設定されていればそれを使用
        if !userCallingName.isEmpty {
            return userCallingName
        }
        return "\(name)さん"
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        gender: Gender? = nil,
        personality: PersonalityType,
        speechCharacteristics: String = "",
        userCallingName: String = "",
        speechStyle: SpeechStyle,
        avatarImageURL: String? = nil, // ← これを追加
        createdAt: Date = Date(),
        totalInteractions: Int = 0,
        lastInteractionDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.gender = gender
        self.personality = personality
        self.speechCharacteristics = speechCharacteristics
        self.userCallingName = userCallingName
        self.speechStyle = speechStyle
        self.avatarImageURL = avatarImageURL // ← これを追加
        self.createdAt = createdAt
        self.totalInteractions = totalInteractions
        self.lastInteractionDate = lastInteractionDate
    }
    
    mutating func increaseIntimacy(by amount: Int = 1) {
        totalInteractions += 1
        lastInteractionDate = Date()
    }
}

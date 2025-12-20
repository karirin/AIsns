import Foundation
import SwiftUI

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

enum RelationshipDistance: String, CaseIterable, Codable {
    case lover = "恋人寄り"
    case bestFriend = "親友"
    case fanAndIdol = "ファンと推し"
    
    var icon: String {
        switch self {
        case .lover: return "❤️"
        case .bestFriend: return "👥"
        case .fanAndIdol: return "⭐️"
        }
    }
}

enum WorldSetting: String, CaseIterable, Codable {
    case idol = "アイドル"
    case vtuber = "VTuber"
    case student = "学生"
    case worker = "社会人"
    case fantasy = "異世界"
    
    var icon: String {
        switch self {
        case .idol: return "🎤"
        case .vtuber: return "🎮"
        case .student: return "🎓"
        case .worker: return "💼"
        case .fantasy: return "🗡️"
        }
    }
}

struct OshiCharacter: Identifiable, Codable {
    let id: UUID
    var name: String
    var personality: PersonalityType
    var speechStyle: SpeechStyle
    var relationshipDistance: RelationshipDistance
    var worldSetting: WorldSetting
    var ngTopics: [String]
    var avatarColor: String // Color as hex string
    var createdAt: Date
    var intimacyLevel: Int // 0-100
    var totalInteractions: Int
    var lastInteractionDate: Date?
    
    // 親密度に応じた呼び方
    var callingName: String {
        if intimacyLevel < 20 {
            return "\(name)さん"
        } else if intimacyLevel < 50 {
            return name
        } else if intimacyLevel < 80 {
            return relationshipDistance == .lover ? "\(name)ちゃん" : name
        } else {
            return relationshipDistance == .lover ? "きみ" : name
        }
    }
    
    init(id: UUID = UUID(), name: String, personality: PersonalityType, 
         speechStyle: SpeechStyle, relationshipDistance: RelationshipDistance,
         worldSetting: WorldSetting, ngTopics: [String] = [], 
         avatarColor: String = "#FF6B9D") {
        self.id = id
        self.name = name
        self.personality = personality
        self.speechStyle = speechStyle
        self.relationshipDistance = relationshipDistance
        self.worldSetting = worldSetting
        self.ngTopics = ngTopics
        self.avatarColor = avatarColor
        self.createdAt = Date()
        self.intimacyLevel = 0
        self.totalInteractions = 0
        self.lastInteractionDate = nil
    }
    
    mutating func increaseIntimacy(by amount: Int = 1) {
        intimacyLevel = min(100, intimacyLevel + amount)
        totalInteractions += 1
        lastInteractionDate = Date()
    }
}

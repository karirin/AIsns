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
    var personalityText: String
    var speechCharacteristics: String
    var userCallingName: String
    var speechStyleText: String
    var createdAt: Date
    var totalInteractions: Int
    var lastInteractionDate: Date?
    var avatarImageURL: String?
    
    var isFollowingUser: Bool
    var isFollowedByUser: Bool
    var isPublic: Bool
    
    // 追加: フォロワー数
    var followerCount: Int
    
    var creatorId: String?
    
    var isMutualFollow: Bool {
        isFollowingUser && isFollowedByUser
    }

    @MainActor
    var avatarImage: UIImage? {
        get async {
            guard let urlString = avatarImageURL else { return nil }
            return try? await FirebaseStorageManager.shared.downloadImage(from: urlString)
        }
    }
    
    func callingName(userName: String) -> String {
        // 1. 推し個別の設定で「ユーザーの呼び方」が決まっている場合はそれを最優先
        if !userCallingName.isEmpty {
            return userCallingName
        }
        // 2. 個別の設定がない場合、アプリ全体のユーザープロフィール名があれば「〜さん」と呼ぶ
        if !userName.isEmpty {
            return "\(userName)さん"
        }
        // 3. どちらも空の場合は「あなた」と呼ぶ
        return "あなた"
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        gender: Gender? = nil,
        personalityText: String = "",
        speechCharacteristics: String = "",
        userCallingName: String = "",
        speechStyleText: String = "",
        avatarImageURL: String? = nil,
        createdAt: Date = Date(),
        totalInteractions: Int = 0,
        lastInteractionDate: Date? = nil,
        isFollowingUser: Bool = false,
        isFollowedByUser: Bool = false,
        isPublic: Bool = false,
        followerCount: Int = 0,
        creatorId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.gender = gender
        self.personalityText = personalityText
        self.speechCharacteristics = speechCharacteristics
        self.userCallingName = userCallingName
        self.speechStyleText = speechStyleText
        self.avatarImageURL = avatarImageURL
        self.createdAt = createdAt
        self.totalInteractions = totalInteractions
        self.lastInteractionDate = lastInteractionDate
        self.isFollowingUser = isFollowingUser
        self.isFollowedByUser = isFollowedByUser
        self.isPublic = isPublic
        self.followerCount = followerCount
        self.creatorId = creatorId
    }
    
    mutating func increaseIntimacy(by amount: Int = 1) {
        totalInteractions += 1
        lastInteractionDate = Date()
    }
}

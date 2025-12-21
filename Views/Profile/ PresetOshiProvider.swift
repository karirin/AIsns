//
//   PresetOshiProvider.swift
//  AIsns
//
//  Created by Apple on 2025/12/21.
//

import Foundation

enum PresetOshiProvider {
    static let recommended: [OshiCharacter] = [
        OshiCharacter(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            name: "レン",
            gender: .male,
            personality: .cool,
            speechCharacteristics: "短め、要点だけ。たまに照れ隠しで強がる。",
            userCallingName: "きみ",
            speechStyle: .casual,
            avatarImageURL: nil
        ),
        OshiCharacter(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            name: "ミオ",
            gender: .female,
            personality: .cool,
            speechCharacteristics: "寄り添い系。共感→提案の順で話す。",
            userCallingName: "あなた",
            speechStyle: .polite,
            avatarImageURL: nil
        )
        // ここに追加していく
    ]
}

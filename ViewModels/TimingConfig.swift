//
//  TimingConfig.swift
//  AIsns
//
//  Created by Apple on 2026/01/03.
//

import SwiftUI
// 開発中に調整しやすいよう、時間を管理する設定を作成
struct TimingConfig {
    // 開発モードかどうか（trueにすると全体的に爆速にする、などのロジックも組めます）
    static let isDebug = false

    struct Reaction {
        // 投稿してから最初の反応が来るまでの待機時間（秒）
        static let startDelayRange: ClosedRange<UInt64> = 60...300
        
        // 各キャラがいいねするまでの待機時間（秒）
        static let likeDelayRange: ClosedRange<UInt64> = 5...30
        
        // 各キャラがコメントするまでの待機時間（秒）
        static let commentDelayRange: ClosedRange<UInt64> = 10...300
    }
    
    struct Chat {
        // チャットの返信が来るまでの待機時間（秒）
        static let replyDelayRange: ClosedRange<UInt64> = 10...20
    }
    
    struct AutoEvent {
        // 自動フォローイベントの間隔（秒）
        static let followIntervalRange: ClosedRange<Double> = 300...1000
        
        // 自動投稿イベントの間隔（秒）
        static let postInterval: TimeInterval = 100.0
    }
    
    // 秒数をナノ秒に変換するヘルパー
    static func nanoseconds(_ range: ClosedRange<UInt64>) -> ClosedRange<UInt64> {
        if isDebug { return 1_000_000_000...3_000_000_000 } // デバッグ時は1~3秒に短縮
        return (range.lowerBound * 1_000_000_000)...(range.upperBound * 1_000_000_000)
    }
}

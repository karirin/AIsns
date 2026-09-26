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
    static let isDebug = _isDebugAssertConfiguration()

    struct Reaction {
        // 投稿してから最初の反応が来るまでの待機時間（秒）
        static let startDelayRange: ClosedRange<UInt64> = 2...8
        
        // 各キャラがいいねするまでの待機時間（秒）
        static let likeDelayRange: ClosedRange<UInt64> = 15...90
        static let plusLikeDelayRange: ClosedRange<UInt64> = 8...45
        
        // 各キャラがコメントするまでの待機時間（秒）
        static let commentDelayRange: ClosedRange<UInt64> = 120...1_200
        static let plusCommentDelayRange: ClosedRange<UInt64> = 60...600

        // ユーザーがAI投稿へコメントしてからAIが返信するまでの待機時間（秒）
        static let replyToUserCommentDelayRange: ClosedRange<UInt64> = 60...420
        static let plusReplyToUserCommentDelayRange: ClosedRange<UInt64> = 30...180
    }
    
    struct Chat {
        // チャットの返信が来るまでの待機時間（秒）
        static let replyDelayRange: ClosedRange<UInt64> = 1...5
        static let plusReplyDelayRange: ClosedRange<UInt64> = 1...3
    }
    
    struct AutoEvent {
        // 自動フォローイベントの間隔（秒）
        static let followIntervalRange: ClosedRange<Double> = 100...1000
        
        // 自動投稿イベントの間隔（秒）
        static let initialPostDelayRange: ClosedRange<Double> = 8...20
        static let plusInitialPostDelayRange: ClosedRange<Double> = 5...12
        static let postInterval: TimeInterval = 60.0
        static let postIntervalRange: ClosedRange<Double> = 45...150
        static let plusPostIntervalRange: ClosedRange<Double> = 25...90
    }
    
    // 秒数をナノ秒に変換するヘルパー
    static func nanoseconds(_ range: ClosedRange<UInt64>) -> ClosedRange<UInt64> {
        let effectiveRange = seconds(range)
        return (effectiveRange.lowerBound * 1_000_000_000)...(effectiveRange.upperBound * 1_000_000_000)
    }

    static func seconds(_ range: ClosedRange<UInt64>) -> ClosedRange<UInt64> {
        isDebug ? 1...3 : range
    }
}

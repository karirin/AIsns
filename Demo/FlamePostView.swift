//
//  FlamePostView.swift
//  AIsns
//
//  Created by Apple on 2026/01/30.
//

import SwiftUI

struct FlamePostView: View {
    @State private var postContent: String = ""
    @State private var isPosted: Bool = false
    @State private var showFlames: Bool = false
    @State private var replyCount: Int = 0
    @State private var repostCount: Int = 0
    @State private var likeCount: Int = 0
    @State private var viewCount: Int = 0
    @State private var angryReplies: [AngryReply] = []
    @State private var flameParticles: [FlameParticle1] = []
    @State private var shakeOffset: CGFloat = 0
    @State private var screenRedOverlay: Double = 0
    @State private var notificationCount: Int = 0
    
    var body: some View {
        ZStack {
            // 背景（白基調）
            Color(.systemBackground).ignoresSafeArea()
            
            // 炎上時の赤いオーバーレイ
            Color.red.opacity(screenRedOverlay * 0.15)
                .ignoresSafeArea()
                .allowsHitTesting(false)
            
            if !isPosted {
                composeView
            } else {
                flameView
            }
        }
    }
    
    // MARK: - 投稿入力画面
    private var composeView: some View {
        VStack(spacing: 0) {
            HStack {
                Button("キャンセル") { }
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text("新規投稿")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("投稿する") {
                    if !postContent.isEmpty {
                        withAnimation {
                            isPosted = true
                        }
                        startFlameAnimation()
                    }
                }
                .foregroundColor(postContent.isEmpty ? .gray : .blue)
                .fontWeight(.bold)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            Divider()
            
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text("🙂")
                            .font(.title2)
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("あなた")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    TextField("いまどうしてる？", text: $postContent, axis: .vertical)
                        .foregroundColor(.primary)
                        .lineLimit(5...10)
                }
            }
            .padding()
            
            Spacer()
        }
    }
    
    // MARK: - 炎上画面
    private var flameView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // ヘッダー
                HStack {
                    Button {
                        resetAll()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    Text("投稿")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // 通知バッジ
                    ZStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.primary)
                        
                        if notificationCount > 0 {
                            Text(notificationCount > 99 ? "99+" : "\(notificationCount)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 12, y: -8)
                        }
                    }
                }
                .padding()
                
                Divider()
                
                // 元の投稿
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 48, height: 48)
                            .overlay(Text("🙂").font(.title2))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("あなた")
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                Text("@you_user")
                                    .foregroundColor(.secondary)
                                Text("・たった今")
                                    .foregroundColor(.secondary)
                            }
                            .font(.subheadline)
                            
                            Text(postContent)
                                .foregroundColor(.primary)
                                .font(.body)
                        }
                    }
                    
                    // エンゲージメント
                    HStack(spacing: 32) {
                        engagementButton(icon: "bubble.left", count: replyCount, color: showFlames ? .orange : .secondary)
                        engagementButton(icon: "arrow.2.squarepath", count: repostCount, color: showFlames ? .red : .secondary)
                        engagementButton(icon: "heart", count: likeCount, color: showFlames ? .pink : .secondary)
                        engagementButton(icon: "chart.bar", count: viewCount, color: .secondary)
                    }
                    .padding(.top, 8)
                }
                .padding()
                .offset(x: shakeOffset)
                
                Divider()
                
                // 炎上リプライ
                if showFlames {
                    LazyVStack(spacing: 0) {
                        ForEach(angryReplies) { reply in
                            AngryReplyRow(reply: reply)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                    }
                }
                
                Spacer(minLength: 100)
            }
        }
    }
    
    private func engagementButton(icon: String, count: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            if count > 0 {
                Text(formatCount(count))
                    .font(.subheadline)
            }
        }
        .foregroundColor(color)
    }
    
    private func formatCount(_ count: Int) -> String {
        if count >= 10000 {
            return String(format: "%.1f万", Double(count) / 10000)
        } else if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000)
        }
        return "\(count)"
    }
    
    // MARK: - アニメーション
    private func startFlameAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                showFlames = true
            }
            startCounterAnimation()
            startReplyAnimation()
            startFlameParticles()
            startShakeAnimation()
        }
    }
    
    private func startCounterAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            withAnimation(.easeOut(duration: 0.1)) {
                replyCount += Int.random(in: 5...50)
                repostCount += Int.random(in: 10...100)
                likeCount += Int.random(in: 1...20)
                viewCount += Int.random(in: 100...1000)
                notificationCount += Int.random(in: 1...10)
                
                screenRedOverlay = min(1.0, screenRedOverlay + 0.02)
            }
            
            if replyCount > 50000 {
                timer.invalidate()
            }
        }
    }
    
    private func startReplyAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                let newReply = generateAngryReply()
                angryReplies.insert(newReply, at: 0)
                
                if angryReplies.count > 30 {
                    angryReplies.removeLast()
                }
            }
            
            if angryReplies.count >= 30 && replyCount > 30000 {
                timer.invalidate()
            }
        }
    }
    
    private func startFlameParticles() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            let particle = FlameParticle1(
                id: UUID(),
                emoji: ["🔥", "💢", "😡", "🤬", "💥", "⚡️"].randomElement()!,
                position: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: UIScreen.main.bounds.height + 50
                ),
                size: CGFloat.random(in: 20...50),
                opacity: 1.0
            )
            flameParticles.append(particle)
            
            withAnimation(.linear(duration: 2)) {
                if let index = flameParticles.firstIndex(where: { $0.id == particle.id }) {
                    flameParticles[index].position.y = -100
                    flameParticles[index].opacity = 0
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                flameParticles.removeAll { $0.id == particle.id }
            }
            
            if replyCount > 50000 {
                timer.invalidate()
            }
        }
    }
    
    private func startShakeAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            withAnimation(.linear(duration: 0.05)) {
                shakeOffset = CGFloat.random(in: -5...5)
            }
            
            if replyCount > 50000 {
                timer.invalidate()
                shakeOffset = 0
            }
        }
    }
    
    private func resetAll() {
        withAnimation {
            isPosted = false
            showFlames = false
            replyCount = 0
            repostCount = 0
            likeCount = 0
            viewCount = 0
            angryReplies = []
            flameParticles = []
            shakeOffset = 0
            screenRedOverlay = 0
            notificationCount = 0
            postContent = ""
        }
    }
    
    private func generateAngryReply() -> AngryReply {
        let replies = [
            "は？何言ってんの？",
            "これはさすがに草",
            "通報しました",
            "炎上案件きたああああ",
            "スクショ撮った",
            "まとめサイトに載りそう",
            "終わったな...",
            "社会的に終了のお知らせ",
            "これはアウトでしょ",
            "魚拓とったわ",
            "拡散希望",
            "うわぁ...",
            "ドン引きなんだけど",
            "ニュースになりそう",
            "謝罪まだ？",
            "会社にバレたら終わりだね",
            "これマジで言ってる？",
            "頭大丈夫？",
            "時代遅れすぎる",
            "常識を疑う",
            "さすがに引くわ",
            "トレンド入りおめでとう（皮肉）",
            "人生終了のカウントダウン開始",
            "もう手遅れだよ",
            "これは永久保存版",
        ]
        
        let usernames = [
            "正義マン", "炎上ウォッチャー", "まとめ民", "通報厨",
            "ネット警察", "鍵垢の人", "野次馬", "一般人A",
            "真実を追求する者", "常識人", "モラリスト", "批判者"
        ]
        
        return AngryReply(
            id: UUID(),
            username: usernames.randomElement()!,
            handle: "@user\(Int.random(in: 1000...9999))",
            content: replies.randomElement()!,
            likes: Int.random(in: 10...5000),
            retweets: Int.random(in: 5...1000)
        )
    }
    
    private var samplePosts: [String] {
        [
            "努力しない人は自己責任",
            "最近の若者は根性がない",
            "○○が好きな人とは仲良くなれない",
            "学歴ない人は努力不足",
            "貧乏なのは甘え",
        ]
    }
}

// MARK: - Models
struct AngryReply: Identifiable {
    let id: UUID
    let username: String
    let handle: String
    let content: String
    let likes: Int
    let retweets: Int
}

struct FlameParticle1: Identifiable {
    let id: UUID
    let emoji: String
    var position: CGPoint
    let size: CGFloat
    var opacity: Double
}

// MARK: - Reply Row
struct AngryReplyRow: View {
    let reply: AngryReply
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 40, height: 40)
                    .overlay(Text("😤").font(.title3))
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(reply.username)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text(reply.handle)
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)
                    
                    Text(reply.content)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 24) {
                        Label("\(reply.retweets)", systemImage: "arrow.2.squarepath")
                        Label("\(reply.likes)", systemImage: "heart")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                }
            }
            .padding()
            
            Divider()
        }
    }
}

#Preview {
    FlamePostView()
}

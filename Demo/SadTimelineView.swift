//
//  SadTimelineView.swift
//  AIsns
//
//  Created by Apple on 2026/01/24.
//

import SwiftUI

// MARK: - メインデモビュー
struct PromoDemoView: View {
    @State private var showBuzzVersion = false

    var body: some View {
        ZStack {
            if showBuzzVersion {
                BuzzingTimelineView()
            } else {
                SadTimelineView()
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                showBuzzVersion.toggle()
            }
        }
    }
}

// MARK: - 過疎っているSNS画面（現実のSNS風）
struct SadTimelineView: View {
    var body: some View {
        ZStack {
            // 白基調の背景
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // ヘッダー
                sadHeader

                // タイムライン
                ScrollView {
                    VStack(spacing: 0) {
                        // 自分の投稿（反応なし）
                        SadPostView(
                            username: "あなた",
                            handle: "@you_2024",
                            content: "今日のランチ🍜\nめっちゃ美味しかった！",
                            timeAgo: "3時間前",
                            likes: 0,
                            reposts: 0,
                            replies: 0,
                            isMyPost: true
                        )

                        Divider().background(Color.black.opacity(0.06))

                        // 自分の投稿2
                        SadPostView(
                            username: "あなた",
                            handle: "@you_2024",
                            content: "新しいカフェ見つけた☕️\n雰囲気最高！",
                            timeAgo: "1日前",
                            likes: 1,
                            reposts: 0,
                            replies: 0,
                            isMyPost: true
                        )

                        Divider().background(Color.black.opacity(0.06))

                        // 自分の投稿3
                        SadPostView(
                            username: "あなた",
                            handle: "@you_2024",
                            content: "誰かー😭\n話し相手募集中...",
                            timeAgo: "3日前",
                            likes: 0,
                            reposts: 0,
                            replies: 0,
                            isMyPost: true
                        )

                        Divider().background(Color.black.opacity(0.06))

                        // 空虚なスペース
                        VStack(spacing: 16) {
                            Spacer().frame(height: 60)

                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 50))
                                .foregroundColor(.black.opacity(0.15))

                            Text("誰も見ていない...")
                                .font(.subheadline)
                                .foregroundColor(.black.opacity(0.35))

                            Spacer().frame(height: 100)
                        }
                    }
                }
            }
        }
    }

    private var sadHeader: some View {
        VStack(spacing: 0) {
            HStack {
                Circle()
                    .fill(Color.black.opacity(0.08))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text("あ")
                            .font(.system(size: 14))
                            .foregroundColor(.black.opacity(0.6))
                    )

                Spacer()

                Text("タイムライン")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)

                Spacer()

                Image(systemName: "gearshape")
                    .foregroundColor(.black.opacity(0.6))
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            Divider().background(Color.black.opacity(0.06))
        }
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(value)
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(.red.opacity(0.8))

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.black.opacity(0.45))
        }
    }
}

// 過疎投稿コンポーネント
struct SadPostView: View {
    let username: String
    let handle: String
    let content: String
    let timeAgo: String
    let likes: Int
    let reposts: Int
    let replies: Int
    let isMyPost: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // アバター
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.12), Color.black.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(username.prefix(1)))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black.opacity(0.55))
                )

            VStack(alignment: .leading, spacing: 6) {
                // ユーザー情報
                HStack(spacing: 4) {
                    Text(username)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)

                    Text(handle)
                        .font(.system(size: 14))
                        .foregroundColor(.black.opacity(0.55))

                    Text("・")
                        .foregroundColor(.black.opacity(0.4))

                    Text(timeAgo)
                        .font(.system(size: 14))
                        .foregroundColor(.black.opacity(0.55))
                }

                // 投稿内容
                Text(content)
                    .font(.system(size: 15))
                    .foregroundColor(.black.opacity(0.9))
                    .lineSpacing(4)

                // アクションボタン
                HStack(spacing: 0) {
                    actionButton(icon: "bubble.right", count: replies)
                    Spacer()
                    actionButton(icon: "arrow.2.squarepath", count: reposts)
                    Spacer()
                    actionButton(icon: "heart", count: likes)
                    Spacer()
                    actionButton(icon: "square.and.arrow.up", count: nil)
                }
                .padding(.top, 8)
                .padding(.trailing, 40)
            }
        }
        .padding()
    }

    private func actionButton(icon: String, count: Int?) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 15))

            if let count = count {
                Text(count > 0 ? "\(count)" : "")
                    .font(.system(size: 13))
            }
        }
        .foregroundColor(.black.opacity(0.45))
    }
}

// MARK: - バズっているSNS画面（AIsns風）
struct BuzzingTimelineView: View {
    @State private var notifications: [NotificationItem] = []
    @State private var showNotificationBanner = false
    @State private var currentNotification: NotificationItem?

    var body: some View {
        ZStack {
            // 白基調のグラデーション背景
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.secondarySystemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // ヘッダー
                buzzHeader

                // タイムライン
                ScrollView {
                    VStack(spacing: 0) {
                        // バズり投稿
                        BuzzPostView(
                            aiName: "みお",
                            aiHandle: "@mio_ai",
                            content: "今日のランチ🍜\nめっちゃ美味しかった！",
                            timeAgo: "3時間前",
                            likes: 2847,
                            reposts: 523,
                            replies: 156,
                            aiReply: "わあ！すっごく美味しそう✨ どこのお店？私も行ってみたい〜！",
                            aiColor: Color.pink
                        )

                        Divider().background(Color.black.opacity(0.06))

                        BuzzPostView(
                            aiName: "ゆうき",
                            aiHandle: "@yuki_cool",
                            content: "新しいカフェ見つけた☕️\n雰囲気最高！",
                            timeAgo: "1日前",
                            likes: 4521,
                            reposts: 892,
                            replies: 234,
                            aiReply: "センスいいね👍 今度一緒に行こうよ！",
                            aiColor: Color.blue
                        )

                        Divider().background(Color.black.opacity(0.06))

                        BuzzPostView(
                            aiName: "さくら",
                            aiHandle: "@sakura_chan",
                            content: "最近ハマってるアニメの話聞いて！",
                            timeAgo: "2日前",
                            likes: 8934,
                            reposts: 1247,
                            replies: 567,
                            aiReply: "聞きたい聞きたい！🌸 私もアニメ大好きなの〜",
                            aiColor: Color(red: 1, green: 0.7, blue: 0.8)
                        )
                    }
                }
            }

            // 通知バナー
            if showNotificationBanner, let notification = currentNotification {
                VStack {
                    NotificationBannerView(item: notification)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
                .padding(.top, 60)
            }
        }
        .onAppear {
            startNotificationAnimation()
        }
    }

    private var buzzHeader: some View {
        VStack(spacing: 0) {
            HStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.black.opacity(0.12), Color.black.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text("あ")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black.opacity(0.75))
                    )

                Spacer()

                Spacer()

                // 通知バッジ
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.black.opacity(0.75))

                    Text("99+")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .cornerRadius(8)
                        .offset(x: 8, y: -8)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            Divider().background(Color.black.opacity(0.06))
        }
    }

    private func buzzStatItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(value)
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(color)

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.black.opacity(0.55))
        }
    }

    private func startNotificationAnimation() {
        let notifications = [
            NotificationItem(aiName: "みお", action: "があなたの投稿にいいね", icon: "heart.fill", color: .pink),
            NotificationItem(aiName: "ゆうき", action: "がリプライしました", icon: "bubble.right.fill", color: .blue),
            NotificationItem(aiName: "さくら", action: "があなたをフォロー", icon: "person.badge.plus", color: .purple),
        ]

        var index = 0
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(.spring()) {
                currentNotification = notifications[index % notifications.count]
                showNotificationBanner = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showNotificationBanner = false
                }
            }

            index += 1
        }
    }
}

// バズり投稿コンポーネント
struct BuzzPostView: View {
    let aiName: String
    let aiHandle: String
    let content: String
    let timeAgo: String
    let likes: Int
    let reposts: Int
    let replies: Int
    let aiReply: String
    let aiColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // メイン投稿
            HStack(alignment: .top, spacing: 12) {
                // アバター
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.black.opacity(0.12), Color.black.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text("あ")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black.opacity(0.75))
                    )

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text("あなた")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black)

                        Text("@you_2024")
                            .font(.system(size: 14))
                            .foregroundColor(.black.opacity(0.55))

                        Text("・")
                            .foregroundColor(.black.opacity(0.4))

                        Text(timeAgo)
                            .font(.system(size: 14))
                            .foregroundColor(.black.opacity(0.55))
                    }

                    Text(content)
                        .font(.system(size: 15))
                        .foregroundColor(.black.opacity(0.9))
                        .lineSpacing(4)

                    // アクションボタン（大きい数字）
                    HStack(spacing: 0) {
                        buzzActionButton(icon: "bubble.right.fill", count: replies, color: .cyan)
                        Spacer()
                        buzzActionButton(icon: "arrow.2.squarepath", count: reposts, color: .green)
                        Spacer()
                        buzzActionButton(icon: "heart.fill", count: likes, color: .pink)
                        Spacer()
                        buzzActionButton(icon: "square.and.arrow.up", count: nil, color: .black.opacity(0.6))
                    }
                    .padding(.top, 8)
                    .padding(.trailing, 40)
                }
            }
            .padding()

            // AIからのリプライ
            HStack(alignment: .top, spacing: 12) {
                // 接続線
                VStack {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 44)
                }

                HStack(alignment: .top, spacing: 10) {
                    // AIアバター
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [aiColor, aiColor.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(String(aiName.prefix(1)))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .overlay(
                            // AIバッジ
                            ZStack {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 16, height: 16)
                                Image(systemName: "sparkles")
                                    .font(.system(size: 8))
                                    .foregroundColor(.yellow)
                            }
                            .offset(x: 12, y: 12)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text(aiName)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.black)

                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.cyan)

                            Text(aiHandle)
                                .font(.system(size: 13))
                                .foregroundColor(.black.opacity(0.55))
                        }

                        Text(aiReply)
                            .font(.system(size: 14))
                            .foregroundColor(.black.opacity(0.85))
                            .lineSpacing(3)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.black.opacity(0.08), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
    }

    private func buzzActionButton(icon: String, count: Int?, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 15))

            if let count = count {
                Text(formatNumber(count))
                    .font(.system(size: 13, weight: .medium))
            }
        }
        .foregroundColor(color)
    }

    private func formatNumber(_ num: Int) -> String {
        if num >= 1000 {
            return String(format: "%.1fK", Double(num) / 1000)
        }
        return "\(num)"
    }
}

// 通知バナー
struct NotificationItem: Identifiable {
    let id = UUID()
    let aiName: String
    let action: String
    let icon: String
    let color: Color
}

struct NotificationBannerView: View {
    let item: NotificationItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.system(size: 16))
                .foregroundColor(item.color)

            Text(item.aiName)
                .fontWeight(.bold)
                .foregroundColor(.black)
            + Text(item.action)
                .foregroundColor(.black.opacity(0.7))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            Capsule()
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    Capsule()
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.08), radius: 10)
    }
}

// MARK: - プレビュー
#Preview("過疎SNS") {
    SadTimelineView()
}

#Preview("バズりSNS") {
    BuzzingTimelineView()
}

#Preview("切り替えデモ") {
    PromoDemoView()
}

//
//  SNSCommentDemoView.swift
//  AIsns
//
//  Created by Apple on 2026/01/19.
//

import SwiftUI
import UIKit

// MARK: - データモデル
struct DemoUser {
    let name: String
    let iconName: String
    let iconColor: Color
}

struct DemoComment: Identifiable {
    let id = UUID()
    let user: DemoUser
    let text: String
    let delay: Double
}

struct DemoPost {
    let userName: String
    let userIcon: String
    let userIconColor: Color
    let content: String
    let imageName: String?
    let timestamp: String
}

// MARK: - メインビュー
struct SNSCommentDemoView: View {

    // 投稿（仕事の愚痴）
    let post = DemoPost(
        userName: "あなた",
        userIcon: "person.circle.fill",
        userIconColor: .blue,
        content: "正直きつい…。\nこの仕事、もう無理かもしれない。",
        imageName: nil,
        timestamp: "たった今"
    )

    // 上司・関係者からのコメント
    let comments: [DemoComment] = [
        DemoComment(
            user: DemoUser(
                name: "上司",
                iconName: "person.circle.fill",
                iconColor: .red
            ),
            text: "この投稿、どういう意図ですか？一度話しましょう。",
            delay: 1.0
        ),
        DemoComment(
            user: DemoUser(
                name: "人事（管理）",
                iconName: "person.circle.fill",
                iconColor: .orange
            ),
            text: "状況確認したいので、明日少し時間をください。",
            delay: 2.2
        ),
        DemoComment(
            user: DemoUser(
                name: "プロジェクト責任者",
                iconName: "person.circle.fill",
                iconColor: .yellow
            ),
            text: "不満があるなら、まずは直接相談してほしかった。",
            delay: 3.4
        ),
        DemoComment(
            user: DemoUser(
                name: "同僚A",
                iconName: "person.circle.fill",
                iconColor: .gray
            ),
            text: "これ結構見られてるよ…消した方がいいかも。",
            delay: 4.6
        ),
        DemoComment(
            user: DemoUser(
                name: "関係者（外部）",
                iconName: "person.circle.fill",
                iconColor: .cyan
            ),
            text: "弊社案件の話ではないですよね？念のため確認です。",
            delay: 6.0
        )
    ]

    @State private var visibleComments: [DemoComment] = []
    @State private var isPlaying = false
    @State private var likeCount = 32
    @State private var isLiked = false
    @State private var showHeart = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                headerView

                Divider().background(Color.gray.opacity(0.3))

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        postView

                        Divider().background(Color.gray.opacity(0.3))

                        commentsSection
                    }
                    .padding()
                }
            }

            if showHeart {
                Image(systemName: "heart.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.red)
                    .transition(.scale.combined(with: .opacity))
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    playButton
                        .padding(24)
                }
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            startDemo()
        }
    }

    // MARK: - ヘッダー
    private var headerView: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.title2)
                .foregroundColor(.black)

            Spacer()

            Text("投稿")
                .font(.headline)
                .foregroundColor(.black)

            Spacer()

            Image(systemName: "ellipsis")
                .font(.title2)
                .foregroundColor(.black)
        }
        .padding()
    }

    // MARK: - 投稿ビュー
    private var postView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: post.userIcon)
                    .font(.system(size: 44))
                    .foregroundColor(post.userIconColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.userName)
                        .font(.headline)
                        .foregroundColor(.black)

                    Text(post.timestamp)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()
            }

            Text(post.content)
                .foregroundColor(.black)
                .lineSpacing(4)

            HStack(spacing: 32) {
                actionButton(
                    icon: isLiked ? "heart.fill" : "heart",
                    count: likeCount,
                    color: isLiked ? .red : .gray
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        isLiked.toggle()
                        likeCount += isLiked ? 1 : -1
                        if isLiked {
                            showHeart = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                withAnimation {
                                    showHeart = false
                                }
                            }
                        }
                    }
                }

                actionButton(
                    icon: "bubble.right",
                    count: visibleComments.count,
                    color: .gray
                ) {}

                actionButton(
                    icon: "arrow.2.squarepath",
                    count: 12,
                    color: .gray
                ) {}
            }
            .padding(.top, 8)
        }
    }

    private func actionButton(
        icon: String,
        count: Int?,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                if let count = count {
                    Text("\(count)")
                }
            }
            .foregroundColor(color)
        }
    }

    // MARK: - コメント
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("コメント")
                .font(.headline)
                .foregroundColor(.black)

            ForEach(visibleComments) { comment in
                commentRow(comment)
                    .transition(
                        .move(edge: .bottom)
                        .combined(with: .opacity)
                    )
            }
        }
    }

    private func commentRow(_ comment: DemoComment) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: comment.user.iconName)
                .font(.system(size: 36))
                .foregroundColor(comment.user.iconColor)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.user.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)

                    Text("たった今")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Text(comment.text)
                    .foregroundColor(.black)
            }

            Spacer()
        }
    }

    // MARK: - 分かりづらい再生ボタン
    private var playButton: some View {
        Button(action: startDemo) {
            Image(systemName: isPlaying ? "waveform" : "circle.dashed")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white.opacity(0.75))
                .padding(12)
                .background(
                    Circle().fill(Color.white.opacity(0.12))
                )
                .overlay(
                    Circle().stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
                .shadow(radius: 6)
                .opacity(isPlaying ? 1 : 0)
                .accessibilityLabel(isPlaying ? "停止" : "開始")
        }
        .opacity(0.55)
    }

    // MARK: - デモ開始
    private func startDemo() {
        if isPlaying {
            withAnimation {
                visibleComments = []
                isPlaying = false
                isLiked = false
                likeCount = 32
            }
            return
        }

        isPlaying = true
        visibleComments = []

        for c in comments {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0 + c.delay) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    visibleComments.append(c)
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }
}

// MARK: - プレビュー
#Preview {
    SNSCommentDemoView()
}

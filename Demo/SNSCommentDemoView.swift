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
    let timestamp: String
}

// MARK: - デモフェーズ
enum DemoPhase {
    case composing      // 投稿作成中
    case posted         // 投稿完了、コメント表示
}

// MARK: - メインビュー
struct SNSCommentDemoView: View {
    
    let comments: [DemoComment] = [
        DemoComment(
            user: DemoUser(name: "匿名", iconName: "person.circle.fill", iconColor: .gray),
            text: "よろしくされた覚えないし。いきなり距離感バグってない？",
            delay: 1.0
        ),
        DemoComment(
            user: DemoUser(name: "現実見よ", iconName: "person.circle.fill", iconColor: .pink),
            text: "『みんな』って誰のこと？身内ノリを外に持ち出すのやめな。",
            delay: 2.2
        ),
        DemoComment(
            user: DemoUser(name: "正論マン", iconName: "person.circle.fill", iconColor: .green),
            text: "よろしくって言う前に、まず自己紹介とか常識では？",
            delay: 3.4
        ),
        DemoComment(
            user: DemoUser(name: "草", iconName: "person.circle.fill", iconColor: .orange),
            text: "このテンションについていけない。初手それはきついw",
            delay: 4.6
        ),
        DemoComment(
            user: DemoUser(name: "通りすがり", iconName: "person.circle.fill", iconColor: .cyan),
            text: "こういう『よろしく』投稿する人、だいたい承認欲求強めで面倒なやつ。",
            delay: 6.0
        )
    ]
    
    @State private var phase: DemoPhase = .composing
    @State private var inputText = ""
    @State private var postedContent = ""
    @State private var visibleComments: [DemoComment] = []
    @State private var likeCount = 32
    @State private var isLiked = false
    @State private var showHeart = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                Divider().background(Color.gray.opacity(0.3))
                
                if phase == .composing {
                    composeView
                } else {
                    timelineView
                }
            }
            
            if showHeart {
                Image(systemName: "heart.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.red)
                    .transition(.scale.combined(with: .opacity))
            }
            
            // リセットボタン（投稿後のみ表示）
            if phase == .posted {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        resetButton
                            .padding(24)
                    }
                }
            }
        }
        .preferredColorScheme(.light)
        .onTapGesture {
            isTextFieldFocused = false
        }
    }
    
    // MARK: - ヘッダー
    private var headerView: some View {
        HStack {
            Button(action: { resetDemo() }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.black)
            }
            
            Spacer()
            
            Text(phase == .posted ? "投稿" : "新規投稿")
                .font(.headline)
                .foregroundColor(.black)
            
            Spacer()
            
            if phase == .composing {
                Button(action: { postMessage() }) {
                    Text("投稿する")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(
                                inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? Color.blue.opacity(0.5)
                                    : Color.blue
                            )
                        )
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } else {
                Image(systemName: "ellipsis")
                    .font(.title2)
                    .foregroundColor(.black)
            }
        }
        .padding()
    }
    
    // MARK: - 投稿作成画面
    private var composeView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("あなた")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    TextField("今なにしてる？", text: $inputText, axis: .vertical)
                        .foregroundColor(.black)
                        .focused($isTextFieldFocused)
                        .lineLimit(1...10)
                }
            }
            .padding()
            
            Spacer()
            
            // 下部ツールバー
            Divider()
            HStack(spacing: 24) {
                Image(systemName: "photo")
                Image(systemName: "camera")
                Image(systemName: "face.smiling")
                Image(systemName: "location")
                Spacer()
            }
            .font(.title2)
            .foregroundColor(.blue)
            .padding()
        }
    }
    
    // MARK: - タイムライン（投稿後）
    private var timelineView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                postView
                Divider().background(Color.gray.opacity(0.3))
                commentsSection
            }
            .padding()
        }
        .transition(.opacity)
    }
    
    // MARK: - 投稿ビュー
    private var postView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("あなた")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Text("たった今")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            Text(postedContent)
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
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation { showHeart = false }
                            }
                        }
                    }
                }
                
                actionButton(icon: "bubble.right", count: visibleComments.count, color: .gray) {}
                actionButton(icon: "arrow.2.squarepath", count: 12, color: .gray) {}
            }
            .padding(.top, 8)
        }
    }
    
    private func actionButton(icon: String, count: Int?, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                if let count = count { Text("\(count)") }
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
                    .transition(.move(edge: .bottom).combined(with: .opacity))
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
    
    // MARK: - リセットボタン
    private var resetButton: some View {
        Button(action: resetDemo) {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray.opacity(0.4))
                .padding(12)
                .background(Circle().fill(Color.gray.opacity(0.08)))
                .overlay(Circle().stroke(Color.gray.opacity(0.15), lineWidth: 1))
        }
        .opacity(0.6)
    }
    
    // MARK: - 投稿実行
    private func postMessage() {
        isTextFieldFocused = false
        postedContent = inputText
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.3)) {
            phase = .posted
        }
        
        // コメントを順次表示（投稿に対する返信として時間差で出す）
        for c in comments {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 + c.delay) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    visibleComments.append(c)
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }
    
    // MARK: - リセット
    private func resetDemo() {
        withAnimation {
            phase = .composing
            inputText = ""
            postedContent = ""
            visibleComments = []
            isLiked = false
            likeCount = 32
        }
    }
}

// MARK: - プレビュー
#Preview {
    SNSCommentDemoView()
}

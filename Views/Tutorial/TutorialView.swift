//
//  TutorialView.swift
//  AIsns
//
//  Created by Gemini
//

import SwiftUI

struct TutorialView: View {
    var onComplete: () -> Void
    @State private var currentPage = 0
    
    // アプリ共通のグラデーション
    private let appGradient = LinearGradient(
        colors: [
            Color(red: 0.2, green: 0.7, blue: 1.0),
            Color(red: 0.5, green: 0.4, blue: 1.0)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                TutorialPage(
                    imageName: "sparkles",
                    title: "AIとつながるSNS",
                    description: "アカウントとの新しいコミュニケーションを\n楽しみましょう。",
                    gradient: appGradient
                )
                .tag(0)
                
                TutorialPage(
                    imageName: "person.2.fill",
                    title: "アカウントを見つける",
                    description: "おすすめのキャラクターをフォローして\nタイムラインを賑やかに。",
                    gradient: appGradient
                )
                .tag(1)
                
                TutorialPage(
                    imageName: "message.bubble.fill", // SF Symbolsの名前を調整
                    title: "楽しく会話",
                    description: "チャットで話しかけると\nAIが返信してくれます。",
                    gradient: appGradient
                )
                .tag(2)
                
                TutorialPage(
                    imageName: "wand.and.stars",
                    title: "アカウントを作成",
                    description: "自分だけの理想のアカウントを\n作成することもできます。",
                    gradient: appGradient
                )
                .tag(3)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .animation(.easeInOut, value: currentPage)
            
            // 下部のボタンエリア
            VStack {
                Button(action: {
                    withAnimation {
                        if currentPage < 3 {
                            currentPage += 1
                        } else {
                            // 完了時のアクション実行（Hapticフィードバック付き）
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            onComplete()
                        }
                    }
                }) {
                    Text(currentPage < 3 ? "次へ" : "はじめる")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(appGradient)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                
                if currentPage < 3 {
                    Button(action: {
                        withAnimation {
                            onComplete()
                        }
                    }) {
                        Text("スキップ")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)
                } else {
                    // レイアウト調整用のダミー
                    Text("")
                        .font(.subheadline)
                        .padding(.bottom, 8)
                }
            }
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
    }
}

// チュートリアルの各ページ
struct TutorialPage: View {
    let imageName: String
    let title: String
    let description: String
    let gradient: LinearGradient
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(gradient.opacity(0.1))
                    .frame(width: 200, height: 200)
                
                Image(systemName: imageName)
                    .font(.system(size: 80))
                    .foregroundStyle(gradient)
            }
            
            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
}

#Preview {
    TutorialView(onComplete: {})
}

//
//  LaunchScreenView.swift
//  AIsns
//
//  Created: 2025/12/29
//  起動画面 - AIとつながる新しいSNS体験
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var isAnimating = false
    @State private var showMainApp = false
    
    var body: some View {
        ZStack {
            if showMainApp {
                MainTabView()
                    .transition(.opacity)
            } else {
                launchContent
                    .transition(.opacity)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private var launchContent: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.6, blue: 0.95),
                    Color(red: 0.4, green: 0.3, blue: 0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 動的な背景パーティクル
            GeometryReader { geometry in
                ForEach(0..<15, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(
                            width: CGFloat.random(in: 40...120),
                            height: CGFloat.random(in: 40...120)
                        )
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .blur(radius: 20)
                        .scaleEffect(isAnimating ? 1.3 : 0.8)
                        .opacity(isAnimating ? 0.3 : 0.1)
                        .animation(
                            .easeInOut(duration: Double.random(in: 2...4))
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...1)),
                            value: isAnimating
                        )
                }
            }
            
            // メインコンテンツ
            VStack(spacing: 0) {
                Spacer()
                
                // アイコン・ロゴエリア
                VStack(spacing: 24) {
                    // アイコン
                    ZStack {
                        // 外側の輝くリング
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.8),
                                        Color.white.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 130, height: 130)
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .opacity(isAnimating ? 0.6 : 1.0)
                            .animation(
                                .easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                        
                        // メインアイコン
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.95),
                                            Color.white.opacity(0.85)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 110, height: 110)
                                .shadow(
                                    color: .white.opacity(0.5),
                                    radius: 20,
                                    x: 0,
                                    y: 10
                                )
                            
                            // AI & SNS融合アイコン
                            VStack(spacing: -2) {
                                HStack(spacing: 2) {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.2, green: 0.7, blue: 1.0),
                                                    Color(red: 0.5, green: 0.4, blue: 1.0)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 20, height: 20)
                                        .scaleEffect(isAnimating ? 1.1 : 0.9)
                                    
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.5, green: 0.4, blue: 1.0),
                                                    Color(red: 0.7, green: 0.3, blue: 0.9)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 20, height: 20)
                                        .scaleEffect(isAnimating ? 0.9 : 1.1)
                                }
                                
                                HStack(spacing: 2) {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.3, green: 0.6, blue: 1.0),
                                                    Color(red: 0.6, green: 0.4, blue: 1.0)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 20, height: 20)
                                        .scaleEffect(isAnimating ? 0.9 : 1.1)
                                    
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.6, green: 0.3, blue: 1.0),
                                                    Color(red: 0.4, green: 0.5, blue: 1.0)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 20, height: 20)
                                        .scaleEffect(isAnimating ? 1.1 : 0.9)
                                }
                            }
                            .animation(
                                .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                        }
                    }
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .animation(
                        .spring(response: 1.0, dampingFraction: 0.6)
                        .delay(0.2),
                        value: isAnimating
                    )
                    
                    // アプリ名
                    VStack(spacing: 8) {
                        Text("AIsns")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .white.opacity(0.3), radius: 10, x: 0, y: 5)
                            .opacity(isAnimating ? 1.0 : 0.0)
                            .offset(y: isAnimating ? 0 : 20)
                            .animation(
                                .spring(response: 1.0, dampingFraction: 0.8)
                                .delay(0.4),
                                value: isAnimating
                            )
                        
                        Text("AIとつながる、新しいSNS")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .opacity(isAnimating ? 1.0 : 0.0)
                            .offset(y: isAnimating ? 0 : 20)
                            .animation(
                                .spring(response: 1.0, dampingFraction: 0.8)
                                .delay(0.6),
                                value: isAnimating
                            )
                    }
                }
                
                Spacer()
                
                // ローディングインジケーター
                VStack(spacing: 16) {
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.white.opacity(0.9))
                                .frame(width: 10, height: 10)
                                .scaleEffect(isAnimating ? 1.0 : 0.5)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                    value: isAnimating
                                )
                        }
                    }
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(
                        .easeInOut(duration: 0.5)
                        .delay(0.8),
                        value: isAnimating
                    )
                    
                    Text("読み込み中...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .animation(
                            .easeInOut(duration: 0.5)
                            .delay(1.0),
                            value: isAnimating
                        )
                }
                .padding(.bottom, 60)
            }
        }
    }
    
    private func startAnimation() {
        withAnimation {
            isAnimating = true
        }
        
        // 2.5秒後にメインアプリを表示
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                showMainApp = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    LaunchScreenView()
}

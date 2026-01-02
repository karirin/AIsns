//
//  LaunchScreenView.swift
//  AIsns
//
//  Updated: 2026/01/02 - Complete UI/UX Redesign
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var isAnimating = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var particleOpacity: Double = 0
    
    @State private var navigationState: NavigationState = .launch
    @AppStorage("hasSeenTutorial13") private var hasSeenTutorial: Bool = false
    
    enum NavigationState {
        case launch
        case onboarding
        case main
    }
    
    var body: some View {
        ZStack {
            switch navigationState {
            case .launch:
                launchContent
                    .transition(.opacity)
            case .onboarding:
                OnboardingFlowView {
                    finishOnboarding()
                }
                .transition(.opacity)
            case .main:
                MainTabView()
                    .transition(.opacity)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // ロゴアニメーション
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
            logoScale = 1.0
            logoOpacity = 1
        }
        
        // パーティクルアニメーション
        withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
            particleOpacity = 1
        }
        
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.5)) {
            isAnimating = true
        }
        
        // 画面遷移
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                if hasSeenTutorial {
                    navigationState = .main
                } else {
                    navigationState = .onboarding
                }
            }
        }
    }
    
    private func finishOnboarding() {
        withAnimation(.easeOut(duration: 0.5)) {
            hasSeenTutorial = true
            navigationState = .main
        }
    }
    
    // MARK: - Launch Content
    
    private var launchContent: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                colors: [
                    Color(hex: "0EA5E9"),
                    Color(hex: "6366F1"),
                    Color(hex: "8B5CF6")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 動的パーティクル
            GeometryReader { geometry in
                ForEach(0..<12, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(
                            width: CGFloat.random(in: 60...140),
                            height: CGFloat.random(in: 60...140)
                        )
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .blur(radius: 30)
                        .scaleEffect(isAnimating ? 1.2 : 0.9)
                        .opacity(particleOpacity * (isAnimating ? 0.3 : 0.15))
                        .animation(
                            .easeInOut(duration: Double.random(in: 2.5...4))
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...1.5)),
                            value: isAnimating
                        )
                }
            }
            
            // メインコンテンツ
            VStack(spacing: 0) {
                Spacer()
                
                // ロゴエリア
                VStack(spacing: DesignTokens.Spacing.xl) {
                    // アイコン
                    ZStack {
                        // 外側のリング
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 130, height: 130)
                            .scaleEffect(isAnimating ? 1.08 : 1.0)
                            .opacity(isAnimating ? 0.5 : 0.8)
                        
                        // 内側のグラデーション
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 110, height: 110)
                        
                        // アイコン
                        Image(systemName: "sparkles")
                            .font(.system(size: 50, weight: .medium))
                            .foregroundColor(.white)
                            .scaleEffect(isAnimating ? 1.05 : 1.0)
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    
                    // アプリ名
                    VStack(spacing: DesignTokens.Spacing.xs) {
                        Text("AIsns")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("AIとつながる、新しいSNS")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                }
                
                Spacer()
                
                // ローディングインジケーター
                VStack(spacing: DesignTokens.Spacing.md) {
                    // カスタムローディング
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                                .scaleEffect(isAnimating ? 1.0 : 0.5)
                                .opacity(isAnimating ? 1.0 : 0.3)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                    value: isAnimating
                                )
                        }
                    }
                    
                    Text("読み込み中...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .opacity(logoOpacity)
                .padding(.bottom, DesignTokens.Spacing.xxxxl)
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}

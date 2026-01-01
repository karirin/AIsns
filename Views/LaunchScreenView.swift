//
//  LaunchScreenView.swift
//  AIsns
//
//  Updated: 初回起動時のオンボーディングフロー対応
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var isAnimating = false
    
    // ✅ 画面遷移の状態管理
    @State private var navigationState: NavigationState = .launch
    
    // ✅ 初回起動フラグ（UserDefaultsに保存）
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial: Bool = false
    
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
                // ✅ 新しいオンボーディングフローを表示
                OnboardingFlowView {
                    finishOnboarding()
                }
                .transition(.opacity)
            case .main:
                // ✅ メインアプリ表示
                MainTabView()
                    .transition(.opacity)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        withAnimation {
            isAnimating = true
        }
        
        // 2.5秒後に次の画面へ判定
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
    
    // ✅ オンボーディング完了時の処理
    private func finishOnboarding() {
        withAnimation(.easeOut(duration: 0.5)) {
            hasSeenTutorial = true
            navigationState = .main
        }
    }
    
    // MARK: - Launch Screen Content (既存のデザイン)
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
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 3)
                            .frame(width: 130, height: 130)
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .opacity(isAnimating ? 0.6 : 1.0)
                            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
                        
                        Image(systemName: "sparkles") // 簡易アイコン（アセットが利用できない場合のフォールバック）
                             .font(.system(size: 60))
                             .foregroundColor(.white)
                    }
                    
                    // アプリ名
                    VStack(spacing: 8) {
                        Text("AIsns")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("AIとつながる、新しいSNS")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                
                Spacer()
                
                // ローディングインジケーター
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    
                    Text("読み込み中...")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 60)
            }
        }
    }
}

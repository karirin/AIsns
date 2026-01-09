//
//  SpotlightTutorialView.swift
//  AIsns
//
//  Created by Apple on 2026/01/07.
//  Fixed: 2026/01/08 - Corrected spotlight positioning
//

import SwiftUI

// MARK: - Spotlight Step Model

struct SpotlightStep: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let position: SpotlightPosition
    let tipPosition: TipPosition
    
    enum SpotlightPosition {
        case rect(CGRect)
        case circle(center: CGPoint, radius: CGFloat)
    }
    
    enum TipPosition {
        case above
        case below
        case left
        case right
    }
    
    static func == (lhs: SpotlightStep, rhs: SpotlightStep) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Spotlight Tutorial View

struct SpotlightTutorialView: View {
    let steps: [SpotlightStep]
    @Binding var currentStepIndex: Int
    @Binding var isShowing: Bool
    
    @State private var animateSpotlight = false
    @State private var animateTip = false
    
    private var currentStep: SpotlightStep? {
        guard currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex]
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 暗いオーバーレイ with スポットライト穴
                SpotlightOverlay(step: currentStep, animate: animateSpotlight)
                    .onTapGesture {
                        nextStep()
                    }
                
                // 説明カード
                if let step = currentStep {
                    tipCard(for: step, safeAreaTop: geometry.safeAreaInsets.top)
                        .opacity(animateTip ? 1 : 0)
                        .offset(y: animateTip ? 0 : 20)
                }
                
                // スキップボタン
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            generateHapticFeedback()
                            withAnimation(.easeOut(duration: 0.3)) {
                                isShowing = false
                            }
                        } label: {
                            Text("スキップ")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(20)
                        }
                        .padding(.trailing, 20)
                        .padding(.top, geometry.safeAreaInsets.top + 10)
                    }
                    Spacer()
                }
                
                // ページインジケーター
                VStack {
                    Spacer()
                    
                    HStack(spacing: 8) {
                        ForEach(0..<steps.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentStepIndex ? Color.white : Color.white.opacity(0.4))
                                .frame(width: 8, height: 8)
                                .scaleEffect(index == currentStepIndex ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3), value: currentStepIndex)
                        }
                    }
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                animateSpotlight = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                animateTip = true
            }
        }
        .onChange(of: currentStepIndex) { _ in
            animateTip = false
            withAnimation(.easeOut(duration: 0.3)) {
                animateSpotlight = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.15)) {
                animateTip = true
            }
        }
    }
    
    // MARK: - Tip Card
    
    private func tipCard(for step: SpotlightStep, safeAreaTop: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // タイトル
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FBBF24"), Color(hex: "F59E0B")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(step.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // 説明
            Text(step.description)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            
            // 次へボタン
            HStack {
                Spacer()
                
                Button {
                    nextStep()
                } label: {
                    HStack(spacing: 6) {
                        Text(currentStepIndex < steps.count - 1 ? "次へ" : "はじめる")
                            .font(.system(size: 15, weight: .semibold))
                        
                        Image(systemName: currentStepIndex < steps.count - 1 ? "arrow.right" : "checkmark")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(Color(hex: "1F2937"))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.95)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.2), radius: 8, y: 4)
                }
            }
            .padding(.top, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "6366F1").opacity(0.95),
                            Color(hex: "8B5CF6").opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.3), radius: 20, y: 10)
        )
        .frame(maxWidth: 320)
        .position(tipPosition(for: step, safeAreaTop: safeAreaTop))
    }
    
    private func tipPosition(for step: SpotlightStep, safeAreaTop: CGFloat) -> CGPoint {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let cardHeight: CGFloat = 180
        
        switch step.position {
        case .rect(let rect):
            switch step.tipPosition {
            case .above:
                return CGPoint(
                    x: screenWidth / 2,
                    y: max(rect.minY - cardHeight / 2 - 20, cardHeight / 2 + safeAreaTop + 50)
                )
            case .below:
                return CGPoint(
                    x: screenWidth / 2,
                    y: min(rect.maxY + cardHeight / 2 + 20, screenHeight - cardHeight / 2 - 100)
                )
            case .left, .right:
                return CGPoint(x: screenWidth / 2, y: screenHeight / 2)
            }
        case .circle(let center, let radius):
            switch step.tipPosition {
            case .above:
                return CGPoint(
                    x: screenWidth / 2,
                    y: max(center.y - radius - cardHeight / 2 - 20, cardHeight / 2 + safeAreaTop + 50)
                )
            case .below:
                return CGPoint(
                    x: screenWidth / 2,
                    y: min(center.y + radius + cardHeight / 2 + 20, screenHeight - cardHeight / 2 - 100)
                )
            case .left, .right:
                return CGPoint(x: screenWidth / 2, y: screenHeight / 2)
            }
        }
    }
    
    // MARK: - Actions
    
    private func nextStep() {
        generateHapticFeedback()
        
        if currentStepIndex < steps.count - 1 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentStepIndex += 1
            }
        } else {
            withAnimation(.easeOut(duration: 0.3)) {
                isShowing = false
            }
        }
    }
}

// MARK: - Spotlight Overlay

struct SpotlightOverlay: View {
    let step: SpotlightStep?
    let animate: Bool
    
    var body: some View {
        Canvas { context, size in
            // 暗い背景を描画
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(Color.black.opacity(0.75))
            )
            
            // スポットライト穴を切り抜き
            if let step = step {
                context.blendMode = .destinationOut
                
                switch step.position {
                case .rect(let rect):
                    let expandedRect = CGRect(
                        x: rect.minX - 8,
                        y: rect.minY - 8,
                        width: rect.width + 16,
                        height: rect.height + 16
                    )
                    let path = RoundedRectangle(cornerRadius: 16)
                        .path(in: expandedRect)
                    context.fill(path, with: .color(.white))
                    
                case .circle(let center, let radius):
                    let expandedRadius = radius + 12
                    let circleRect = CGRect(
                        x: center.x - expandedRadius,
                        y: center.y - expandedRadius,
                        width: expandedRadius * 2,
                        height: expandedRadius * 2
                    )
                    let path = Circle().path(in: circleRect)
                    context.fill(path, with: .color(.white))
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Spotlight Anchor Preference Key

struct SpotlightAnchorKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// MARK: - View Extension for Spotlight

extension View {
    func spotlightAnchor(_ id: String) -> some View {
        self.overlay(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        // グローバル座標を取得
                        let frame = geometry.frame(in: .global)
                        NotificationCenter.default.post(
                            name: .spotlightAnchorUpdated,
                            object: nil,
                            userInfo: ["id": id, "frame": frame]
                        )
                    }
                    .onChange(of: geometry.frame(in: .global)) { newFrame in
                        NotificationCenter.default.post(
                            name: .spotlightAnchorUpdated,
                            object: nil,
                            userInfo: ["id": id, "frame": newFrame]
                        )
                    }
            }
        )
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let spotlightAnchorUpdated = Notification.Name("spotlightAnchorUpdated")
}

// MARK: - Home Spotlight Tutorial Manager

class HomeSpotlightManager: ObservableObject {
    @Published var isShowing: Bool = false
    @Published var currentStepIndex: Int = 0
    @Published var steps: [SpotlightStep] = []
    
    private var hasInitializedSteps = false
    private var tutorialStarted = false
    private var anchors: [String: CGRect] = [:]
    private var cancellable: Any?
    private var stableCheckTimer: Timer?
    private var lastAnchors: [String: CGRect] = [:]
    private var stableCount = 0
    @AppStorage("hasSeenHomeSpotlightTutorial") private var hasSeenTutorialStored: Bool = false

    var hasSeenTutorial: Bool {
        get { hasSeenTutorialStored }
        set { hasSeenTutorialStored = newValue }
    }
    
    init() {
        
        // NotificationCenterを監視
        cancellable = NotificationCenter.default.addObserver(
            forName: .spotlightAnchorUpdated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let userInfo = notification.userInfo,
                  let id = userInfo["id"] as? String,
                  let frame = userInfo["frame"] as? CGRect else { return }
            
            self.anchors[id] = frame
            self.scheduleStabilityCheck()
        }
    }
    
    deinit {
        if let cancellable = cancellable {
            NotificationCenter.default.removeObserver(cancellable)
        }
        stableCheckTimer?.invalidate()
    }
    
    private func scheduleStabilityCheck() {
        // 既存のタイマーをキャンセル
        stableCheckTimer?.invalidate()
        
        // 座標が更新されなくなってから200ms後にチェック
        stableCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
            self?.checkAndUpdateSteps()
        }
    }
    
    private func checkAndUpdateSteps() {
        // すでにステップを初期化済み、またはチュートリアルを見た場合は更新しない
        guard !hasInitializedSteps && !hasSeenTutorial else { return }
        
        // 3つのアンカーが揃っているか確認
        guard anchors["profile_button"] != nil,
              anchors["tab_bar"] != nil,
              anchors["fab_button"] != nil else {
            print("⏳ Waiting for all anchors... (current: \(anchors.keys.joined(separator: ", ")))")
            return
        }
        
        // 座標が前回と同じかチェック（安定しているか）
        let anchorsAreSame = !lastAnchors.isEmpty &&
            anchors.keys.sorted() == lastAnchors.keys.sorted() &&
            anchors.allSatisfy { key, rect in
                guard let lastRect = lastAnchors[key] else { return false }
                return abs(rect.minX - lastRect.minX) < 1 &&
                       abs(rect.minY - lastRect.minY) < 1 &&
                       abs(rect.width - lastRect.width) < 1 &&
                       abs(rect.height - lastRect.height) < 1
            }
        
        if anchorsAreSame {
            stableCount += 1
            print("✓ Coordinates stable (count: \(stableCount))")
        } else {
            stableCount = 1  // 初回または変更があった場合は1からスタート
            lastAnchors = anchors
            print("📍 Coordinates updated, resetting stability count")
        }
        
        // 1回でも安定していれば（タイマーが発火した = 200ms間更新がなかった）
        updateStepsIfReady()
    }
    
    func startTutorialIfNeeded() {
        print("🎯 startTutorialIfNeeded called")
        print("  hasSeenTutorial: \(hasSeenTutorial)")
        print("  tutorialStarted: \(tutorialStarted)")
        
        // すでに見た場合は何もしない
        guard !hasSeenTutorial else {
            print("  ❌ Tutorial already seen, skipping")
            return
        }
        
        // すでに開始済みなら何もしない
        guard !tutorialStarted else {
            print("  ❌ Tutorial already started, skipping")
            return
        }
        
        tutorialStarted = true
        print("  ✅ Starting tutorial...")
        
        // 少し遅延させてから表示（画面が完全に表示されてから）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            print("  📍 Delayed check - steps: \(self.steps.count), isShowing: \(self.isShowing)")
            // ステップが準備できていて、まだ表示していない場合のみ表示
            if !self.steps.isEmpty && !self.isShowing {
                withAnimation(.easeOut(duration: 0.3)) {
                    self.isShowing = true
                }
                print("  🎬 Tutorial is now showing")
            }
        }
    }
    
    func completeTutorial() {
        print("🏁 completeTutorial called")
        hasSeenTutorial = true
        isShowing = false
        tutorialStarted = false
        print("  hasSeenTutorial set to: \(hasSeenTutorial)")
    }
    
    func resetTutorial() {
        hasSeenTutorial = false
        hasSeenTutorialStored = false
        currentStepIndex = 0
        hasInitializedSteps = false
        tutorialStarted = false
        steps = []
        anchors = [:]
        lastAnchors = [:]
        stableCount = 0
    }
    
    // ステップを更新（座標が確定してから）- 初回のみ
    private func updateStepsIfReady() {
        // すでにステップを初期化済み、またはチュートリアルを見た場合は更新しない
        guard !hasInitializedSteps && !hasSeenTutorial else { return }
        
        // デバッグ: 取得した座標を出力
        print("📍 Spotlight Anchors (stable):")
        for (key, rect) in anchors {
            print("  \(key): x=\(rect.minX), y=\(rect.minY), w=\(rect.width), h=\(rect.height)")
        }
        
        // 3つのアンカーが揃っているか確認
        guard let profileRect = anchors["profile_button"], profileRect.width > 0,
              let tabRect = anchors["tab_bar"], tabRect.height > 0,
              let fabRect = anchors["fab_button"], fabRect.width > 0 else {
            print("⚠️ Not all anchors ready yet")
            return
        }
        
        // 座標が有効かチェック（画面内にあるか）
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        // プロフィールボタンはヘッダー内にあるはず（Y座標が200未満）
        guard profileRect.midY < 200,
              profileRect.midX > 0 && profileRect.midX < screenWidth,
              tabRect.midX > 0 && tabRect.midX < screenWidth,
              tabRect.midY > 0 && tabRect.midY < 300,
              fabRect.midX > 0 && fabRect.midX < screenWidth,
              fabRect.midY > 0 && fabRect.midY < screenHeight else {
            print("⚠️ Coordinates are outside expected bounds, waiting...")
            return
        }
        
        print("✅ All anchors ready with valid coordinates, creating steps")
        
        // 初期化済みフラグを立てる
        hasInitializedSteps = true
        
        var newSteps: [SpotlightStep] = []
        
        // Step 1: プロフィールアイコン
        print("  Profile spotlight center: (\(profileRect.midX), \(profileRect.midY)), radius: \(profileRect.width / 2)")
        newSteps.append(SpotlightStep(
            id: "profile",
            title: "プロフィール & メニュー",
            description: "タップするとサイドメニューが開きます。\nプロフィール編集やフォロワー管理ができます。",
            position: .circle(center: CGPoint(x: profileRect.midX, y: profileRect.midY), radius: profileRect.width / 2 + 4),
            tipPosition: .below
        ))
        
        // Step 2: タブ切り替え
        print("  Tab bar spotlight rect: \(tabRect)")
        newSteps.append(SpotlightStep(
            id: "tabs",
            title: "タイムラインの切り替え",
            description: "「フォロー中」でフォローしているアカウントの投稿、\n「おすすめ」で人気の投稿を見られます。",
            position: .rect(tabRect),
            tipPosition: .below
        ))
        
        // Step 3: 投稿ボタン (FAB)
        print("  FAB spotlight center: (\(fabRect.midX), \(fabRect.midY)), radius: \(fabRect.width / 2)")
        newSteps.append(SpotlightStep(
            id: "post",
            title: "投稿を作成",
            description: "ここをタップして新しい投稿を作成しましょう！\nAIフォロワーがコメントしてくれます。",
            position: .circle(center: CGPoint(x: fabRect.midX, y: fabRect.midY), radius: fabRect.width / 2 + 4),
            tipPosition: .above
        ))
        
        self.steps = newSteps
        
        // ステップが準備できたら、tutorialStartedがtrueで待機中なら表示開始
        if tutorialStarted && !isShowing {
            withAnimation(.easeOut(duration: 0.3)) {
                self.isShowing = true
            }
        }
    }
    
    // PreferenceKey用のメソッド（後方互換性のため残す）
    func updateSteps(with anchors: [String: CGRect]) {
        for (key, value) in anchors {
            self.anchors[key] = value
        }
        scheduleStabilityCheck()
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.blue.opacity(0.3).ignoresSafeArea()
        
        SpotlightTutorialView(
            steps: [
                SpotlightStep(
                    id: "test1",
                    title: "テスト機能",
                    description: "これはテストの説明文です。\n複数行にも対応しています。",
                    position: .circle(center: CGPoint(x: 200, y: 200), radius: 30),
                    tipPosition: .below
                ),
                SpotlightStep(
                    id: "test2",
                    title: "次の機能",
                    description: "2つ目のステップです。",
                    position: .rect(CGRect(x: 50, y: 400, width: 300, height: 60)),
                    tipPosition: .below
                )
            ],
            currentStepIndex: .constant(0),
            isShowing: .constant(true)
        )
    }
}

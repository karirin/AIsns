//
//  OnboardingFlowView.swift
//  AIsns
//
//  Updated: 2026/01/06 - 簡単入力機能追加
//

import SwiftUI

struct OnboardingFlowView: View {
    var onComplete: () -> Void
    
    enum OnboardingStep {
        case intro
        case userSetup
        case oshiSetup
    }
    
    @State private var currentStep: OnboardingStep = .intro
    @StateObject private var viewModel = OshiViewModel()
    
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary.ignoresSafeArea()
            
            switch currentStep {
            case .intro:
                IntroSlideView {
                    withAnimation(DesignTokens.Animation.spring) {
                        currentStep = .userSetup
                    }
                }
                .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading)))
                
            case .userSetup:
                OnboardingUserSetupView {
                    withAnimation(DesignTokens.Animation.spring) {
                        currentStep = .oshiSetup
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                
            case .oshiSetup:
                OnboardingOshiSetupView(viewModel: viewModel) {
                    onComplete()
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            }
        }
        .onTapGesture {
            UIApplication.shared.endEditing()
        }
    }
}

// MARK: - Intro Slides

struct IntroSlideView: View {
    var onNext: () -> Void
    @State private var currentPage = 0
    
    private let slides: [(icon: String, title: String, description: String)] = [
        ("sparkles", "AIとつながるSNS", "AIフォロワーとの新しいコミュニケーションを\n楽しみましょう。"),
        ("person.2.fill", "自分だけのフォロワー", "理想のキャラクターを作成して\nあなただけのパートナーに。"),
        ("message.fill", "楽しく会話", "チャットや投稿で話しかけると\nAIが返信してくれます。")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(slides.enumerated()), id: \.offset) { index, slide in
                    introPage(icon: slide.icon, title: slide.title, description: slide.description)
                        .tag(index)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            // ボタンエリア
            VStack(spacing: DesignTokens.Spacing.md) {
                Button(action: {
                    generateHapticFeedback()
                    if currentPage < slides.count - 1 {
                        withAnimation(DesignTokens.Animation.spring) {
                            currentPage += 1
                        }
                    } else {
                        onNext()
                    }
                }) {
                    Text(currentPage < slides.count - 1 ? "次へ" : "はじめる")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignTokens.Spacing.md)
                        .background(AppColors.primaryGradientH)
                        .cornerRadius(DesignTokens.Radius.md)
                }
                
                if currentPage < slides.count - 1 {
                    Button(action: {
                        generateHapticFeedback()
                        onNext()
                    }) {
                        Text("スキップ")
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .padding(.bottom, DesignTokens.Spacing.xxl)
        }
    }
    
    private func introPage(icon: String, title: String, description: String) -> some View {
        VStack(spacing: DesignTokens.Spacing.xxl) {
            Spacer()
            
            // アイコン
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.primary.opacity(0.1),
                                AppColors.pink.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)
                
                Image(systemName: icon)
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(AppColors.primaryGradient)
            }
            
            VStack(spacing: DesignTokens.Spacing.md) {
                Text(title)
                    .font(AppTypography.title)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(description)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Spacer()
        }
        .padding(.horizontal, DesignTokens.Spacing.xl)
    }
}

// MARK: - User Setup

struct OnboardingUserSetupView: View {
    var onNext: () -> Void
    
    @State private var name: String = ""
    @State private var avatarImage: UIImage?
    @State private var showImagePicker = false
    @State private var isSaving = false
    @State private var avatarPulse = false
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()
            
            // タイトル
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("プロフィール設定")
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("あなたの名前とアイコンを設定してください。\n（後からいつでも変更できます）")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // アバター選択
            Button(action: {
                generateHapticFeedback()
                showImagePicker = true
            }) {
                ZStack {
                    // グロー効果
                    Circle()
                        .fill(AppColors.primaryGradient)
                        .frame(width: 130, height: 130)
                        .blur(radius: avatarPulse ? 18 : 14)
                        .opacity(avatarPulse ? 0.4 : 0.3)
                        .scaleEffect(avatarPulse ? 1.05 : 1.0)
                    
                    if let image = avatarImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(AppColors.primaryGradient, lineWidth: 3)
                            )
                    } else {
                        ZStack {
                            Circle()
                                .fill(AppColors.backgroundSecondary)
                                .frame(width: 120, height: 120)
                            
                            VStack(spacing: DesignTokens.Spacing.xs) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(AppColors.primaryGradient)
                                
                                Text("写真を追加")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                    }
                }
            }
            .pressableStyle()
            
            // 名前入力
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("名前")
                    .font(AppTypography.captionMedium)
                    .foregroundColor(AppColors.textSecondary)
                
                TextField("例: ゆう", text: $name)
                    .font(AppTypography.body)
                    .padding(DesignTokens.Spacing.md)
                    .background(AppColors.backgroundSecondary)
                    .cornerRadius(DesignTokens.Radius.md)
            }
            .padding(.horizontal, DesignTokens.Spacing.xxl)
            
            Spacer()
            
            // 次へボタン
            Button(action: saveAndNext) {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignTokens.Spacing.md)
                        .background(AppColors.primary.opacity(0.7))
                        .cornerRadius(DesignTokens.Radius.md)
                } else {
                    Text("次へ")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignTokens.Spacing.md)
                        .background(
                            name.isEmpty
                            ? LinearGradient(colors: [.gray.opacity(0.4)], startPoint: .leading, endPoint: .trailing)
                            : AppColors.primaryGradientH
                        )
                        .cornerRadius(DesignTokens.Radius.md)
                }
            }
            .disabled(name.isEmpty || isSaving)
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .padding(.bottom, DesignTokens.Spacing.xxl)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerWithCrop(selectedImage: $avatarImage)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                avatarPulse = true
            }
        }
    }
    
    private func saveAndNext() {
        guard !name.isEmpty else { return }
        isSaving = true
        
        Task {
            do {
                var imageURL: String? = nil
                if let image = avatarImage {
                    imageURL = try await FirebaseStorageManager.shared.uploadUserAvatar(
                        image,
                        userId: FirebaseConfig.shared.userId
                    )
                }
                
                try await FirebaseDatabaseManager.shared.saveUserProfile(
                    userName: name,
                    userBio: "",
                    avatarImageURL: imageURL
                )
                
                await MainActor.run {
                    isSaving = false
                    onNext()
                }
            } catch {
                print("Error saving user profile: \(error)")
                await MainActor.run {
                    isSaving = false
                    onNext()
                }
            }
        }
    }
}

// MARK: - Oshi Setup

struct OnboardingOshiSetupView: View {
    @ObservedObject var viewModel: OshiViewModel
    var onComplete: () -> Void
    
    @State private var name: String = ""
    @State private var personality: String = ""
    @State private var tone: String = ""
    @State private var avatarImage: UIImage?
    @State private var showImagePicker = false
    @State private var isProcessing = false
    
    // クイック入力の展開状態
    @State private var showPersonalityOptions = false
    @State private var showToneOptions = false
    
    // クイック入力オプション
    private let personalityOptions = ["優しい", "明るい", "クール", "天然", "しっかり者", "甘えん坊", "ツンデレ", "元気"]
    private let toneOptions = ["丁寧語", "タメ口", "関西弁", "方言", "クール", "フレンドリー", "敬語", "ギャル語"]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: DesignTokens.Spacing.lg) {
                Spacer(minLength: DesignTokens.Spacing.md)
                
                // タイトル
                VStack(spacing: DesignTokens.Spacing.xs) {
                    Text("最初のパートナーを選ぶ")
                        .font(AppTypography.title2)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("気になるキャラクターをフォローするか、\n自分だけのフォロワーを作成しましょう。")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                // おすすめプリセット
                if !viewModel.recommendedOshis.isEmpty {
                    presetSection
                } else if viewModel.isLoading {
                    LoadingView(message: "おすすめを読み込み中...")
                        .frame(height: 180)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 32))
                            .foregroundColor(.orange)
                        Text("おすすめアカウントが見つかりませんでした")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                        if let error = viewModel.errorMessage {
                            Text("エラー: \(error)")
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .background(AppColors.backgroundSecondary.opacity(0.5))
                    .cornerRadius(12)
                    .padding(.horizontal, DesignTokens.Spacing.xl)
                }
                
                // 区切り線
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(AppColors.borderLight)
                    Text("または新規作成")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(AppColors.borderLight)
                }
                .padding(.horizontal, DesignTokens.Spacing.xl)
                
                // カスタム作成フォーム
                customCreationForm
                
                Spacer(minLength: DesignTokens.Spacing.xxl)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerWithCrop(selectedImage: $avatarImage)
        }
    }
    
    // MARK: - Preset Section
    
    private var presetSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("おすすめのアカウント")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, DesignTokens.Spacing.xl)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(viewModel.recommendedOshis.prefix(4)) { oshi in
                        PresetOshiCard(oshi: oshi) {
                            selectPreset(oshi)
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.bottom, DesignTokens.Spacing.xs)
            }
        }
    }
    
    // MARK: - Custom Creation Form
    
    private var customCreationForm: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // アバター + 名前（横並び）
            HStack(spacing: 16) {
                // アバター選択
                Button(action: {
                    generateHapticFeedback()
                    showImagePicker = true
                }) {
                    if let image = avatarImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 72)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(AppColors.pinkGradient, lineWidth: 3)
                            )
                    } else {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "FEE2E2"), Color(hex: "FCE7F3")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 72, height: 72)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color(hex: "EC4899").opacity(0.3), lineWidth: 2)
                                )
                            
                            VStack(spacing: 2) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color(hex: "EC4899"))
                                Text("写真")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(Color(hex: "EC4899"))
                            }
                        }
                    }
                }
                .buttonStyle(ScaleButtonStyle())
                
                // 名前入力
                VStack(alignment: .leading, spacing: 6) {
                    Text("フォロワーの名前")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "6B7280"))
                    
                    TextField("例: レン", text: $name)
                        .font(.system(size: 16, weight: .medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "F3F4F6"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(
                                            name.isEmpty ? Color.clear : Color(hex: "EC4899").opacity(0.4),
                                            lineWidth: 1.5
                                        )
                                )
                        )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
            )
            .padding(.horizontal, DesignTokens.Spacing.xl)
            
            // 性格入力カード
            compactInputCard(
                icon: "heart.fill",
                iconColor: Color(hex: "EF4444"),
                label: "性格",
                placeholder: "優しい、明るい、ツンデレ など",
                text: $personality,
                options: personalityOptions,
                isExpanded: $showPersonalityOptions
            )
            .padding(.horizontal, DesignTokens.Spacing.xl)
            
            // 口調入力カード
            compactInputCard(
                icon: "text.bubble.fill",
                iconColor: Color(hex: "10B981"),
                label: "口調",
                placeholder: "丁寧語、タメ口、方言 など",
                text: $tone,
                options: toneOptions,
                isExpanded: $showToneOptions
            )
            .padding(.horizontal, DesignTokens.Spacing.xl)
            
            // 作成ボタン
            Button(action: createCustomOshi) {
                if isProcessing {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignTokens.Spacing.md)
                        .background(AppColors.pink.opacity(0.7))
                        .cornerRadius(DesignTokens.Radius.md)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("作成してはじめる")
                            .font(AppTypography.bodyMedium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignTokens.Spacing.md)
                    .background(
                        name.isEmpty
                        ? LinearGradient(colors: [.gray.opacity(0.4)], startPoint: .leading, endPoint: .trailing)
                        : AppColors.pinkGradient
                    )
                    .cornerRadius(DesignTokens.Radius.md)
                }
            }
            .disabled(name.isEmpty || isProcessing)
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .padding(.top, DesignTokens.Spacing.xs)
        }
    }
    
    // MARK: - コンパクト入力カード
    private func compactInputCard(
        icon: String,
        iconColor: Color,
        label: String,
        placeholder: String,
        text: Binding<String>,
        options: [String],
        isExpanded: Binding<Bool>
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // ヘッダー
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(iconColor.opacity(0.12)))
                
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "374151"))
                
                Spacer()
                
                // 簡単入力ボタン
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.wrappedValue.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10, weight: .semibold))
                        Text("簡単入力")
                            .font(.system(size: 11, weight: .semibold))
                        Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .foregroundColor(Color(hex: "EC4899"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(Color(hex: "EC4899").opacity(0.1))
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            // テキスト入力
            TextField(placeholder, text: text)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "374151"))
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "F9FAFB"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(
                                    text.wrappedValue.isEmpty ? Color(hex: "E5E7EB") : iconColor.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                )
            
            // クイック入力オプション
            if isExpanded.wrappedValue {
                OnboardingFlowLayout(spacing: 6) {
                    ForEach(options, id: \.self) { option in
                        OnboardingQuickInputTag(
                            text: option,
                            isSelected: text.wrappedValue.contains(option),
                            color: iconColor
                        ) {
                            appendToText(option, to: text)
                        }
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
        )
    }
    
    // MARK: - テキスト追加ヘルパー
    private func appendToText(_ option: String, to text: Binding<String>) {
        generateHapticFeedback()
        
        if text.wrappedValue.isEmpty {
            text.wrappedValue = option
        } else if text.wrappedValue.contains(option) {
            let patterns = ["\(option)、", "、\(option)", option]
            for pattern in patterns {
                if text.wrappedValue.contains(pattern) {
                    text.wrappedValue = text.wrappedValue.replacingOccurrences(of: pattern, with: "")
                    break
                }
            }
            text.wrappedValue = text.wrappedValue.trimmingCharacters(in: CharacterSet(charactersIn: "、 "))
        } else {
            text.wrappedValue += "、\(option)"
        }
    }
    
    // MARK: - Actions
    
    private func selectPreset(_ oshi: OshiCharacter) {
        guard !isProcessing else { return }
        isProcessing = true
        generateHapticFeedback()
        
        Task {
            await viewModel.followRecommended(oshi)
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            await MainActor.run {
                isProcessing = false
                onComplete()
            }
        }
    }
    
    private func createCustomOshi() {
        guard !name.isEmpty else { return }
        isProcessing = true
        generateHapticFeedback()
        
        Task {
            var newOshi = OshiCharacter(
                name: name,
                personalityText: personality,
                speechCharacteristics: "",
                userCallingName: "",
                speechStyleText: tone
            )
            
            if let image = avatarImage {
                do {
                    let url = try await FirebaseStorageManager.shared.uploadOshiAvatar(image, oshiId: newOshi.id)
                    newOshi.avatarImageURL = url
                } catch {
                    print("Image upload failed: \(error)")
                }
            }
            
            viewModel.addOshi(newOshi)
            
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            await MainActor.run {
                isProcessing = false
                onComplete()
            }
        }
    }
}

// MARK: - Onboarding用FlowLayout（名前衝突回避）

struct OnboardingFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
                
                self.size.width = max(self.size.width, currentX - spacing)
            }
            
            self.size.height = currentY + lineHeight
        }
    }
}

// MARK: - Onboarding用QuickInputTag（名前衝突回避）

struct OnboardingQuickInputTag: View {
    let text: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? color : color.opacity(0.1))
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Preset Oshi Card

struct PresetOshiCard: View {
    let oshi: OshiCharacter
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: DesignTokens.Spacing.sm) {
                // アイコン
                AsyncAvatarView(
                    imageURL: oshi.avatarImageURL,
                    name: oshi.name,
                    size: 72,
                    placeholderGradient: AppColors.pinkGradient
                )
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                VStack(spacing: DesignTokens.Spacing.xxs) {
                    Text(oshi.name)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)
                    
                    Text(oshi.personalityText)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(height: 32)
                }
                
                Text("フォローする")
                    .font(AppTypography.captionMedium)
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, DesignTokens.Spacing.xs)
                    .background(AppColors.primaryGradientH)
                    .cornerRadius(DesignTokens.Radius.full)
            }
            .padding(DesignTokens.Spacing.md)
            .frame(width: 150, height: 200)
            .background(AppColors.backgroundPrimary)
            .cornerRadius(DesignTokens.Radius.lg)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .stroke(AppColors.borderLight, lineWidth: 1)
            )
        }
        .pressableStyle()
    }
}

// MARK: - Scale Button Style (Legacy Support)

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(DesignTokens.Animation.fast, value: configuration.isPressed)
    }
}

// MARK: - Sized Box (Legacy Support)

struct SizedBox: View {
    let height: CGFloat
    var body: some View {
        Spacer().frame(height: height)
    }
}

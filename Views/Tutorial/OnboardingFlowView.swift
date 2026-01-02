//
//  OnboardingFlowView.swift
//  AIsns
//
//  Updated: 2026/01/02 - Complete UI/UX Redesign
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
    @State private var avatarPulse = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: DesignTokens.Spacing.xl) {
                Spacer(minLength: DesignTokens.Spacing.lg)
                
                // タイトル
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Text("最初のパートナーを選ぶ")
                        .font(AppTypography.title2)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("気になるキャラクターをフォローするか、\n自分だけの推しを作成しましょう。")
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
                
                Spacer(minLength: DesignTokens.Spacing.xxxl)
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
            // アバター選択
            Button(action: {
                generateHapticFeedback()
                showImagePicker = true
            }) {
                ZStack {
                    Circle()
                        .fill(AppColors.pinkGradient)
                        .frame(width: 110, height: 110)
                        .blur(radius: avatarPulse ? 16 : 12)
                        .opacity(avatarPulse ? 0.4 : 0.3)
                        .scaleEffect(avatarPulse ? 1.05 : 1.0)
                    
                    if let image = avatarImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(AppColors.pinkGradient, lineWidth: 3)
                            )
                    } else {
                        ZStack {
                            Circle()
                                .fill(AppColors.pinkGradient)
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "camera.fill")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .pressableStyle()
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    avatarPulse = true
                }
            }
            
            // 入力フィールド
            VStack(spacing: DesignTokens.Spacing.sm) {
                inputField(title: "推しの名前", placeholder: "例: レン", text: $name)
                inputField(title: "性格", placeholder: "例: 優しくて甘えん坊", text: $personality)
                inputField(title: "口調", placeholder: "例: タメ口、語尾に「〜だよ」", text: $tone)
            }
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
                    Text("作成してはじめる")
                        .font(AppTypography.bodyMedium)
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
    
    private func inputField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
            Text(title)
                .font(AppTypography.captionMedium)
                .foregroundColor(AppColors.textSecondary)
            
            TextField(placeholder, text: text)
                .font(AppTypography.body)
                .padding(DesignTokens.Spacing.sm)
                .background(AppColors.backgroundSecondary)
                .cornerRadius(DesignTokens.Radius.sm)
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

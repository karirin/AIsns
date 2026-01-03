//
//  OshiProfileEditView.swift
//  AIsns
//
//  Updated: 2025/12/29 - Premium UI/UX Redesign
//

import SwiftUI

struct OshiProfileEditView: View {
    let oshi: OshiCharacter
    @ObservedObject var viewModel: OshiViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String
    @State private var gender: Gender?
    @State private var personalityText: String
    @State private var speechCharacteristics: String
    @State private var userCallingName: String
    @State private var speechStyleText: String
    @State private var avatarImage: UIImage?
    @State private var showingSaveConfirmation = false
    @State private var showingImagePicker = false
    @State private var isLoadingImage = false
    
    // アニメーション用State
    @State private var appearAnimation = false
    @State private var avatarPulse = false
    @State private var isSaving = false
    
    // プリセットフラグ
    let isPreset: Bool
    
    // カラーテーマ（CreationViewと統一）
    private let accentGradient = LinearGradient(
        colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6"), Color(hex: "A855F7")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    private let softGradient = LinearGradient(
        colors: [Color(hex: "F0F4FF"), Color(hex: "FAF5FF")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    private let cardGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.9),
            Color.white.opacity(0.7)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    init(oshi: OshiCharacter, viewModel: OshiViewModel, isPreset: Bool = false) {
        self.oshi = oshi
        self.viewModel = viewModel
        self.isPreset = isPreset
        
        _name = State(initialValue: oshi.name)
        _gender = State(initialValue: oshi.gender)
        _personalityText = State(initialValue: oshi.personalityText)
        _speechCharacteristics = State(initialValue: oshi.speechCharacteristics)
        _userCallingName = State(initialValue: oshi.userCallingName)
        _speechStyleText = State(initialValue: oshi.speechStyleText)
        _avatarImage = State(initialValue: nil)
        _showingSaveConfirmation = State(initialValue: false)
        _showingImagePicker = State(initialValue: false)
        _isLoadingImage = State(initialValue: false)
        
        print("📝 OshiProfileEditView init")
        print("  - oshi.name: \(oshi.name)")
        print("  - isPreset: \(isPreset)")
    }
    
    var body: some View {
        ZStack {
            // 背景レイヤー
            backgroundLayer
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // ヘッダーカード（プロフィール画像 + 名前）
                    headerCard
                        .offset(y: appearAnimation ? 0 : 30)
                        .opacity(appearAnimation ? 1 : 0)
                    
                    // 基本設定セクション
                    basicSettingsSection
                        .offset(y: appearAnimation ? 0 : 40)
                        .opacity(appearAnimation ? 1 : 0)
                    
                    // キャラクター設定セクション
                    characterSettingsSection
                        .offset(y: appearAnimation ? 0 : 50)
                        .opacity(appearAnimation ? 1 : 0)
                    
                    // ユーザーとの関係セクション
                    relationshipSection
                        .offset(y: appearAnimation ? 0 : 60)
                        .opacity(appearAnimation ? 1 : 0)
                    
                    Spacer(minLength: 40)
                }
                .padding(.bottom, 40)
            }
            
            // 成功トースト
            if showingSaveConfirmation {
                successToast
            }
        }
        .onTapGesture {
            UIApplication.shared.endEditing()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("プロフィール編集")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(hex: "1F2937"))
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    generateHapticFeedback()
                    saveChanges()
                } label: {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "6366F1")))
                            .scaleEffect(0.8)
                    } else {
                        Text("保存")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(accentGradient)
                    }
                }
                .disabled(isSaving)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerWithCrop(selectedImage: $avatarImage)
        }
        .task {
            if let urlString = oshi.avatarImageURL, avatarImage == nil {
                isLoadingImage = true
                avatarImage = try? await FirebaseStorageManager.shared.downloadImage(from: urlString)
                isLoadingImage = false
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                appearAnimation = true
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                avatarPulse = true
            }
        }
    }
    
    // MARK: - 背景レイヤー
    private var backgroundLayer: some View {
        ZStack {
            softGradient
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "6366F1").opacity(0.15),
                                Color(hex: "6366F1").opacity(0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: geometry.size.width * 0.6
                        )
                    )
                    .frame(width: geometry.size.width * 1.2, height: geometry.size.width * 1.2)
                    .position(x: geometry.size.width * 0.8, y: -geometry.size.width * 0.3)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "A855F7").opacity(0.12),
                                Color(hex: "A855F7").opacity(0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: geometry.size.width * 0.5
                        )
                    )
                    .frame(width: geometry.size.width * 1.0, height: geometry.size.width * 1.0)
                    .position(x: geometry.size.width * 0.1, y: geometry.size.height * 0.85)
            }
            .ignoresSafeArea()
        }
    }
    
    // MARK: - ヘッダーカード
    private var headerCard: some View {
        VStack(spacing: 20) {
            // プロフィール画像
            avatarSection
            
            // 名前入力
            nameInputSection
        }
        .padding(24)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 28)
                    .fill(cardGradient)
                
                RoundedRectangle(cornerRadius: 28)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: Color(hex: "6366F1").opacity(0.08), radius: 20, y: 10)
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
    
    // MARK: - アバターセクション
    private var avatarSection: some View {
        Button(action: {
            generateHapticFeedback()
            showingImagePicker = true
        }) {
            ZStack {
                // 外側のグロー効果
                Circle()
                    .fill(accentGradient)
                    .frame(width: 134, height: 134)
                    .blur(radius: avatarPulse ? 20 : 15)
                    .opacity(avatarPulse ? 0.4 : 0.3)
                    .scaleEffect(avatarPulse ? 1.05 : 1.0)
                
                if isLoadingImage {
                    loadingAvatarView
                } else if let avatarImage = avatarImage {
                    existingAvatarView(avatarImage)
                } else {
                    initialAvatarView
                }
                
                // 編集バッジ
                editBadge
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var loadingAvatarView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "F0F4FF"), Color(hex: "FAF5FF")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "6366F1")))
                .scaleEffect(1.2)
        }
    }
    
    private func existingAvatarView(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 120, height: 120)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .strokeBorder(accentGradient, lineWidth: 4)
            )
            .shadow(color: Color(hex: "6366F1").opacity(0.3), radius: 15, y: 8)
    }
    
    private var initialAvatarView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "6366F1"), Color(hex: "A855F7")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 2)
                )
            
            Text(String(name.prefix(1).isEmpty ? "?" : name.prefix(1)))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .shadow(color: Color(hex: "6366F1").opacity(0.4), radius: 15, y: 8)
    }
    
    private var editBadge: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 36, height: 36)
                        .shadow(color: Color.black.opacity(0.15), radius: 8, y: 4)
                    
                    Circle()
                        .fill(accentGradient)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "camera.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .offset(x: -4, y: -4)
            }
        }
        .frame(width: 120, height: 120)
    }
    
    // MARK: - 名前入力セクション
    private var nameInputSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sparkle")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(accentGradient)
                
                Text("フォロワーの名前")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "374151"))
            }
            
            TextField("名前を入力", text: $name)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: "F9FAFB"))
                        
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                name.isEmpty
                                    ? Color(hex: "E5E7EB")
                                    : Color(hex: "6366F1").opacity(0.5),
                                lineWidth: 1.5
                            )
                    }
                )
                .animation(.easeInOut(duration: 0.2), value: name.isEmpty)
        }
    }
    
    // MARK: - 基本設定セクション
    private var basicSettingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            ModernSectionHeader(title: "基本設定", icon: "person.fill", color: Color(hex: "6366F1"))
            
            NavigationLink {
                ModernGenderSelectionView(selectedGender: $gender)
            } label: {
                GlassSettingRow(
                    icon: "figure.dress.line.vertical.figure",
                    iconColor: Color(hex: "EC4899"),
                    label: "性別",
                    value: gender?.rawValue ?? "未設定"
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - キャラクター設定セクション
    private var characterSettingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            ModernSectionHeader(title: "キャラクター設定", icon: "sparkles", color: Color(hex: "8B5CF6"))
            
            VStack(spacing: 2) {
                NavigationLink {
                    ModernFreeTextEditView(
                        title: "性格",
                        placeholder: "優しい、明るい、ツンデレ など",
                        text: $personalityText,
                        iconColor: Color(hex: "EF4444")
                    )
                } label: {
                    GlassSettingRow(
                        icon: "heart.fill",
                        iconColor: Color(hex: "EF4444"),
                        label: "性格",
                        value: personalityText.isEmpty ? "未設定" : personalityText,
                        position: .top
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                
                NavigationLink {
                    ModernFreeTextEditView(
                        title: "話し方の特徴",
                        placeholder: "柔らかい口調、元気いっぱい など",
                        text: $speechCharacteristics,
                        iconColor: Color(hex: "3B82F6")
                    )
                } label: {
                    GlassSettingRow(
                        icon: "bubble.left.fill",
                        iconColor: Color(hex: "3B82F6"),
                        label: "話し方の特徴",
                        value: speechCharacteristics.isEmpty ? "未設定" : speechCharacteristics,
                        position: .middle
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                
                NavigationLink {
                    ModernFreeTextEditView(
                        title: "口調",
                        placeholder: "丁寧、タメ口、方言 など",
                        text: $speechStyleText,
                        iconColor: Color(hex: "10B981")
                    )
                } label: {
                    GlassSettingRow(
                        icon: "text.bubble.fill",
                        iconColor: Color(hex: "10B981"),
                        label: "口調",
                        value: speechStyleText.isEmpty ? "未設定" : speechStyleText,
                        position: .bottom
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - ユーザーとの関係セクション
    private var relationshipSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            ModernSectionHeader(title: "ユーザーとの関係", icon: "person.2.fill", color: Color(hex: "F59E0B"))
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "FEF3C7"))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "at")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "F59E0B"))
                    }
                    
                    Text("あなたへの呼び方")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "374151"))
                }
                
                TextField("例: あなた、きみ", text: $userCallingName)
                    .font(.system(size: 16, weight: .medium))
                    .padding(16)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(hex: "F9FAFB"))
                            
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(
                                    userCallingName.isEmpty
                                        ? Color(hex: "E5E7EB")
                                        : Color(hex: "F59E0B").opacity(0.5),
                                    lineWidth: 1.5
                                )
                        }
                    )
            }
            .padding(20)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: 20)
                        .fill(cardGradient)
                    
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                }
            )
            .shadow(color: Color.black.opacity(0.04), radius: 15, y: 5)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - 成功トースト
    private var successToast: some View {
        VStack {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("保存しました")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 18)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "10B981"), Color(hex: "059669")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color(hex: "10B981").opacity(0.4), radius: 20, y: 10)
            )
            .padding(.top, 80)
            
            Spacer()
        }
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.8)),
            removal: .opacity.combined(with: .scale(scale: 0.9))
        ))
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showingSaveConfirmation)
    }
    
    // MARK: - 保存処理
    private func saveChanges() {
        print("\n💾 saveChanges 開始")
        print("  - oshi.name: \(oshi.name)")
        print("  - isPreset: \(isPreset)")
        
        isSaving = true
        
        Task {
            var updatedOshi = oshi
            updatedOshi.name = name
            updatedOshi.gender = gender
            updatedOshi.personalityText = personalityText
            updatedOshi.speechCharacteristics = speechCharacteristics
            updatedOshi.userCallingName = userCallingName
            updatedOshi.speechStyleText = speechStyleText
            
            if let image = avatarImage {
                do {
                    print("  📤 画像アップロード開始...")
                    let imageURL = try await FirebaseStorageManager.shared.uploadOshiAvatar(
                        image,
                        oshiId: oshi.id
                    )
                    updatedOshi.avatarImageURL = imageURL
                    print("  ✅ 画像アップロード成功: \(imageURL)")
                } catch {
                    print("  ❌ 画像アップロードエラー: \(error)")
                }
            }
            
            if isPreset {
                print("  🔄 プリセットテーブルに保存中...")
                await viewModel.updatePresetOshi(updatedOshi)
                print("  ✅ プリセットテーブル保存完了")
            } else {
                print("  🔄 通常テーブルに保存中...")
                await viewModel.updateOshi(updatedOshi)
                print("  ✅ 通常テーブル保存完了")
            }
            
            await MainActor.run {
                isSaving = false
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showingSaveConfirmation = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showingSaveConfirmation = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        dismiss()
                    }
                }
            }
            
            print("💾 saveChanges 完了\n")
        }
    }
}

// MARK: - Modern Free Text Edit View

struct ModernFreeTextEditView: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let iconColor: Color
    @Environment(\.dismiss) var dismiss
    @FocusState private var isFocused: Bool
    
    private let softGradient = LinearGradient(
        colors: [Color(hex: "F0F4FF"), Color(hex: "FAF5FF")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    var body: some View {
        ZStack {
            softGradient
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // 入力カード
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(iconColor.opacity(0.12))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(iconColor)
                        }
                        
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "374151"))
                    }
                    
                    TextField(placeholder, text: $text, axis: .vertical)
                        .focused($isFocused)
                        .font(.system(size: 16, weight: .medium))
                        .lineLimit(3...10)
                        .padding(16)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(hex: "F9FAFB"))
                                
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(
                                        isFocused
                                            ? iconColor.opacity(0.5)
                                            : Color(hex: "E5E7EB"),
                                        lineWidth: 1.5
                                    )
                            }
                        )
                        .animation(.easeInOut(duration: 0.2), value: isFocused)
                }
                .padding(20)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                        
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.9),
                                        Color.white.opacity(0.7)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                    }
                )
                .shadow(color: Color.black.opacity(0.04), radius: 15, y: 5)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                Spacer()
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    generateHapticFeedback()
                    dismiss()
                } label: {
                    Text("完了")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isFocused = true
            }
        }
    }
}

// MARK: - Modern Gender Selection View

struct ModernGenderSelectionView: View {
    @Binding var selectedGender: Gender?
    @Environment(\.dismiss) var dismiss
    
    private let softGradient = LinearGradient(
        colors: [Color(hex: "F0F4FF"), Color(hex: "FAF5FF")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    var body: some View {
        ZStack {
            softGradient
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                VStack(spacing: 2) {
                    ForEach(Array(Gender.allCases.enumerated()), id: \.element) { index, gender in
                        let position: RowPosition = {
                            if Gender.allCases.count == 1 { return .single }
                            if index == 0 { return .top }
                            if index == Gender.allCases.count - 1 { return .middle }
                            return .middle
                        }()
                        
                        Button {
                            generateHapticFeedback()
                            selectedGender = gender
                            dismiss()
                        } label: {
                            GenderSelectionRow(
                                icon: gender.icon,
                                label: gender.rawValue,
                                isSelected: selectedGender == gender,
                                position: position
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    
                    // 未設定オプション
                    Button {
                        generateHapticFeedback()
                        selectedGender = nil
                        dismiss()
                    } label: {
                        GenderSelectionRow(
                            icon: "🚫",
                            label: "未設定",
                            isSelected: selectedGender == nil,
                            position: .bottom
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                Spacer()
            }
        }
        .navigationTitle("性別")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
    }
}

struct GenderSelectionRow: View {
    let icon: String
    let label: String
    let isSelected: Bool
    var position: RowPosition = .single
    
    private var corners: UIRectCorner {
        switch position {
        case .single: return .allCorners
        case .top: return [.topLeft, .topRight]
        case .middle: return []
        case .bottom: return [.bottomLeft, .bottomRight]
        }
    }
    
    var body: some View {
        HStack(spacing: 14) {
            Text(icon)
                .font(.system(size: 24))
            
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "374151"))
            
            Spacer()
            
            if isSelected {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            } else {
                Circle()
                    .strokeBorder(Color(hex: "D1D5DB"), lineWidth: 2)
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            ZStack {
                if position == .single {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.9),
                                    Color.white.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                } else {
                    CustomRoundedRectangle(corners: corners, radius: 20)
                        .fill(.ultraThinMaterial)
                    
                    CustomRoundedRectangle(corners: corners, radius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.9),
                                    Color.white.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
        )
        .shadow(color: Color.black.opacity(position == .single ? 0.04 : 0), radius: 15, y: 5)
        .overlay(
            Group {
                if position == .top || position == .middle {
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(Color(hex: "E5E7EB").opacity(0.5))
                            .frame(height: 1)
                            .padding(.leading, 56)
                    }
                }
            }
        )
    }
}

// MARK: - Legacy Support (FreeTextEditView)

struct FreeTextEditView: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    @Environment(\.dismiss) var dismiss
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ModernFreeTextEditView(
            title: title,
            placeholder: placeholder,
            text: $text,
            iconColor: Color(hex: "6366F1")
        )
        .onTapGesture {
            UIApplication.shared.endEditing()
        }
    }
}

// MARK: - Legacy Support (GenderSelectionView)

struct GenderSelectionView: View {
    @Binding var selectedGender: Gender?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ModernGenderSelectionView(selectedGender: $selectedGender)
    }
}

// MARK: - Legacy Support (EditRowLabel)

struct EditRowLabel: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        GlassSettingRow(
            icon: "circle.fill",
            iconColor: Color(hex: "6366F1"),
            label: label,
            value: value
        )
    }
}

#Preview {
    NavigationStack {
        OshiProfileEditView(
            oshi: OshiCharacter(
                name: "さくら",
                gender: .female,
                personalityText: "優しい",
                speechCharacteristics: "柔らかい口調で話す",
                userCallingName: "あなた",
                speechStyleText: "敬語"
            ),
            viewModel: OshiViewModel(),
            isPreset: false
        )
    }
}

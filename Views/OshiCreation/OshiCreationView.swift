//
//  OshiCreationView.swift
//  AIsns
//
//  Created: 2025/12/21 - Premium UI/UX Redesign
//

import SwiftUI

struct OshiCreationView: View {
    @ObservedObject var viewModel: OshiViewModel
    @Environment(\.dismiss) var dismiss
    
    // 入力State
    @State private var name: String = ""
    @State private var gender: Gender? = nil
    @State private var personalityText: String = ""
    @State private var speechCharacteristics: String = ""
    @State private var userCallingName: String = ""
    @State private var speechStyleText: String = ""
    @State private var avatarImage: UIImage? = nil
    @State private var isPublic: Bool = false
    
    @State private var showingSaveConfirmation = false
    @State private var showingImagePicker = false
    @State private var isLoadingImage = false
    
    // アニメーション用State
    @State private var appearAnimation = false
    @State private var avatarPulse = false
    @State private var isSaving = false
    
    // カラーテーマ
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
    
    var body: some View {
        ZStack {
            // 背景レイヤー
            backgroundLayer
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // ヘッダーカード
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
                    
                    shareSettingsSection
                        .offset(y: appearAnimation ? 0 : 70)
                        .opacity(appearAnimation ? 1 : 0)
                    
                    Spacer(minLength: 120)
                }
                .padding(.bottom, 100)
            }
            
            // フローティング登録ボタン
            floatingActionButton
            
            // 成功トースト
            if showingSaveConfirmation {
                successToast
            }
        }
        .onTapGesture {
            UIApplication.shared.endEditing()
        }
        .navigationTitle("フォロワーを作成")
        .navigationBarBackButtonHidden(true)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 80 {
                        dismiss()
                    }
                }
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerWithCrop(selectedImage: $avatarImage)
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
            // ベースグラデーション
            softGradient
                .ignoresSafeArea()
            
            // 装飾的な図形
            GeometryReader { geometry in
                // 上部の装飾円
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
                
                // 下部の装飾円
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
                // ガラスモーフィズム効果
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 28)
                    .fill(cardGradient)
                
                // 内側のボーダー
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
                    placeholderAvatarView
                }
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
                    .strokeBorder(
                        accentGradient,
                        lineWidth: 4
                    )
            )
            .shadow(color: Color(hex: "6366F1").opacity(0.3), radius: 15, y: 8)
    }
    
    private var placeholderAvatarView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "EEF2FF"), Color(hex: "F5F3FF")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color(hex: "6366F1").opacity(0.5),
                                    Color(hex: "A855F7").opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
            
            VStack(spacing: 8) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(accentGradient)
                
                Text("写真を追加")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "6366F1"))
            }
        }
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
            
            TextField("例: さくら", text: $name)
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
                GenderSelectionView(selectedGender: $gender)
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
                    FreeTextEditView(
                        title: "性格",
                        placeholder: "優しい、明るい、ツンデレ など",
                        text: $personalityText
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
                    FreeTextEditView(
                        title: "話し方の特徴",
                        placeholder: "柔らかい口調、元気いっぱい など",
                        text: $speechCharacteristics
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
                    FreeTextEditView(
                        title: "口調",
                        placeholder: "丁寧、タメ口、方言 など",
                        text: $speechStyleText
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
                        .strokeBorder(
                            Color.white.opacity(0.5),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: Color.black.opacity(0.04), radius: 15, y: 5)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - フローティングアクションボタン
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 0) {
                // グラデーションボーダー
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color(hex: "E5E7EB").opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 20)
                
                Button {
                    generateHapticFeedback()
                    createOshi()
                } label: {
                    HStack(spacing: 10) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.9)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                            
                            Text("フォロワーを登録")
                                .font(.system(size: 17, weight: .bold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        Group {
                            if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(hex: "D1D5DB"))
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(accentGradient)
                                    
                                    // シャイン効果
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.25),
                                                    Color.white.opacity(0)
                                                ],
                                                startPoint: .top,
                                                endPoint: .center
                                            )
                                        )
                                }
                            }
                        }
                    )
                    .foregroundColor(.white)
                    .shadow(
                        color: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? .clear
                        : Color(hex: "6366F1").opacity(0.4),
                        radius: 15,
                        y: 8
                    )
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                )
            }
        }
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
                
                Text("フォロワーを登録しました")
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
    
    private var shareSettingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            ModernSectionHeader(title: "共有設定", icon: "globe.asia.australia.fill", color: Color(hex: "10B981"))
            
            Toggle(isOn: $isPublic) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("共有する")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "374151"))
                    
                    Text("ONにすると、他のユーザーが検索できるようになります（現在は機能しません）")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "6B7280"))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
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
            .toggleStyle(SwitchToggleStyle(tint: Color(hex: "10B981")))
            .shadow(color: Color.black.opacity(0.04), radius: 15, y: 5)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - 推し作成処理
    private func createOshi() {
        isSaving = true
        
        Task {
            // ... (Existing creation logic) ...
            let personality: PersonalityType = {
                if let matched = PersonalityType.allCases.first(where: { $0.rawValue == personalityText }) { return matched }
                return .kind
            }()
            let style: SpeechStyle = {
                if let matched = SpeechStyle.allCases.first(where: { $0.rawValue == speechStyleText }) { return matched }
                return .polite
            }()

            var newOshi = OshiCharacter(
                name: name.isEmpty ? "名無し" : name,
                gender: gender,
                personalityText: personalityText,
                speechCharacteristics: speechCharacteristics,
                userCallingName: userCallingName,
                speechStyleText: speechStyleText,
                avatarImageURL: nil,
                isPublic: isPublic // ✅ ここでは初期値として渡すが、ViewModelで上書きされるか確認
            )

            if let image = avatarImage {
                do {
                    let imageURL = try await FirebaseStorageManager.shared.uploadOshiAvatar(image, oshiId: newOshi.id)
                    newOshi.avatarImageURL = imageURL
                } catch {
                    print("画像アップロードエラー: \(error)")
                }
            }

            // ✅ isPublicを渡す
            viewModel.addOshi(newOshi, isPublic: isPublic)

            await MainActor.run {
                isSaving = false
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { showingSaveConfirmation = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.3)) { showingSaveConfirmation = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { dismiss() }
                }
            }
        }
    }
}

// MARK: - Modern Section Header

struct ModernSectionHeader: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 28, height: 28)
                
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "1F2937"))
        }
        .padding(.leading, 4)
    }
}

// MARK: - Glass Setting Row

enum RowPosition {
    case single, top, middle, bottom
}

struct GlassSettingRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String
    var position: RowPosition = .single
    
    private var cornerRadius: CGFloat {
        switch position {
        case .single: return 20
        case .top, .middle, .bottom: return 0
        }
    }
    
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
            // アイコン
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            // ラベル
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "374151"))
            
            Spacer()
            
            // 値
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(value == "未設定" ? Color(hex: "9CA3AF") : Color(hex: "6B7280"))
                .lineLimit(1)
            
            // シェブロン
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "D1D5DB"))
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
                    
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
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
                            .padding(.leading, 68)
                    }
                }
            }
        )
    }
}

// MARK: - Custom Rounded Rectangle

struct CustomRoundedRectangle: Shape {
    let corners: UIRectCorner
    let radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String {
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        let ri = Int(round(r * 255))
        let gi = Int(round(g * 255))
        let bi = Int(round(b * 255))
        return String(format: "#%02X%02X%02X", ri, gi, bi)
        #else
        return "#FF69B4"
        #endif
    }

    #if canImport(UIKit)
    func isApproximatelyEqual(to other: Color) -> Bool {
        let c1 = UIColor(self)
        let c2 = UIColor(other)

        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

        c1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        c2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        return abs(r1 - r2) < 0.01 && abs(g1 - g2) < 0.01 && abs(b1 - b2) < 0.01
    }
    #else
    func isApproximatelyEqual(to other: Color) -> Bool { false }
    #endif
}

#Preview {
    NavigationStack {
        OshiCreationView(viewModel: OshiViewModel())
    }
}

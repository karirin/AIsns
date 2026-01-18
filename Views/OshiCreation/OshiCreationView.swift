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
    @State private var isPublic: Bool = true
    
    @State private var showingSaveConfirmation = false
    @State private var showingImagePicker = false
    @State private var isLoadingImage = false
    
    // アニメーション用State
    @State private var appearAnimation = false
    @State private var isSaving = false
    
    // クイック入力の展開状態
    @State private var showPersonalityOptions = false
    @State private var showSpeechCharacteristicsOptions = false
    @State private var showSpeechStyleOptions = false
    
    @ObservedObject var adViewModel: AdViewModel
    
    // クイック入力オプション
    private let personalityOptions = ["優しい", "明るい", "クール", "天然", "しっかり者", "甘えん坊", "ツンデレ", "元気"]
    private let speechCharacteristicsOptions = ["柔らかい口調", "元気いっぱい", "落ち着いている", "おっとり", "ハキハキ", "ゆっくり", "早口", "囁くような"]
    private let speechStyleOptions = ["丁寧語", "タメ口", "関西弁", "方言", "クール", "フレンドリー", "敬語", "ギャル語"]
    
    // カラーテーマ
    private let accentGradient = LinearGradient(
        colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6"), Color(hex: "A855F7")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    private let cardGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.95),
            Color.white.opacity(0.85)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        ZStack {
            // 背景
            Color(hex: "F8FAFC")
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // ヘッダー（アバター＋名前＋性別）
                    headerCard
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                    
                    // キャラクター設定セクション
                    characterSettingsSection
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                    
                    // ユーザーとの関係 + 共有設定
                    bottomSettingsSection
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
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
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appearAnimation = true
            }
        }
    }
    
    // MARK: - ヘッダーカード（アバター＋名前＋性別）
    private var headerCard: some View {
        VStack(spacing: 16) {
            // アバター + 名前（横並び）
            HStack(spacing: 16) {
                // アバター
                avatarButton
                
                // 名前入力
                VStack(alignment: .leading, spacing: 6) {
                    Text("フォロワーの名前")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "6B7280"))
                    
                    TextField("例: さくら", text: $name)
                        .font(.system(size: 17, weight: .medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "F3F4F6"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(
                                            name.isEmpty ? Color.clear : Color(hex: "6366F1").opacity(0.4),
                                            lineWidth: 1.5
                                        )
                                )
                        )
                }
            }
            
            // 性別選択（インライン）
            VStack(alignment: .leading, spacing: 8) {
                Text("性別")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "6B7280"))
                
                HStack(spacing: 10) {
                    ForEach(Gender.allCases, id: \.self) { g in
                        genderButton(g)
                    }
                }
            }
        }
        .padding(16)
        .background(cardBackground)
    }
    
    // MARK: - アバターボタン
    private var avatarButton: some View {
        Button {
            generateHapticFeedback()
            showingImagePicker = true
        } label: {
            ZStack {
                if isLoadingImage {
                    Circle()
                        .fill(Color(hex: "F3F4F6"))
                        .frame(width: 80, height: 80)
                    ProgressView()
                } else if let avatarImage = avatarImage {
                    Image(uiImage: avatarImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(accentGradient, lineWidth: 3)
                        )
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "EEF2FF"), Color(hex: "F5F3FF")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .strokeBorder(Color(hex: "6366F1").opacity(0.3), lineWidth: 2)
                        )
                        .overlay(
                            VStack(spacing: 4) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(Color(hex: "6366F1"))
                                Text("写真")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Color(hex: "6366F1"))
                            }
                        )
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - 性別ボタン
    private func genderButton(_ g: Gender) -> some View {
        Button {
            generateHapticFeedback()
            withAnimation(.easeInOut(duration: 0.2)) {
                gender = g
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: genderIcon(g))
                    .font(.system(size: 14, weight: .medium))
                Text(g.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(gender == g ? .white : Color(hex: "6B7280"))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(gender == g ? genderColor(g) : Color(hex: "F3F4F6"))
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private func genderIcon(_ g: Gender) -> String {
        switch g {
        case .male: return "figure.stand"
        case .female: return "figure.stand.dress"
        case .other: return "sparkles"
        }
    }
    
    private func genderColor(_ g: Gender) -> Color {
        switch g {
        case .male: return Color(hex: "3B82F6")
        case .female: return Color(hex: "EC4899")
        case .other: return Color(hex: "8B5CF6")
        }
    }
    
    // MARK: - キャラクター設定セクション
    private var characterSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "キャラクター設定", icon: "sparkles", color: Color(hex: "8B5CF6"))
            
            VStack(spacing: 12) {
                // 性格
                compactInputCard(
                    icon: "heart.fill",
                    iconColor: Color(hex: "EF4444"),
                    label: "性格",
                    placeholder: "優しい、明るい、ツンデレ など",
                    text: $personalityText,
                    options: personalityOptions,
                    isExpanded: $showPersonalityOptions
                )
                
                // 話し方の特徴
                compactInputCard(
                    icon: "bubble.left.fill",
                    iconColor: Color(hex: "3B82F6"),
                    label: "話し方の特徴",
                    placeholder: "柔らかい口調、元気いっぱい など",
                    text: $speechCharacteristics,
                    options: speechCharacteristicsOptions,
                    isExpanded: $showSpeechCharacteristicsOptions
                )
                
                // 口調
                compactInputCard(
                    icon: "text.bubble.fill",
                    iconColor: Color(hex: "10B981"),
                    label: "口調",
                    placeholder: "丁寧、タメ口、方言 など",
                    text: $speechStyleText,
                    options: speechStyleOptions,
                    isExpanded: $showSpeechStyleOptions
                )
            }
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
                    .foregroundColor(Color(hex: "6366F1"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(Color(hex: "6366F1").opacity(0.1))
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            // テキスト入力
            ZStack(alignment: .topLeading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "9CA3AF"))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                }
                
                TextEditor(text: text)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "374151"))
                    .frame(minHeight: 50, maxHeight: 80)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
            }
            .padding(10)
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
                FlowLayout(spacing: 6) {
                    ForEach(options, id: \.self) { option in
                        QuickInputTag(
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
        .background(cardBackground)
    }
    
    // MARK: - 下部設定セクション（呼び方 + 共有設定）
    private var bottomSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "その他の設定", icon: "slider.horizontal.3", color: Color(hex: "F59E0B"))
            
            VStack(spacing: 0) {
                // ユーザーへの呼び方
                HStack(spacing: 12) {
                    Image(systemName: "at")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "F59E0B"))
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color(hex: "FEF3C7")))
                    
                    Text("あなたへの呼び方")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "374151"))
                    
                    Spacer()
                    
                    TextField("例: あなた、きみ", text: $userCallingName)
                        .font(.system(size: 14))
                        .multilineTextAlignment(.trailing)
                        .frame(width: 120)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                
                Divider()
                    .padding(.leading, 54)
                
                // 共有設定
                HStack(spacing: 12) {
                    Image(systemName: "globe.asia.australia.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "10B981"))
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color(hex: "D1FAE5")))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("みんなに公開")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "374151"))
                        Text("他のユーザーからも投稿が見えます")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "9CA3AF"))
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isPublic)
                        .toggleStyle(SwitchToggleStyle(tint: Color(hex: "10B981")))
                        .labelsHidden()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .background(cardBackground)
        }
    }
    
    // MARK: - セクションヘッダー
    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color)
                .frame(width: 22, height: 22)
                .background(Circle().fill(color.opacity(0.12)))
            
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: "1F2937"))
        }
        .padding(.leading, 4)
    }
    
    // MARK: - カード背景
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white)
            .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
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
    
    // MARK: - フローティングアクションボタン
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            
            Button {
                generateHapticFeedback()
                createOshi()
            } label: {
                HStack(spacing: 8) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("フォロワーを登録")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Group {
                        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(hex: "D1D5DB"))
                        } else {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(accentGradient)
                        }
                    }
                )
                .foregroundColor(.white)
                .shadow(
                    color: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? .clear
                    : Color(hex: "6366F1").opacity(0.3),
                    radius: 10,
                    y: 4
                )
            }
            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .background(
                LinearGradient(
                    colors: [Color(hex: "F8FAFC").opacity(0), Color(hex: "F8FAFC")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
                .allowsHitTesting(false)
                .ignoresSafeArea()
            )
        }
    }
    
    // MARK: - 成功トースト
    private var successToast: some View {
        VStack {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text("フォロワーを登録しました")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(Color(hex: "10B981"))
                    .shadow(color: Color(hex: "10B981").opacity(0.3), radius: 10, y: 4)
            )
            .padding(.top, 60)
            
            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showingSaveConfirmation)
    }
    
    // MARK: - 推し作成処理
    private func createOshi() {
        isSaving = true
        
        Task {
            var newOshi = OshiCharacter(
                name: name.isEmpty ? "名無し" : name,
                gender: gender,
                personalityText: personalityText,
                speechCharacteristics: speechCharacteristics,
                userCallingName: userCallingName,
                speechStyleText: speechStyleText,
                avatarImageURL: nil,
                isPublic: isPublic
            )

            if let image = avatarImage {
                do {
                    let imageURL = try await FirebaseStorageManager.shared.uploadOshiAvatar(image, oshiId: newOshi.id)
                    newOshi.avatarImageURL = imageURL
                } catch {
                    print("画像アップロードエラー: \(error)")
                }
            }

            viewModel.addOshi(newOshi, isPublic: isPublic)

            await MainActor.run {
                isSaving = false
                if AppConfig.adGateEnabled {
                    adViewModel.showInterstitialAd()
                }
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
        }
    }
}

// MARK: - クイック入力タグ
struct QuickInputTag: View {
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

// MARK: - FlowLayout
struct FlowLayout: Layout {
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

// クイック登録ボタン
struct QuickCreateButton: View {
    let emoji: String
    let name: String
    let personality: String
    let tone: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 36))
                
                VStack(spacing: 4) {
                    Text(name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "1F2937"))
                    
                    Text(personality)
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "6B7280"))
                        .lineLimit(1)
                }
            }
            .frame(width: 100, height: 120)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
            )
        }
        .buttonStyle(ScaleButtonStyle())
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
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "374151"))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(value == "未設定" ? Color(hex: "9CA3AF") : Color(hex: "6B7280"))
                .lineLimit(1)
            
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
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
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
        OshiCreationView(viewModel: OshiViewModel(), adViewModel: AdViewModel())
    }
}

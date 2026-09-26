//
//  OshiProfileEditView.swift
//  AIsns
//
//  Updated: 2025/12/29 - Compact UI Redesign
//

import SwiftUI

struct OshiProfileEditView: View {
    let oshi: OshiCharacter
    @ObservedObject var viewModel: OshiViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String
    @State private var gender: Gender?
    @State private var appearanceDescription: String
    @State private var backgroundStory: String
    @State private var personalityText: String
    @State private var speechCharacteristics: String
    @State private var userCallingName: String
    @State private var speechStyleText: String
    @State private var relationshipStyle: String
    @State private var replyLengthPreference: String
    @State private var memoryMemo: String
    @State private var replyFrequencyPreference: String
    @State private var avatarImage: UIImage?
    @State private var isPublic: Bool
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
    
    // クイック入力オプション
    private let personalityOptions = ["優しい", "明るい", "クール", "天然", "しっかり者", "甘えん坊", "ツンデレ", "元気"]
    private let speechCharacteristicsOptions = ["柔らかい口調", "元気いっぱい", "落ち着いている", "おっとり", "ハキハキ", "ゆっくり", "早口", "囁くような"]
    private let speechStyleOptions = ["丁寧語", "タメ口", "関西弁", "方言", "クール", "フレンドリー", "敬語", "ギャル語"]
    private let relationshipOptions = ["友達", "親友", "恋人風", "先輩後輩", "推しとファン"]
    private let replyLengthOptions = ["短め", "普通", "長め"]
    private let replyFrequencyOptions = ["控えめ", "普通", "多め"]
    
    // プリセットフラグ
    let isPreset: Bool
    
    // カラーテーマ
    private let accentGradient = LinearGradient(
        colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6"), Color(hex: "A855F7")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    init(oshi: OshiCharacter, viewModel: OshiViewModel, isPreset: Bool = false) {
        self.oshi = oshi
        self.viewModel = viewModel
        self.isPreset = isPreset
        
        _name = State(initialValue: oshi.name)
        _gender = State(initialValue: oshi.gender)
        _appearanceDescription = State(initialValue: oshi.appearanceDescription)
        _backgroundStory = State(initialValue: oshi.backgroundStory)
        _personalityText = State(initialValue: oshi.personalityText)
        _speechCharacteristics = State(initialValue: oshi.speechCharacteristics)
        _userCallingName = State(initialValue: oshi.userCallingName)
        _speechStyleText = State(initialValue: oshi.speechStyleText)
        _relationshipStyle = State(initialValue: oshi.relationshipStyle ?? "")
        _replyLengthPreference = State(initialValue: oshi.replyLengthPreference ?? "")
        _memoryMemo = State(initialValue: oshi.memoryMemo ?? "")
        _replyFrequencyPreference = State(initialValue: oshi.replyFrequencyPreference ?? "")
        _avatarImage = State(initialValue: nil)
        _isPublic = State(initialValue: oshi.isPublic)
    }
    
    var body: some View {
        ZStack {
            // 背景
            AuroraBackground()

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

                    plusAdvancedSettingsSection
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                    
                    // ユーザーとの関係 + 共有設定
                    bottomSettingsSection
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
            
            // 成功トースト
            if showingSaveConfirmation {
                successToast
            }
        }
        .simultaneousGesture(TapGesture().onEnded {
            UIApplication.shared.endEditing()
        })
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("プロフィール編集")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
            }

            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                }
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
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appearAnimation = true
            }
        }
    }
    
    // MARK: - ヘッダーカード（アバター＋名前＋性別）
    private var headerCard: some View {
        VStack(spacing: 16) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) {
                    avatarButton
                    nameInputField
                }

                VStack(alignment: .center, spacing: 12) {
                    avatarButton
                    nameInputField
                }
            }
            
            // 性別選択（インライン）
            VStack(alignment: .leading, spacing: 8) {
                Text("性別")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
                
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

    private var nameInputField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("フォロワーの名前")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)

            TextField("名前を入力", text: $name)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
                .tint(AppColors.primary)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.surfaceSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    name.isEmpty ? AppColors.borderLight : Color(hex: "6366F1").opacity(0.4),
                                    lineWidth: 1.5
                                )
                        )
                )
        }
        .frame(maxWidth: .infinity)
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
                        .fill(AppColors.surfaceSecondary)
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
                    // イニシャル表示
                    ZStack {
                        Circle()
                            .fill(accentGradient)
                            .frame(width: 80, height: 80)
                        
                        Text(String(name.prefix(1).isEmpty ? "?" : name.prefix(1)))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                
                // 編集バッジ
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(AppColors.surface)
                                .frame(width: 26, height: 26)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
                            
                            Circle()
                                .fill(accentGradient)
                                .frame(width: 22, height: 22)
                            
                            Image(systemName: "camera.fill")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(width: 80, height: 80)
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
            .foregroundColor(gender == g ? .white : AppColors.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(gender == g ? genderColor(g) : AppColors.surfaceSecondary)
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

                detailInputCard(
                    icon: "person.crop.rectangle",
                    iconColor: Color(hex: "EC4899"),
                    label: "外見",
                    placeholder: "例: 黒髪のショート、青い瞳、白いパーカー",
                    text: $appearanceDescription,
                    characterLimit: 200
                )

                detailInputCard(
                    icon: "book.closed.fill",
                    iconColor: Color(hex: "F59E0B"),
                    label: "背景設定",
                    placeholder: "例: 写真部に所属する大学生。海辺の町で育った",
                    text: $backgroundStory,
                    characterLimit: 500
                )
            }
        }
    }

    private func detailInputCard(
        icon: String,
        iconColor: Color,
        label: String,
        placeholder: String,
        text: Binding<String>,
        characterLimit: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(iconColor.opacity(0.12)))

                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                Text("\(text.wrappedValue.count)/\(characterLimit)")
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.textTertiary)
            }

            ZStack(alignment: .topLeading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textTertiary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                }

                TextEditor(text: text)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textPrimary)
                    .tint(AppColors.primary)
                    .frame(minHeight: 70, maxHeight: 120)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .onChange(of: text.wrappedValue) { newValue in
                        if newValue.count > characterLimit {
                            text.wrappedValue = String(newValue.prefix(characterLimit))
                        }
                    }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.surfaceSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(
                                text.wrappedValue.isEmpty ? AppColors.borderLight : iconColor.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            )
        }
        .padding(14)
        .background(cardBackground)
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
                    .foregroundColor(AppColors.textPrimary)
                
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
                        .foregroundColor(AppColors.textTertiary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                }
                
                TextEditor(text: text)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textPrimary)
                    .tint(AppColors.primary)
                    .frame(minHeight: 50, maxHeight: 80)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.surfaceSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(
                                text.wrappedValue.isEmpty ? AppColors.borderLight : iconColor.opacity(0.3),
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

    private var plusAdvancedSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Plus詳細調整", icon: "sparkles", color: AppColors.primary)

            if viewModel.isPlusActive {
                VStack(spacing: 14) {
                    choiceRow(
                        title: "距離感",
                        icon: "person.2.fill",
                        options: relationshipOptions,
                        selection: $relationshipStyle
                    )

                    Divider()

                    choiceRow(
                        title: "返信の長さ",
                        icon: "text.alignleft",
                        options: replyLengthOptions,
                        selection: $replyLengthPreference
                    )

                    Divider()

                    choiceRow(
                        title: "リプ頻度",
                        icon: "message.badge.fill",
                        options: replyFrequencyOptions,
                        selection: $replyFrequencyPreference
                    )

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Label("記憶メモ", systemImage: "brain.head.profile")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)

                        ZStack(alignment: .topLeading) {
                            if memoryMemo.isEmpty {
                                Text("好きなもの、関係性、覚えてほしいこと")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppColors.textTertiary)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 8)
                            }

                            TextEditor(text: $memoryMemo)
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.textPrimary)
                                .tint(AppColors.primary)
                                .frame(minHeight: 70, maxHeight: 110)
                                .scrollContentBackground(.hidden)
                        }
                        .padding(10)
                        .background(AppColors.surfaceSecondary, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(14)
                .background(cardBackground)
            } else {
                Button {
                    generateHapticFeedback()
                    viewModel.requestPlusPaywall(.premiumFeature, force: true)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(AppColors.primary, in: RoundedRectangle(cornerRadius: 9))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Plusで距離感・記憶メモを調整")
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppColors.textPrimary)
                            Text("通常の性格・口調設定はこのまま使えます")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(14)
                .background(cardBackground)
            }
        }
    }

    private func choiceRow(
        title: String,
        icon: String,
        options: [String],
        selection: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)

            FlowLayout(spacing: 6) {
                ForEach(options, id: \.self) { option in
                    Button {
                        generateHapticFeedback()
                        selection.wrappedValue = selection.wrappedValue == option ? "" : option
                    } label: {
                        Text(option)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(selection.wrappedValue == option ? .white : AppColors.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(selection.wrappedValue == option ? AppColors.primary : AppColors.surfaceSecondary)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
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
                        .background(Circle().fill(Color(hex: "F59E0B").opacity(0.15)))
                    
                    Text("あなたへの呼び方")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    TextField("例: あなた、きみ", text: $userCallingName)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textPrimary)
                        .tint(AppColors.primary)
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(.trailing)
                        .frame(minWidth: 120)
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
                        .background(Circle().fill(AppColors.success.opacity(0.15)))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("みんなに公開")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        Text("他のユーザーからも投稿が見えます")
                            .font(.system(size: 11))
                            .foregroundColor(AppColors.textTertiary)
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
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(.leading, 4)
    }
    
    // MARK: - カード背景
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(AppColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(AppColors.borderLight.opacity(0.6), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
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
    
    // MARK: - 成功トースト
    private var successToast: some View {
        VStack {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text("保存しました")
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
    
    // MARK: - 保存処理
    private func saveChanges() {
        isSaving = true
        
        Task {
            var updatedOshi = oshi
            updatedOshi.name = name
            updatedOshi.gender = gender
            updatedOshi.appearanceDescription = appearanceDescription
            updatedOshi.backgroundStory = backgroundStory
            updatedOshi.personalityText = personalityText
            updatedOshi.speechCharacteristics = speechCharacteristics
            updatedOshi.userCallingName = userCallingName
            updatedOshi.speechStyleText = speechStyleText
            updatedOshi.relationshipStyle = emptyToNil(relationshipStyle)
            updatedOshi.replyLengthPreference = emptyToNil(replyLengthPreference)
            updatedOshi.memoryMemo = emptyToNil(memoryMemo)
            updatedOshi.replyFrequencyPreference = emptyToNil(replyFrequencyPreference)
            updatedOshi.isPublic = isPublic
            
            if let image = avatarImage {
                do {
                    let imageURL = try await FirebaseStorageManager.shared.uploadOshiAvatar(
                        image,
                        oshiId: oshi.id
                    )
                    updatedOshi.avatarImageURL = imageURL
                } catch {
                    print("画像アップロードエラー: \(error)")
                }
            }
            
            if isPreset {
                await viewModel.updatePresetOshi(updatedOshi)
            } else {
                viewModel.updateOshi(updatedOshi)
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
        }
    }

    private func emptyToNil(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
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

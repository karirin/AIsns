//
//  OshiProfileEdit.swift
//  AIsns
//
//  Updated: 2025/12/20
//

import SwiftUI

struct OshiProfileEditView: View {
    let oshi: OshiCharacter
    @ObservedObject var viewModel: OshiViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String
    @State private var gender: Gender?
    @State private var personality: PersonalityType
    @State private var speechCharacteristics: String
    @State private var userCallingName: String
    @State private var speechStyle: SpeechStyle
    @State private var relationshipDistance: RelationshipDistance
    @State private var worldSetting: WorldSetting
    @State private var ngTopicsText: String
    @State private var selectedColor: Color
    @State private var showingSaveConfirmation = false
    
    init(oshi: OshiCharacter, viewModel: OshiViewModel) {
        self.oshi = oshi
        self.viewModel = viewModel
        
        _name = State(initialValue: oshi.name)
        _gender = State(initialValue: oshi.gender)
        _personality = State(initialValue: oshi.personality)
        _speechCharacteristics = State(initialValue: oshi.speechCharacteristics)
        _userCallingName = State(initialValue: oshi.userCallingName)
        _speechStyle = State(initialValue: oshi.speechStyle)
        _relationshipDistance = State(initialValue: oshi.relationshipDistance)
        _worldSetting = State(initialValue: oshi.worldSetting)
        _ngTopicsText = State(initialValue: oshi.ngTopics.joined(separator: ", "))
        _selectedColor = State(initialValue: Color(hex: oshi.avatarColor))
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    // プロフィール画像エリア
                    VStack(spacing: 12) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [selectedColor, selectedColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(String(name.prefix(1).isEmpty ? "?" : name.prefix(1)))
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        Text("写真を変更")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                    
                    // ユーザー情報セクション
                    VStack(spacing: 0) {
                        Text("ユーザー情報")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        
                        VStack(spacing: 0) {
                            // 名前
                            HStack {
                                Text("名前")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                TextField("", text: $name)
                                    .multilineTextAlignment(.trailing)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 14)
                            .background(Color(.systemBackground))
                            
                            Divider()
                                .padding(.leading, 16)
                            
                            // 性別
                            NavigationLink {
                                GenderSelectionView(selectedGender: $gender)
                            } label: {
                                HStack {
                                    Text("性別")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text(gender?.rawValue ?? "未設定")
                                        .font(.subheadline)
                                        .foregroundColor(gender == nil ? .secondary : .primary)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 14)
                                .background(Color(.systemBackground))
                            }
                            
                            Divider()
                                .padding(.leading, 16)
                            
                            // ユーザー名（固定）
                            HStack {
                                Text("ユーザー名")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text("up\(String(format: "%05d", abs(oshi.id.hashValue % 100000)))")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.clear)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 14)
                            .background(Color(.systemBackground))
                            
                            Divider()
                                .padding(.leading, 16)
                            
                            // SNSリンク
                            HStack {
                                Spacer()
                                HStack(spacing: 4) {
                                    Text("tiktok.com/@up\(String(format: "%05d", abs(oshi.id.hashValue % 100000)))")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    Image(systemName: "doc.on.doc")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 14)
                            .background(Color(.systemBackground))
                        }
                        .background(Color(.systemBackground))
                    }
                    
                    // 自己紹介
                    VStack(spacing: 0) {
                        Divider()
                            .padding(.leading, 16)
                        
                        NavigationLink {
                            SpeechCharacteristicsEditView(text: $speechCharacteristics)
                        } label: {
                            HStack {
                                Text("自己紹介")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text(speechCharacteristics.isEmpty ? "自己紹介を追加" : speechCharacteristics)
                                    .font(.subheadline)
                                    .foregroundColor(speechCharacteristics.isEmpty ? .secondary : .primary)
                                    .lineLimit(1)
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 14)
                            .background(Color(.systemBackground))
                        }
                    }
                    .background(Color(.systemBackground))
                    .padding(.top, 20)
                    
                    // キャラクター設定セクション
                    VStack(spacing: 0) {
                        Text("キャラクター設定")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 32)
                            .padding(.bottom, 8)
                        
                        VStack(spacing: 0) {
                            // 性格
                            NavigationLink {
                                PersonalitySelectionView(selectedPersonality: $personality)
                            } label: {
                                EditRowLabel(label: "性格", value: "\(personality.emoji) \(personality.rawValue)")
                            }
                            
                            Divider()
                                .padding(.leading, 16)
                            
                            // 話し方の特徴
                            NavigationLink {
                                SpeechCharacteristicsEditView(text: $speechCharacteristics)
                            } label: {
                                EditRowLabel(
                                    label: "話し方の特徴",
                                    value: speechCharacteristics.isEmpty ? "追加" : speechCharacteristics,
                                    valueColor: speechCharacteristics.isEmpty ? .secondary : .primary
                                )
                            }
                            
                            Divider()
                                .padding(.leading, 16)
                            
                            // ユーザーへの呼び方
                            HStack {
                                Text("ユーザーへの呼び方")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                TextField("あなた、きみ など", text: $userCallingName)
                                    .multilineTextAlignment(.trailing)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.clear)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 14)
                            .background(Color(.systemBackground))
                            
                            Divider()
                                .padding(.leading, 16)
                            
                            // 口調
                            NavigationLink {
                                SpeechStyleSelectionView(selectedStyle: $speechStyle)
                            } label: {
                                EditRowLabel(label: "口調", value: speechStyle.rawValue)
                            }
                            
                            Divider()
                                .padding(.leading, 16)
                            
                            // 距離感
                            NavigationLink {
                                RelationshipSelectionView(selectedDistance: $relationshipDistance)
                            } label: {
                                EditRowLabel(label: "距離感", value: "\(relationshipDistance.icon) \(relationshipDistance.rawValue)")
                            }
                            
                            Divider()
                                .padding(.leading, 16)
                            
                            // 世界観
                            NavigationLink {
                                WorldSettingSelectionView(selectedSetting: $worldSetting)
                            } label: {
                                EditRowLabel(label: "世界観", value: "\(worldSetting.icon) \(worldSetting.rawValue)")
                            }
                        }
                        .background(Color(.systemBackground))
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            .background(Color(.systemGray6))
            
            // トースト通知
            if showingSaveConfirmation {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Text("名前を更新しました")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.85))
                    )
                    .padding(.top, 60)
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.3), value: showingSaveConfirmation)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("キャンセル") {
                    dismiss()
                }
                .foregroundColor(.primary)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    saveChanges()
                }
                .foregroundColor(.primary)
                .fontWeight(.semibold)
            }
        }
    }
    
    private func saveChanges() {
        var updatedOshi = oshi
        updatedOshi.name = name
        updatedOshi.gender = gender
        updatedOshi.personality = personality
        updatedOshi.speechCharacteristics = speechCharacteristics
        updatedOshi.userCallingName = userCallingName
        updatedOshi.speechStyle = speechStyle
        updatedOshi.relationshipDistance = relationshipDistance
        updatedOshi.worldSetting = worldSetting
        updatedOshi.ngTopics = ngTopicsText.split(separator: ",").map {
            String($0.trimmingCharacters(in: .whitespaces))
        }.filter { !$0.isEmpty }
        updatedOshi.avatarColor = selectedColor.toHex()
        
        viewModel.updateOshi(updatedOshi)
        
        // 保存完了の通知を表示
        withAnimation {
            showingSaveConfirmation = true
        }
        
        // 1.5秒後に通知を非表示にして閉じる
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showingSaveConfirmation = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                dismiss()
            }
        }
    }
}

// 編集行ラベル
struct EditRowLabel: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(valueColor)
                .lineLimit(1)
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
    }
}

// 編集行（カスタムコンテンツ対応）
struct EditRow<Content: View>: View {
    let icon: String
    let title: String
    let value: String
    let placeholder: String
    @ViewBuilder let content: Content
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.primary)
                .frame(width: 40, height: 40)
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            content
            
            if !(content is EmptyView) {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .opacity(0)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

// 性別選択画面
struct GenderSelectionView: View {
    @Binding var selectedGender: Gender?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            ForEach(Gender.allCases, id: \.self) { gender in
                Button {
                    selectedGender = gender
                    dismiss()
                } label: {
                    HStack {
                        Text("\(gender.icon) \(gender.rawValue)")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if selectedGender == gender {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            Button {
                selectedGender = nil
                dismiss()
            } label: {
                HStack {
                    Text("未設定")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if selectedGender == nil {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .navigationTitle("性別")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// 性格選択画面
struct PersonalitySelectionView: View {
    @Binding var selectedPersonality: PersonalityType
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            ForEach(PersonalityType.allCases, id: \.self) { personality in
                Button {
                    selectedPersonality = personality
                    dismiss()
                } label: {
                    HStack {
                        Text("\(personality.emoji) \(personality.rawValue)")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if selectedPersonality == personality {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("性格")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// 話し方の特徴編集画面
struct SpeechCharacteristicsEditView: View {
    @Binding var text: String
    @Environment(\.dismiss) var dismiss
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            TextEditor(text: $text)
                .focused($isFocused)
                .padding()
                .font(.body)
            
            Spacer()
        }
        .navigationTitle("話し方の特徴")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完了") {
                    dismiss()
                }
            }
        }
        .onAppear {
            isFocused = true
        }
    }
}

// 口調選択画面
struct SpeechStyleSelectionView: View {
    @Binding var selectedStyle: SpeechStyle
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            ForEach(SpeechStyle.allCases, id: \.self) { style in
                Button {
                    selectedStyle = style
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(style.rawValue)
                                .foregroundColor(.primary)
                            Text(style.example)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedStyle == style {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("口調")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// 距離感選択画面
struct RelationshipSelectionView: View {
    @Binding var selectedDistance: RelationshipDistance
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            ForEach(RelationshipDistance.allCases, id: \.self) { distance in
                Button {
                    selectedDistance = distance
                    dismiss()
                } label: {
                    HStack {
                        Text("\(distance.icon) \(distance.rawValue)")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if selectedDistance == distance {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("距離感")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// 世界観選択画面
struct WorldSettingSelectionView: View {
    @Binding var selectedSetting: WorldSetting
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            ForEach(WorldSetting.allCases, id: \.self) { setting in
                Button {
                    selectedSetting = setting
                    dismiss()
                } label: {
                    HStack {
                        Text("\(setting.icon) \(setting.rawValue)")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if selectedSetting == setting {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("世界観")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        OshiProfileEditView(
            oshi: OshiCharacter(
                name: "さくら",
                gender: .female,
                personality: .kind,
                speechCharacteristics: "柔らかい口調で話す",
                userCallingName: "あなた",
                speechStyle: .polite,
                relationshipDistance: .bestFriend,
                worldSetting: .student,
                avatarColor: "#FF69B4"
            ),
            viewModel: OshiViewModel()
        )
    }
}

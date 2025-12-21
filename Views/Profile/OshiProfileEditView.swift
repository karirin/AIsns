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
    @State private var personalityText: String  // 自由入力用
    @State private var speechCharacteristics: String
    @State private var userCallingName: String
    @State private var speechStyleText: String  // 自由入力用
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
        _personalityText = State(initialValue: oshi.personality.rawValue)
        _speechCharacteristics = State(initialValue: oshi.speechCharacteristics)
        _userCallingName = State(initialValue: oshi.userCallingName)
        _speechStyleText = State(initialValue: oshi.speechStyle.rawValue)
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
                                    .foregroundColor(.clear)
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
                        }
                        .background(Color(.systemBackground))
                    }

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
                            // 性格（自由入力）
                            NavigationLink {
                                FreeTextEditView(
                                    title: "性格",
                                    placeholder: "優しい、明るい、ツンデレ など",
                                    text: $personalityText
                                )
                            } label: {
                                EditRowLabel(
                                    label: "性格",
                                    value: personalityText.isEmpty ? "追加" : personalityText,
                                    valueColor: personalityText.isEmpty ? .secondary : .primary
                                )
                            }
                            
                            Divider()
                                .padding(.leading, 16)
                            
                            // 話し方の特徴
                            NavigationLink {
                                FreeTextEditView(
                                    title: "話し方の特徴",
                                    placeholder: "柔らかい口調、元気いっぱい など",
                                    text: $speechCharacteristics
                                )
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
                            
                            // 口調（自由入力）
                            NavigationLink {
                                FreeTextEditView(
                                    title: "口調",
                                    placeholder: "丁寧、タメ口、方言 など",
                                    text: $speechStyleText
                                )
                            } label: {
                                EditRowLabel(
                                    label: "口調",
                                    value: speechStyleText.isEmpty ? "追加" : speechStyleText,
                                    valueColor: speechStyleText.isEmpty ? .secondary : .primary
                                )
                            }
                            
                            Divider()
                                .padding(.leading, 16)
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
                        Text("保存しました")
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
        
        // 性格: カスタムテキストまたは既存の列挙型から選択
        if let matchedPersonality = PersonalityType.allCases.first(where: { $0.rawValue == personalityText }) {
            updatedOshi.personality = matchedPersonality
        } else {
            // カスタムテキストの場合は適当なデフォルト値を設定
            // または PersonalityType に .custom(String) を追加する必要があります
            updatedOshi.personality = .kind  // 仮のデフォルト
        }
        
        updatedOshi.speechCharacteristics = speechCharacteristics
        updatedOshi.userCallingName = userCallingName
        
        // 口調: カスタムテキストまたは既存の列挙型から選択
        if let matchedStyle = SpeechStyle.allCases.first(where: { $0.rawValue == speechStyleText }) {
            updatedOshi.speechStyle = matchedStyle
        } else {
            updatedOshi.speechStyle = .polite  // 仮のデフォルト
        }
        
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

// 自由テキスト編集画面（汎用）
struct FreeTextEditView: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    @Environment(\.dismiss) var dismiss
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            TextField(placeholder, text: $text, axis: .vertical)
                .focused($isFocused)
                .padding()
                .font(.body)
                .lineLimit(3...10)
            
            Spacer()
        }
        .navigationTitle(title)
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

import SwiftUI

struct OshiCreationView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: OshiViewModel
    
    @State private var name = ""
    @State private var gender: Gender? = nil
    @State private var personality: PersonalityType = .kind
    @State private var speechCharacteristics = ""
    @State private var userCallingName = ""
    @State private var speechStyle: SpeechStyle = .casual
    @State private var relationshipDistance: RelationshipDistance = .bestFriend
    @State private var worldSetting: WorldSetting = .idol
    @State private var ngTopicsText = ""
    @State private var selectedColor: Color = .pink
    
    let availableColors: [Color] = [
        .pink, .purple, .blue, .cyan, .green,
        .yellow, .orange, .red, .indigo
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // アバターカラー選択
                    VStack(alignment: .leading, spacing: 12) {
                        Text("アバターカラー")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(availableColors, id: \.self) { color in
                                Circle()
                                    .fill(color.gradient)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                                    .shadow(color: selectedColor == color ? color.opacity(0.5) : .clear,
                                           radius: 8)
                                    .onTapGesture {
                                        withAnimation(.spring()) {
                                            selectedColor = color
                                        }
                                    }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    // 名前入力
                    VStack(alignment: .leading, spacing: 8) {
                        Text("名前")
                            .font(.headline)
                        TextField("推しの名前を入力", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .font(.body)
                    }
                    
                    // 性別選択
                    VStack(alignment: .leading, spacing: 12) {
                        Text("性別（任意）")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            ForEach([Gender.male, Gender.female, Gender.other], id: \.self) { genderOption in
                                SelectionCard(
                                    title: "\(genderOption.icon) \(genderOption.rawValue)",
                                    isSelected: gender == genderOption
                                ) {
                                    withAnimation(.spring()) {
                                        gender = genderOption
                                    }
                                }
                            }
                        }
                        
                        if gender != nil {
                            Button("未設定にする") {
                                withAnimation(.spring()) {
                                    gender = nil
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                    
                    // 性格選択
                    VStack(alignment: .leading, spacing: 12) {
                        Text("性格")
                            .font(.headline)
                        
                        ForEach(PersonalityType.allCases, id: \.self) { type in
                            SelectionCard(
                                title: "\(type.emoji) \(type.rawValue)",
                                isSelected: personality == type
                            ) {
                                withAnimation(.spring()) {
                                    personality = type
                                }
                            }
                        }
                    }
                    
                    // 話し方の特徴
                    VStack(alignment: .leading, spacing: 8) {
                        Text("話し方の特徴（任意）")
                            .font(.headline)
                        Text("例: 柔らかい口調で話す、語尾に「にゃ」をつける")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("話し方の特徴を入力", text: $speechCharacteristics)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // ユーザーへの呼び方
                    VStack(alignment: .leading, spacing: 8) {
                        Text("あなたへの呼び方（任意）")
                            .font(.headline)
                        Text("例: あなた、きみ、〇〇さん")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("呼び方を入力", text: $userCallingName)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // 口調選択
                    VStack(alignment: .leading, spacing: 12) {
                        Text("口調")
                            .font(.headline)
                        
                        ForEach(SpeechStyle.allCases, id: \.self) { style in
                            SelectionCard(
                                title: style.rawValue,
                                subtitle: style.example,
                                isSelected: speechStyle == style
                            ) {
                                withAnimation(.spring()) {
                                    speechStyle = style
                                }
                            }
                        }
                    }
                    
                    // 距離感選択
                    VStack(alignment: .leading, spacing: 12) {
                        Text("距離感")
                            .font(.headline)
                        
                        ForEach(RelationshipDistance.allCases, id: \.self) { distance in
                            SelectionCard(
                                title: "\(distance.icon) \(distance.rawValue)",
                                isSelected: relationshipDistance == distance
                            ) {
                                withAnimation(.spring()) {
                                    relationshipDistance = distance
                                }
                            }
                        }
                    }
                    
                    // 世界観選択
                    VStack(alignment: .leading, spacing: 12) {
                        Text("世界観")
                            .font(.headline)
                        
                        ForEach(WorldSetting.allCases, id: \.self) { setting in
                            SelectionCard(
                                title: "\(setting.icon) \(setting.rawValue)",
                                isSelected: worldSetting == setting
                            ) {
                                withAnimation(.spring()) {
                                    worldSetting = setting
                                }
                            }
                        }
                    }
                    
                    // NG項目
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NG項目（任意）")
                            .font(.headline)
                        Text("カンマ区切りで入力")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("例: 重い話題,下ネタ", text: $ngTopicsText)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // 作成ボタン
                    Button(action: createOshi) {
                        Text("推しを作成")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [selectedColor, selectedColor.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                    }
                    .disabled(name.isEmpty)
                    .opacity(name.isEmpty ? 0.5 : 1)
                }
                .padding()
            }
            .navigationTitle("推しを作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func createOshi() {
        let ngTopics = ngTopicsText.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
        
        let oshi = OshiCharacter(
            name: name,
            gender: gender,
            personality: personality,
            speechCharacteristics: speechCharacteristics,
            userCallingName: userCallingName,
            speechStyle: speechStyle,
            relationshipDistance: relationshipDistance,
            worldSetting: worldSetting,
            ngTopics: ngTopics,
            avatarColor: selectedColor.toHex()
        )
        
        viewModel.addOshi(oshi)
        dismiss()
    }
}

// 選択カード
struct SelectionCard: View {
    let title: String
    var subtitle: String? = nil
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.primary)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .imageScale(.large)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

// Color extension for hex conversion
extension Color {
    func toHex() -> String {
        let components = UIColor(self).cgColor.components
        let r = Float(components?[0] ?? 0)
        let g = Float(components?[1] ?? 0)
        let b = Float(components?[2] ?? 0)
        return String(format: "#%02lX%02lX%02lX",
                     lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

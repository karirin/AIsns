//
//  OshiCreationView.swift
//  AIsns
//
//  Created: 2025/12/21 - 最新デザインに統一
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

    @State private var showingSaveConfirmation = false
    @State private var showingImagePicker = false
    @State private var isLoadingImage = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // プロフィール画像エリア
                    VStack(spacing: 16) {
                        Button(action: {
                            generateHapticFeedback()
                            showingImagePicker = true
                        }) {
                            Group {
                                if isLoadingImage {
                                    Circle()
                                        .fill(Color(.systemGray5))
                                        .frame(width: 120, height: 120)
                                        .overlay(ProgressView())
                                } else if let avatarImage = avatarImage {
                                    Image(uiImage: avatarImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(Color(.systemGray4), lineWidth: 1)
                                        )
                                } else {
                                    ZStack {
                                        Circle()
                                            .fill(Color(.systemGray5))
                                            .frame(width: 120, height: 120)
                                        
                                        VStack(spacing: 8) {
                                            Image(systemName: "person.crop.circle.badge.plus")
                                                .font(.system(size: 40))
                                                .foregroundColor(.secondary)
                                            
                                            Text("写真を追加")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 32)

                    // フォームコンテナ
                    VStack(spacing: 20) {
                        // 基本情報セクション
                        VStack(alignment: .leading, spacing: 12) {
                            Text("基本情報")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                            
                            VStack(spacing: 0) {
                                // 名前
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("名前")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("推しの名前を入力", text: $name)
                                        .textFieldStyle(.plain)
                                        .font(.body)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(10)
                                }
                                .padding(16)
                                
                                Divider()
                                    .padding(.leading, 16)
                                
                                // 性別
                                NavigationLink {
                                    GenderSelectionView(selectedGender: $gender)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("性別")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            
                                            Text(gender?.rawValue ?? "未設定")
                                                .font(.body)
                                                .foregroundColor(gender == nil ? .secondary : .primary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(16)
                                }
                                .buttonStyle(.plain)
                            }
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                        }
                        
                        // キャラクター設定セクション
                        VStack(alignment: .leading, spacing: 12) {
                            Text("キャラクター設定")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                            
                            VStack(spacing: 0) {
                                // 性格
                                NavigationLink {
                                    FreeTextEditView(
                                        title: "性格",
                                        placeholder: "優しい、明るい、ツンデレ など",
                                        text: $personalityText
                                    )
                                } label: {
                                    CharacterSettingRow(
                                        label: "性格",
                                        value: personalityText,
                                        placeholder: "追加"
                                    )
                                }
                                .buttonStyle(.plain)
                                
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
                                    CharacterSettingRow(
                                        label: "話し方の特徴",
                                        value: speechCharacteristics,
                                        placeholder: "追加"
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                Divider()
                                    .padding(.leading, 16)
                                
                                // ユーザーへの呼び方
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("ユーザーへの呼び方")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("あなた、きみ など", text: $userCallingName)
                                        .textFieldStyle(.plain)
                                        .font(.body)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(10)
                                }
                                .padding(16)
                                
                                Divider()
                                    .padding(.leading, 16)
                                
                                // 口調
                                NavigationLink {
                                    FreeTextEditView(
                                        title: "口調",
                                        placeholder: "丁寧、タメ口、方言 など",
                                        text: $speechStyleText
                                    )
                                } label: {
                                    CharacterSettingRow(
                                        label: "口調",
                                        value: speechStyleText,
                                        placeholder: "追加"
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer(minLength: 100)
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Button {
                        generateHapticFeedback()
                        createOshi()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.body)
                            
                            Text("登録")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? Color(.systemGray4)
                            : Color.blue
                        )
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGroupedBackground))
                }
            }
            
            // トースト通知
            if showingSaveConfirmation {
                VStack {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.body)
                            .foregroundColor(.white)
                        
                        Text("登録しました")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.85))
                    )
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                    .padding(.top, 60)
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showingSaveConfirmation)
            }
        }
        .navigationTitle("推しを作成")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerWithCrop(selectedImage: $avatarImage)
        }
    }

    private func createOshi() {
        Task {
            let personality: PersonalityType = {
                if let matched = PersonalityType.allCases.first(where: { $0.rawValue == personalityText }) {
                    return matched
                }
                return .kind
            }()

            let style: SpeechStyle = {
                if let matched = SpeechStyle.allCases.first(where: { $0.rawValue == speechStyleText }) {
                    return matched
                }
                return .polite
            }()

            var newOshi = OshiCharacter(
                name: name.isEmpty ? "名無し" : name,
                gender: gender,
                personalityText: personalityText,
                speechCharacteristics: speechCharacteristics,
                userCallingName: userCallingName,
                speechStyleText: speechStyleText,
                avatarImageURL: nil
            )

            if let image = avatarImage {
                do {
                    let imageURL = try await FirebaseStorageManager.shared.uploadOshiAvatar(
                        image,
                        oshiId: newOshi.id
                    )
                    newOshi.avatarImageURL = imageURL
                } catch {
                    print("画像アップロードエラー: \(error)")
                }
            }

            viewModel.addOshi(newOshi)

            await MainActor.run {
                withAnimation {
                    showingSaveConfirmation = true
                }

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
    }
}

// MARK: - Components

struct CharacterSettingRow: View {
    let label: String
    let value: String
    let placeholder: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value.isEmpty ? placeholder : value)
                    .font(.body)
                    .foregroundColor(value.isEmpty ? .secondary : .primary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
    }
}

// MARK: - Extensions

extension Color {
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

//
//  OshiCreationView.swift
//  AIsns
//
//  Created: 2025/12/21 - OshiProfileEditView と同じデザインに統一
//

import SwiftUI

struct OshiCreationView: View {
    @ObservedObject var viewModel: OshiViewModel
    @Environment(\.dismiss) var dismiss

    // Edit画面と同じ粒度の入力State
    @State private var name: String = ""
    @State private var gender: Gender? = nil
    @State private var personalityText: String = ""          // 自由入力
    @State private var speechCharacteristics: String = ""
    @State private var userCallingName: String = ""
    @State private var speechStyleText: String = ""
    @State private var avatarImage: UIImage? = nil

    @State private var showingSaveConfirmation = false
    @State private var showingImagePicker = false
    @State private var isLoadingImage = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    // プロフィール画像エリア（Editと同じ）
                    VStack(spacing: 12) {
                        Button(action: { showingImagePicker = true }) {
                            Group {
                                if isLoadingImage {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 100, height: 100)
                                        .overlay(
                                            ProgressView()
                                        )
                                } else if let avatarImage = avatarImage {
                                    Image(uiImage: avatarImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 4)
                                        )
                                        .shadow(radius: 5)
                                } else {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.red, .red.opacity(0.7)],
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
                                }
                            }
                        }

                        Text("写真を変更")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 32)

                    // ユーザー情報セクション（Editと同じ）
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

                    // キャラクター設定セクション（Editと同じ）
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

                    Spacer(minLength: 140)
                }
            }
            .background(Color(.systemGray6))
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Button {
                        createOshi()
                    } label: {
                        Text("登録")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .foregroundColor(.white)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                }
            }
            // トースト通知（Editと同じ）
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
        .navigationTitle("推しを作成")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("登録") {
                    createOshi()
                }
                .foregroundColor(.primary)
                .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerWithCrop(selectedImage: $avatarImage)
        }
    }

    private func createOshi() {
        Task {
            // 文字列 -> enum 変換（合わなければデフォルト）
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

            // 先にキャラを作成（画像URLは後で入れる）
            var newOshi = OshiCharacter(
                name: name.isEmpty ? "名無し" : name,
                gender: gender,
                personalityText: personalityText, 
                speechCharacteristics: speechCharacteristics,
                userCallingName: userCallingName,
                speechStyleText: speechStyleText,
                avatarImageURL: nil
            )

            // 画像がある場合はStorageにアップロードしてURLを保存
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

            // ここはあなたのViewModelの実装に合わせて呼び出し名を調整してください
            // 例: viewModel.addOshi(newOshi) / viewModel.createOshi(newOshi) など
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

// Color -> Hex
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

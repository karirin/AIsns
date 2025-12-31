//
//  PresetManagementView.swift
//  AIsns
//
//  Created by Apple on 2025/12/31.
//

import SwiftUI

struct PresetManagementView: View {
    // 画面専用のViewModelを作成（または親から渡してもOK）
    @StateObject private var viewModel = OshiViewModel()
    @State private var showingAddSheet = false

    var body: some View {
        List {
            ForEach(viewModel.recommendedOshis) { oshi in
                NavigationLink {
                    PresetEditView(viewModel: viewModel, originalOshi: oshi)
                } label: {
                    HStack {
                        // アイコン表示
                        if let url = oshi.avatarImageURL, let imageURL = URL(string: url) {
                            AsyncImage(url: imageURL) { image in
                                image.resizable()
                                     .scaledToFill()
                            } placeholder: {
                                Color.gray.opacity(0.3)
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(Text(oshi.name.prefix(1)).font(.caption))
                        }
                        
                        VStack(alignment: .leading) {
                            Text(oshi.name)
                                .font(.headline)
                            Text(oshi.personalityText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .onDelete(perform: deletePreset)
        }
        .navigationTitle("おすすめアカウント管理")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            NavigationStack {
                // 新規作成モード（originalOshi: nil）
                PresetEditView(viewModel: viewModel, originalOshi: nil)
            }
        }
        .task {
            // 画面表示時にデータ読み込み（ViewModelのinitで呼ばれているが念のため）
            if viewModel.recommendedOshis.isEmpty {
                await viewModel.loadData()
            }
        }
    }
    
    private func deletePreset(at offsets: IndexSet) {
        offsets.forEach { index in
            let oshi = viewModel.recommendedOshis[index]
            Task {
                await viewModel.deleteRecommendedOshi(oshi)
            }
        }
    }
}

// MARK: - 編集・作成画面

struct PresetEditView: View {
    @ObservedObject var viewModel: OshiViewModel
    @Environment(\.dismiss) var dismiss
    
    // 編集対象（nilなら新規作成）
    let originalOshi: OshiCharacter?
    
    // 入力フォーム用State
    @State private var name: String = ""
    @State private var gender: Gender? = nil
    @State private var personalityText: String = ""
    @State private var speechCharacteristics: String = ""
    @State private var userCallingName: String = ""
    @State private var speechStyleText: String = ""
    @State private var avatarImage: UIImage? = nil
    
    @State private var showingImagePicker = false
    @State private var isLoadingImage = false
    @State private var isSaving = false
    
    // 画像URL保持用（編集時）
    @State private var currentAvatarURL: String? = nil
    
    init(viewModel: OshiViewModel, originalOshi: OshiCharacter?) {
        self.viewModel = viewModel
        self.originalOshi = originalOshi
        
        // 初期値の設定
        if let oshi = originalOshi {
            _name = State(initialValue: oshi.name)
            _gender = State(initialValue: oshi.gender)
            _personalityText = State(initialValue: oshi.personalityText)
            _speechCharacteristics = State(initialValue: oshi.speechCharacteristics)
            _userCallingName = State(initialValue: oshi.userCallingName)
            _speechStyleText = State(initialValue: oshi.speechStyleText)
            _currentAvatarURL = State(initialValue: oshi.avatarImageURL)
        }
    }
    
    var body: some View {
        Form {
            Section("基本情報") {
                // アイコン画像
                HStack {
                    Spacer()
                    Button(action: { showingImagePicker = true }) {
                        if let image = avatarImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else if let urlString = currentAvatarURL, let url = URL(string: urlString) {
                            AsyncImage(url: url) { image in
                                image.resizable()
                                     .scaledToFill()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 100, height: 100)
                                .overlay(Image(systemName: "camera.fill").foregroundColor(.white))
                        }
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
                
                TextField("名前", text: $name)
                
                Picker("性別", selection: $gender) {
                    Text("未設定").tag(nil as Gender?)
                    ForEach(Gender.allCases, id: \.self) { gender in
                        Text(gender.rawValue).tag(gender as Gender?)
                    }
                }
            }
            
            Section("キャラクター設定") {
                TextField("性格（例: 優しい、ツンデレ）", text: $personalityText)
                TextField("話し方の特徴（例: 元気いっぱい）", text: $speechCharacteristics)
                TextField("ユーザーの呼び方（例: あなた、きみ）", text: $userCallingName)
                TextField("口調（例: 丁寧語、タメ口）", text: $speechStyleText)
            }
        }
        .navigationTitle(originalOshi == nil ? "プリセット作成" : "プリセット編集")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    savePreset()
                }
                .disabled(name.isEmpty || isSaving)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerWithCrop(selectedImage: $avatarImage)
        }
    }
    
    private func savePreset() {
        guard !name.isEmpty else { return }
        isSaving = true
        
        Task {
            // IDは既存のものがあれば使い、なければ新規生成
            let id = originalOshi?.id ?? UUID()
            var newImageURL = currentAvatarURL
            
            // 画像が変更されていればアップロード
            if let image = avatarImage {
                do {
                    // プリセット用も通常のOshiと同じStorageロジックを使用
                    newImageURL = try await FirebaseStorageManager.shared.uploadOshiAvatar(image, oshiId: id)
                } catch {
                    print("❌ 画像アップロード失敗: \(error)")
                }
            }
            
            let newOshi = OshiCharacter(
                id: id,
                name: name,
                gender: gender,
                personalityText: personalityText,
                speechCharacteristics: speechCharacteristics,
                userCallingName: userCallingName,
                speechStyleText: speechStyleText,
                avatarImageURL: newImageURL,
                // ✅ 修正: 存在しない intimacyLevel と isMutualFollow を削除
                totalInteractions: originalOshi?.totalInteractions ?? 0,
                isFollowingUser: originalOshi?.isFollowingUser ?? false,
                isFollowedByUser: originalOshi?.isFollowedByUser ?? false
            )
            
            await viewModel.updatePresetOshi(newOshi)
            
            await MainActor.run {
                isSaving = false
                dismiss()
            }
        }
    }
}


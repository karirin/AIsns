//
//  OnboardingFlowView.swift
//  AIsns
//
//  Created by Gemini
//  Updated: プリセット選択機能を追加
//

import SwiftUI

struct OnboardingFlowView: View {
    // 完了時のコールバック
    var onComplete: () -> Void
    
    // フローの状態管理
    enum OnboardingStep {
        case intro      // アプリ紹介
        case userSetup  // ユーザープロフィール作成
        case oshiSetup  // 推し作成・選択
    }
    
    @State private var currentStep: OnboardingStep = .intro
    @StateObject private var viewModel = OshiViewModel() // 推しデータ管理用
    
    var body: some View {
        ZStack {
            // 背景（全ステップ共通）
            Color(.systemBackground).ignoresSafeArea()
            
            switch currentStep {
            case .intro:
                IntroSlideView {
                    withAnimation { currentStep = .userSetup }
                }
                .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading)))
                
            case .userSetup:
                OnboardingUserSetupView {
                    withAnimation { currentStep = .oshiSetup }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                
            case .oshiSetup:
                OnboardingOshiSetupView(viewModel: viewModel) {
                    onComplete()
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            }
        }
    }
}

// MARK: - Step 1: Intro Slides
struct IntroSlideView: View {
    var onNext: () -> Void
    @State private var currentPage = 0
    
    private let gradient = LinearGradient(
        colors: [Color(red: 0.2, green: 0.7, blue: 1.0), Color(red: 0.5, green: 0.4, blue: 1.0)],
        startPoint: .leading, endPoint: .trailing
    )
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                slidePage(image: "sparkles", title: "AIとつながるSNS", desc: "AIフォロワーとの新しいコミュニケーションを\n楽しみましょう。").tag(0)
                slidePage(image: "person.2.fill", title: "自分だけのフォロワー", desc: "理想のキャラクターを作成して\nあなただけのパートナーに。").tag(1)
                slidePage(image: "message.bubble.fill", title: "楽しく会話", desc: "チャットや投稿で話しかけると\nAIが返信してくれます。").tag(2)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            Button(action: {
                if currentPage < 2 {
                    withAnimation { currentPage += 1 }
                } else {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    onNext()
                }
            }) {
                Text(currentPage < 2 ? "次へ" : "はじめる")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(gradient)
                    .cornerRadius(14)
            }
            .padding(24)
        }
    }
    
    private func slidePage(image: String, title: String, desc: String) -> some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: image)
                .font(.system(size: 80))
                .foregroundStyle(gradient)
            
            VStack(spacing: 16) {
                Text(title).font(.title).bold()
                Text(desc).multilineTextAlignment(.center).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
    }
}

// MARK: - Step 2: User Setup
struct OnboardingUserSetupView: View {
    var onNext: () -> Void
    
    @State private var name: String = ""
    @State private var avatarImage: UIImage?
    @State private var showImagePicker = false
    @State private var isSaving = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("プロフィール設定")
                .font(.title2).bold()
            
            Text("あなたの名前とアイコンを設定してください。\n（後からいつでも変更できます）")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // アイコン選択
            Button(action: { showImagePicker = true }) {
                ZStack {
                    if let image = avatarImage {
                        Image(uiImage: image)
                            .resizable().scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else {
                        Circle().fill(Color(.systemGray5))
                            .frame(width: 120, height: 120)
                        Image(systemName: "camera.fill")
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                }
                .overlay(Circle().stroke(Color.blue.opacity(0.3), lineWidth: 1))
            }
            
            // 名前入力
            TextField("名前を入力 (例: ゆう)", text: $name)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal, 32)
            
            Spacer()
            
            Button(action: saveAndNext) {
                if isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text("次へ")
                        .fontWeight(.bold)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(name.isEmpty ? Color.gray : Color.blue)
            .cornerRadius(14)
            .padding(24)
            .disabled(name.isEmpty || isSaving)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerWithCrop(selectedImage: $avatarImage)
        }
    }
    
    private func saveAndNext() {
        guard !name.isEmpty else { return }
        isSaving = true
        
        Task {
            do {
                var imageURL: String? = nil
                if let image = avatarImage {
                    imageURL = try await FirebaseStorageManager.shared.uploadUserAvatar(image, userId: FirebaseConfig.shared.userId)
                }
                
                try await FirebaseDatabaseManager.shared.saveUserProfile(
                    userName: name,
                    userBio: "",
                    avatarImageURL: imageURL
                )
                
                await MainActor.run {
                    isSaving = false
                    onNext()
                }
            } catch {
                print("Error saving user profile: \(error)")
                await MainActor.run { isSaving = false }
                onNext()
            }
        }
    }
}

// MARK: - Step 3: Oshi Creation or Selection
struct OnboardingOshiSetupView: View {
    @ObservedObject var viewModel: OshiViewModel
    var onComplete: () -> Void
    
    // カスタム作成用の入力State
    @State private var name: String = ""
    @State private var personality: String = ""
    @State private var tone: String = ""
    @State private var avatarImage: UIImage?
    @State private var showImagePicker = false
    @State private var isProcessing = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                SizedBox(height: 20)
                
                Text("最初のパートナーを選ぶ")
                    .font(.title2).bold()
                
                Text("気になるキャラクターをフォローするか、\n自分だけの推しを作成しましょう。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // ✅ おすすめプリセットの表示エリア (presetsテーブルのデータを表示)
                if !viewModel.recommendedOshis.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("おすすめのアカウント")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                // 候補を最大3人表示 (DBのsortOrder順)
                                ForEach(viewModel.recommendedOshis.prefix(4)) { oshi in
                                    PresetOshiCard(oshi: oshi) {
                                        selectPreset(oshi)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 8) // 影のための余白
                        }
                    }
                    .padding(.vertical, 8)
                } else if viewModel.isLoading {
                    // データ読み込み中の表示
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("おすすめを読み込み中...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                }
                
                // 「または」の区切り線
                HStack {
                    Rectangle().frame(height: 1).foregroundColor(Color(.systemGray5))
                    Text("または新規作成").font(.caption).foregroundColor(.secondary)
                    Rectangle().frame(height: 1).foregroundColor(Color(.systemGray5))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)

                // カスタム作成フォーム
                VStack(spacing: 16) {
                    // アイコン選択
                    Button(action: { showImagePicker = true }) {
                        ZStack {
                            if let image = avatarImage {
                                Image(uiImage: image)
                                    .resizable().scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                    .shadow(radius: 3)
                            } else {
                                Circle().fill(LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 100, height: 100)
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    inputField(title: "推しの名前", placeholder: "例: レン", text: $name)
                    inputField(title: "性格", placeholder: "例: 優しくて甘えん坊", text: $personality)
                    inputField(title: "口調", placeholder: "例: タメ口、語尾に「〜だよ」", text: $tone)
                    
                    Button(action: createCustomOshi) {
                        if isProcessing {
                            ProgressView().tint(.white)
                        } else {
                            Text("作成してはじめる")
                                .fontWeight(.bold)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(name.isEmpty ? Color.gray : Color.pink)
                    .cornerRadius(14)
                    .padding(.top, 8)
                    .disabled(name.isEmpty || isProcessing)
                }
                .padding(.horizontal, 24)
                
                SizedBox(height: 40)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerWithCrop(selectedImage: $avatarImage)
        }
    }
    
    private func inputField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption).foregroundColor(.secondary)
            TextField(placeholder, text: text)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
    }
    
    // ✅ プリセットを選択した場合の処理
    private func selectPreset(_ oshi: OshiCharacter) {
        guard !isProcessing else { return }
        isProcessing = true
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        Task {
            // ViewModelの既存メソッドを使ってフォロー＆セットアップ
            await viewModel.followRecommended(oshi)
            
            // 処理完了後、少し待ってから画面遷移（ユーザーへのフィードバック用）
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
            
            await MainActor.run {
                isProcessing = false
                onComplete()
            }
        }
    }
    
    // カスタム作成した場合の処理
    private func createCustomOshi() {
        guard !name.isEmpty else { return }
        isProcessing = true
        
        Task {
            // 推しキャラのモデル作成
            var newOshi = OshiCharacter(
                name: name,
                personalityText: personality,
                speechCharacteristics: "",
                userCallingName: "",
                speechStyleText: tone
            )
            
            // 画像アップロード
            if let image = avatarImage {
                do {
                    let url = try await FirebaseStorageManager.shared.uploadOshiAvatar(image, oshiId: newOshi.id)
                    newOshi.avatarImageURL = url
                } catch {
                    print("Image upload failed: \(error)")
                }
            }
            
            viewModel.addOshi(newOshi)
            
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            
            await MainActor.run {
                isProcessing = false
                onComplete()
            }
        }
    }
}

// ✅ プリセット表示用のカードビュー
struct PresetOshiCard: View {
    let oshi: OshiCharacter
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                // アイコン
                AsyncImage(url: URL(string: oshi.avatarImageURL ?? "")) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    ZStack {
                        Color.gray.opacity(0.1)
                        Text(String(oshi.name.prefix(1)))
                            .font(.title)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                VStack(spacing: 4) {
                    Text(oshi.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(oshi.personalityText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(height: 32) // 高さ固定でレイアウト崩れ防止
                }
                
                Text("フォローする")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(20)
            }
            .padding(16)
            .frame(width: 160, height: 220)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// レイアウト調整用
struct SizedBox: View {
    let height: CGFloat
    var body: some View { Spacer().frame(height: height) }
}

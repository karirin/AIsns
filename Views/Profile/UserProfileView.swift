//
//  UserProfileView.swift
//  AIsns
//
//  Created by Apple on 2025/12/27.
//  Updated: OshiProfileDetailViewスタイルに全面刷新
//

import SwiftUI

struct UserProfileView: View {
    @ObservedObject var viewModel: OshiViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var userName: String = "あなた"
    @State private var userBio: String = ""
    @State private var avatarImage: UIImage?
    @State private var showingEditSheet = false
    @State private var isLoadingImage = false
    @State private var avatarImageURL: String? = nil
    
    private let dbManager = FirebaseDatabaseManager.shared
    private let avatarSize: CGFloat = 100
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // アバターセクション
                avatarSection
                
                // プロフィール情報
                profileInfoSection
                
                // フォロー統計
                followStatsSection
                
                Divider()
                    .padding(.horizontal, 24)
                
                // コンテンツエリア（投稿など）
                contentSection
                
                // 管理者メニュー（該当者のみ）
                if FirebaseConfig.shared.userId == "3248012D-3F48-4449-9F99-D3C0D777D0D0" {
                    adminSection
                }
            }
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("プロフィールを編集", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                UserProfileEditView(
                    userName: $userName,
                    userBio: $userBio,
                    avatarImage: $avatarImage
                )
            }
        }
        .task {
            await loadProfile()
        }
    }
    
    // MARK: - Data Loading
    
    private func loadProfile() async {
        do {
            let profile = try await dbManager.loadUserProfile()
            await MainActor.run {
                userName = profile.userName
                userBio = profile.userBio
                avatarImageURL = profile.avatarImageURL
            }

            if let url = profile.avatarImageURL {
                isLoadingImage = true
                let img = try await FirebaseStorageManager.shared.downloadImage(from: url)
                await MainActor.run {
                    avatarImage = img
                    isLoadingImage = false
                }
            }
        } catch {
            print("❌ loadProfile error:", error.localizedDescription)
        }
    }
    
    // MARK: - Avatar Section
    
    private var avatarSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // 背景のグラデーションリング
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.pink.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: avatarSize + 12, height: avatarSize + 12)
                
                avatarView
            }
        }
    }
    
    private var avatarView: some View {
        Group {
            if isLoadingImage {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: avatarSize, height: avatarSize)
                    .overlay(
                        ProgressView()
                            .tint(.gray)
                    )
            } else if let image = avatarImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: avatarSize, height: avatarSize)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: avatarSize, height: avatarSize)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    )
            }
        }
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Profile Info Section
    
    private var profileInfoSection: some View {
        VStack(spacing: 12) {
            // 名前
            Text(userName)
                .font(.title2)
                .fontWeight(.bold)
            
            // 自己紹介
            if !userBio.isEmpty {
                Text(userBio)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
        }
    }
    
    // MARK: - Follow Stats Section
    
    private var followStatsSection: some View {
        HStack(spacing: 32) {
            StatColumn(value: viewModel.followerCount, label: "フォロワー")
            StatColumn(value: viewModel.followingCount, label: "フォロー中")
            StatColumn(value: viewModel.posts.filter { $0.isUserPost }.count, label: "投稿")
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Content Section
    
    private var contentSection: some View {
        VStack(spacing: 16) {
            // セクションヘッダー
            HStack {
                Text("ポスト")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                let userPosts = viewModel.posts.filter { $0.isUserPost }
                if !userPosts.isEmpty {
                    Text("\(userPosts.count)件")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            
            let userPosts = viewModel.posts.filter { $0.isUserPost }
            
            if userPosts.isEmpty {
                emptyContentView(
                    icon: "square.and.pencil",
                    title: "まだポストがありません",
                    subtitle: "最初の投稿をしてみましょう"
                )
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(userPosts) { post in
                        PostCardView(post: post, viewModel: viewModel)
                        
                        if post.id != userPosts.last?.id {
                            Divider()
                                .padding(.leading, 68)
                        }
                    }
                }
                .background(Color(.systemBackground))
            }
        }
    }
    
    // MARK: - Admin Section
    
    private var adminSection: some View {
        VStack(spacing: 16) {
            Divider()
                .padding(.horizontal, 24)
                .padding(.top, 16)

            HStack {
                Text("管理者メニュー")
                    .font(.headline)
                    .foregroundColor(.red)
                
                Spacer()
            }
            .padding(.horizontal, 24)

            NavigationLink {
                PresetManagementView()
            } label: {
                HStack {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 18))
                        .foregroundColor(.red)
                    
                    Text("おすすめアカウント管理")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color(.systemBackground))
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func emptyContentView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 40)
            
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 80, height: 80)
                
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
                .frame(height: 60)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
    }
}

// MARK: - Stat Column Component

struct StatColumn: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Edit View

struct UserProfileEditView: View {
    @Binding var userName: String
    @Binding var userBio: String
    @Binding var avatarImage: UIImage?
    
    @Environment(\.dismiss) var dismiss
    @State private var editingName: String = ""
    @State private var editingBio: String = ""
    @State private var showingImagePicker = false
    @State private var showingSaveConfirmation = false
    @State private var isLoadingImage = false
    private let dbManager = FirebaseDatabaseManager.shared
    @State private var isSaving = false
    
    init(userName: Binding<String>, userBio: Binding<String>, avatarImage: Binding<UIImage?>) {
        self._userName = userName
        self._userBio = userBio
        self._avatarImage = avatarImage
        self._editingName = State(initialValue: userName.wrappedValue)
        self._editingBio = State(initialValue: userBio.wrappedValue)
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    // プロフィール画像エリア
                    VStack(spacing: 12) {
                        Button(action: {
                            generateHapticFeedback()
                            showingImagePicker = true
                        }) {
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
                                                colors: [
                                                    Color(red: 0.2, green: 0.7, blue: 1.0),
                                                    Color(red: 0.5, green: 0.4, blue: 1.0)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 100, height: 100)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 40))
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
                    
                    // 基本情報セクション
                    VStack(spacing: 0) {
                        Text("基本情報")
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
                                
                                TextField("", text: $editingName)
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
                            
                            // 自己紹介
                            NavigationLink {
                                BioEditView(bio: $editingBio)
                            } label: {
                                HStack {
                                    Text("自己紹介")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text(editingBio.isEmpty ? "追加" : editingBio)
                                        .font(.subheadline)
                                        .foregroundColor(editingBio.isEmpty ? .secondary : .primary)
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
        .navigationTitle("プロフィールを編集")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("キャンセル") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    Task { await saveChanges() }
                }
                .foregroundColor(.primary)
                .fontWeight(.semibold)
                .disabled(isSaving)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerWithCrop(selectedImage: $avatarImage)
        }
    }
    
    @MainActor
    private func saveChanges() async {
        isSaving = true
        defer { isSaving = false }

        do {
            let uid = FirebaseConfig.shared.userId

            var newAvatarURL: String? = nil
            if let img = avatarImage {
                isLoadingImage = true
                newAvatarURL = try await FirebaseStorageManager.shared.uploadUserAvatar(img, userId: uid)
                isLoadingImage = false
            }

            try await dbManager.saveUserProfile(
                userName: editingName,
                userBio: editingBio,
                avatarImageURL: newAvatarURL
            )

            userName = editingName
            userBio = editingBio

            withAnimation { showingSaveConfirmation = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation { showingSaveConfirmation = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    dismiss()
                }
            }

        } catch {
            print("❌ save profile error:", error.localizedDescription)
        }
    }
}

// MARK: - Bio Edit View

struct BioEditView: View {
    @Binding var bio: String
    @Environment(\.dismiss) var dismiss
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            TextField("自己紹介を入力", text: $bio, axis: .vertical)
                .focused($isFocused)
                .padding()
                .font(.body)
                .lineLimit(3...10)
            
            Spacer()
        }
        .navigationTitle("自己紹介")
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

// MARK: - Stat Row

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        UserProfileView(viewModel: OshiViewModel(mock: true))
    }
}

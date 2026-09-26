//
//  UserProfileView.swift
//  AIsns
//
//  Created by Apple on 2025/12/27.
//  Updated: モダンSNSスタイルに刷新
//

import SwiftUI

struct UserProfileView: View {
    @ObservedObject var viewModel: OshiViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var userName: String = "ユーザー"
    @State private var userBio: String = ""
    @State private var avatarImage: UIImage?
    @State private var showingEditSheet = false
    @State private var isLoadingImage = false
    @State private var avatarImageURL: String? = nil
    @State private var selectedTab: ProfileTab = .posts
    @State private var showingSettings = false
    
    private let dbManager = FirebaseDatabaseManager.shared
    private let avatarSize: CGFloat = 86
    private let headerHeight: CGFloat = 140
    
    enum ProfileTab: String, CaseIterable {
        case posts = "投稿"
        case likes = "いいね"
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // バナー + アバター
                ZStack(alignment: .bottom) {
                    AppColors.primaryGradient
                        .frame(height: headerHeight)
                        .overlay(
                            // 装飾的な円
                            GeometryReader { geo in
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.12))
                                        .frame(width: 160, height: 160)
                                        .offset(x: geo.size.width - 80, y: -60)
                                    Circle()
                                        .fill(Color.white.opacity(0.08))
                                        .frame(width: 120, height: 120)
                                        .offset(x: -30, y: 60)
                                }
                            }
                            .clipped()
                        )

                    avatarView
                        .offset(y: avatarSize / 2)
                }
                .padding(.bottom, avatarSize / 2)

                // プロフィール情報
                profileSection
                    .padding(.top, 10)

                // タブセクション
                tabSection
                    .padding(.top, 20)

                // コンテンツ
                contentSection

                // 管理者メニュー
                if FirebaseConfig.shared.userId == "43F74A75-89A5-48EE-9372-5B350504CD35" {
                    adminSection
                        .padding(.top, 24)
                }
            }
            .padding(.bottom, 32)
        }
        .background(AuroraBackground())
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 80 {
                        dismiss()
                    }
                }
        )
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                        )
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "gearshape")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                        )
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
        .fullScreenCover(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView(
                    viewModel: viewModel,
                    userName: $userName,
                    userBio: $userBio,
                    avatarImage: $avatarImage
                )
            }
        }
        .task {
            await loadProfile()
            await viewModel.loadUserLikes()
        }
        .onChange(of: userName) { newName in
            let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedName.isEmpty {
                viewModel.userProfileName = trimmedName == "あなた" ? "ユーザー" : trimmedName
            }
        }
    }
    
    private var avatarView: some View {
        ZStack {
            // 背景のリング
            Circle()
                .fill(AppColors.canvas)
                .frame(width: avatarSize + 10, height: avatarSize + 10)

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
                        .fill(AppColors.primaryGradient)
                        .frame(width: avatarSize, height: avatarSize)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                        )
                }
            }
            .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
        }
    }
    
    // MARK: - Profile Section
    
    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 名前
            Text(userName)
                .font(.title2)
                .fontWeight(.bold)
            
            // 自己紹介
            if !userBio.isEmpty {
                Text(userBio)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineSpacing(3)
            }
            
            // フォロー統計（横並び）
            HStack(spacing: 16) {
                // ボタンをNavigationLinkに変更
                NavigationLink {
                    FollowListView(title: "フォロー中", type: .following, viewModel: viewModel)
                } label: {
                    HStack(spacing: 4) {
                        Text("\(viewModel.followingCount)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("フォロー中")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // フォロワー一覧へ（必要なら実装、今回はボタンのまま）
                Button {
                    // 将来的に実装
                } label: {
                    HStack(spacing: 4) {
                        Text("\(viewModel.followerCount)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("フォロワー")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                // 編集ボタン
                Button {
                    generateHapticFeedback()
                    showingEditSheet = true
                } label: {
                    Text("編集")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(AppColors.primary.opacity(0.12))
                        )
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Tab Section
    
    private var tabSection: some View {
        PillSegmentedControl(
            items: ProfileTab.allCases.map { (value: $0, label: $0.rawValue) },
            selection: $selectedTab
        )
        .padding(.horizontal, DesignTokens.Spacing.md)
    }
    
    // MARK: - Content Section
    
    private var contentSection: some View {
        Group {
            switch selectedTab {
            case .posts:
                postsContent
            case .likes:
                likesContent
            }
        }
    }
    
    private var postsContent: some View {
        let userPosts = viewModel.posts.filter { $0.isUserPost }
        
        return Group {
            if userPosts.isEmpty {
                emptyStateView(
                    icon: "text.bubble",
                    title: "まだ投稿がありません",
                    subtitle: "あなたの投稿がここに表示されます"
                )
            } else {
                LazyVStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(userPosts) { post in
                        PostCardView(post: post, viewModel: viewModel)
                            .padding(.horizontal, DesignTokens.Spacing.sm)
                    }
                }
                .padding(.top, DesignTokens.Spacing.md)
            }
        }
    }
    
    private var likesContent: some View {
        let likedPosts = viewModel.posts.filter { viewModel.hasUserReacted(to: $0) }
        
        return Group {
            if likedPosts.isEmpty {
                emptyStateView(
                    icon: "heart",
                    title: "まだいいねがありません",
                    subtitle: "いいねした投稿がここに表示されます"
                )
            } else {
                LazyVStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(likedPosts) { post in
                        PostCardView(post: post, viewModel: viewModel)
                            .padding(.horizontal, DesignTokens.Spacing.sm)
                    }
                }
                .padding(.top, DesignTokens.Spacing.md)
            }
        }
    }
    
    private func emptyStateView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 60)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.primary.opacity(0.08),
                                AppColors.pink.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 96, height: 96)

                Image(systemName: icon)
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(AppColors.primaryGradient)
            }

            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
                .frame(height: 80)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Admin Section
    
    private var adminSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("管理者メニュー")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.red)
                .padding(.horizontal, 16)
            
            NavigationLink {
                PresetManagementView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "person.badge.shield.checkmark")
                        .font(.system(size: 18))
                        .foregroundColor(.red)
                        .frame(width: 28)
                    
                    Text("おすすめアカウント管理")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColors.textTertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .floatingCardStyle()
                .padding(.horizontal, DesignTokens.Spacing.sm)
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadProfile() async {
        do {
            let profile = try await dbManager.loadUserProfile()
            await MainActor.run {
                userName = profile.userName
                viewModel.userProfileName = profile.userName
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
}

// MARK: - Preview

#Preview {
    NavigationStack {
        UserProfileView(viewModel: OshiViewModel(mock: true))
    }
}

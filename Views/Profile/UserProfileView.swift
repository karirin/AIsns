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
    
    @State private var userName: String = "あなた"
    @State private var userBio: String = ""
    @State private var avatarImage: UIImage?
    @State private var showingEditSheet = false
    @State private var isLoadingImage = false
    @State private var avatarImageURL: String? = nil
    @State private var selectedTab: ProfileTab = .posts
    
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
                avatarView
                
                // プロフィール情報
                profileSection
                    .padding(.top, 10)
                
                // タブセクション
                tabSection
                    .padding(.top, 20)
                
                // コンテンツ
                contentSection
                
                // 管理者メニュー
                if FirebaseConfig.shared.userId == "3248012D-3F48-4449-9F99-D3C0D777D0D0" {
                    adminSection
                        .padding(.top, 24)
                }
            }
            .padding(.bottom, 32)
        }
//        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
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
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("プロフィールを編集", systemImage: "pencil")
                    }
                } label: {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "ellipsis")
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
        .task {
            await loadProfile()
            await viewModel.loadUserLikes()
        }
    }
    
    private var avatarView: some View {
        ZStack {
            // 背景の白い円
            Circle()
                .fill(Color(.systemBackground))
                .frame(width: avatarSize + 8, height: avatarSize + 8)
            
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
                                colors: [
                                    Color(red: 0.5, green: 0.7, blue: 1.0),
                                    Color(red: 0.7, green: 0.5, blue: 0.9)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: avatarSize, height: avatarSize)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                        )
                }
            }
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
                Button {
                    // フォロー中一覧へ
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
                
                Button {
                    // フォロワー一覧へ
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
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color(.systemBackground))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color(.separator), lineWidth: 1)
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
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(ProfileTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 10) {
                            Text(tab.rawValue)
                                .font(.subheadline)
                                .fontWeight(selectedTab == tab ? .semibold : .regular)
                                .foregroundColor(selectedTab == tab ? .primary : .secondary)
                            
                            Rectangle()
                                .fill(selectedTab == tab ? Color.primary : Color.clear)
                                .frame(height: 2)
                                .animation(.easeInOut(duration: 0.2), value: selectedTab)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            
            Divider()
        }
//        .background(Color(.systemBackground))
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
                LazyVStack(spacing: 0) {
                    ForEach(userPosts) { post in
                        PostCardView(post: post, viewModel: viewModel)
                        
                        Divider()
                            .padding(.leading, 68)
                    }
                }
                .background(Color(.systemBackground))
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
                LazyVStack(spacing: 0) {
                    ForEach(likedPosts) { post in
                        PostCardView(post: post, viewModel: viewModel)
                        
                        Divider()
                            .padding(.leading, 68)
                    }
                }
                .background(Color(.systemBackground))
            }
        }
    }
    
    private func emptyStateView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 60)
            
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundColor(.secondary.opacity(0.6))
            
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
                .background(Color(.systemBackground))
            }
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
}

// MARK: - Preview

#Preview {
    NavigationStack {
        UserProfileView(viewModel: OshiViewModel(mock: true))
    }
}

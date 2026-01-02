//
//  TimelineView.swift
//  AIsns
//
//  Updated: 2026/01/02 - Complete UI/UX Redesign
//

import SwiftUI
import PhotosUI

// MARK: - Sidebar Destination

enum SidebarDestination: Hashable {
    case profile
    case followers
    case chat
    case notifications
    case bookmarks
    case settings
}

// MARK: - Timeline Tab

enum TimelineTab: String, CaseIterable {
    case forYou = "おすすめ"
    case following = "フォロー中"
}

// MARK: - Timeline Screen View

struct TimelineScreenView: View {
    @ObservedObject var viewModel: OshiViewModel
    @State private var showingPostSheet = false
    @State private var showingSidebar = false
    @State private var navigationPath = NavigationPath()
    @State private var userAvatarImage: UIImage?
    @State private var isLoadingUserAvatar = false
    @State private var userName: String = "あなた"
    @State private var selectedTab: TimelineTab = .forYou
    @State private var showingSearch = false
    @Namespace private var tabNamespace
    
    private let dbManager = FirebaseDatabaseManager.shared
    
    // フィルタリングされた投稿
    private var filteredPosts: [Post] {
        switch selectedTab {
        case .forYou:
            return viewModel.timelinePosts
        case .following:
            return viewModel.timelinePosts.filter { post in
                if let authorId = post.authorId {
                    return viewModel.followingOshiIds.contains(authorId)
                }
                return post.isUserPost
            }
        }
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .leading) {
                // メインコンテンツ
                mainContent
                    .offset(x: showingSidebar ? 280 : 0)
                    .scaleEffect(showingSidebar ? 0.92 : 1.0)
                    .disabled(showingSidebar)
                
                // オーバーレイ
                if showingSidebar {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .offset(x: showingSidebar ? 280 : 0)
                        .onTapGesture {
                            withAnimation(DesignTokens.Animation.spring) {
                                showingSidebar = false
                            }
                        }
                }
                
                // サイドバー
                SidebarMenuView(
                    userName: userName,
                    userAvatarImage: userAvatarImage,
                    viewModel: viewModel,
                    onClose: {
                        withAnimation(DesignTokens.Animation.spring) {
                            showingSidebar = false
                        }
                    },
                    onNavigate: { destination in
                        navigateAndCloseSidebar(destination)
                    }
                )
                .offset(x: showingSidebar ? 0 : -300)
            }
            .navigationBarHidden(true)
            .navigationDestination(for: SidebarDestination.self) { destination in
                switch destination {
                case .profile:
                    UserProfileView(viewModel: viewModel)
                case .followers:
                    OshiListView(viewModel: viewModel, isPresented: .constant(true))
                case .chat:
                    ChatListView(viewModel: viewModel, isPresented: .constant(true))
                case .notifications:
                    NotificationView(viewModel: viewModel, isPresented: .constant(true))
                case .bookmarks:
                    BookmarkListView(viewModel: viewModel)
                case .settings:
                    EmptyView()
                }
            }
            .task {
                await loadInitialData()
            }
            .sheet(isPresented: $showingPostSheet) {
                PostComposerView(viewModel: viewModel, isPresented: $showingPostSheet)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .global)
                .onEnded { value in
                    let dx = value.translation.width
                    let dy = value.translation.height
                    guard abs(dx) > abs(dy) else { return }
                    
                    withAnimation(DesignTokens.Animation.spring) {
                        if dx > 60, !showingSidebar {
                            showingSidebar = true
                        }
                        if dx < -60, showingSidebar {
                            showingSidebar = false
                        }
                    }
                }
        )
    }
    
    // MARK: - Data Loading
    
    private func loadInitialData() async {
        do {
            let profile = try await dbManager.loadUserProfile()
            userName = profile.userName
            
            if let url = profile.avatarImageURL {
                isLoadingUserAvatar = true
                userAvatarImage = try? await FirebaseStorageManager.shared.downloadImage(from: url)
                isLoadingUserAvatar = false
            }
            
            await viewModel.loadUserReposts()
            await viewModel.loadUserLikes()
            await viewModel.loadUserBookmarks()
        } catch {
            print("❌ Timeline load error:", error.localizedDescription)
            isLoadingUserAvatar = false
        }
    }
    
    private func navigateAndCloseSidebar(_ destination: SidebarDestination) {
        generateHapticFeedback()
        navigationPath.append(destination)
        withAnimation(DesignTokens.Animation.spring) {
            showingSidebar = false
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            // ヘッダー
            headerView
            
            // タブバー
            tabBarView
            
            // コンテンツ
            Group {
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    LoadingView(
                        message: "読み込み中...",
                        subtitle: "最新の投稿を取得しています"
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredPosts.isEmpty {
                    timelineEmptyView
                } else {
                    timelineScrollView
                }
            }
        }
        .background(AppColors.backgroundPrimary)
        .overlay(alignment: .bottomTrailing) {
            FloatingActionButton(icon: "plus") {
                generateHapticFeedback()
                showingPostSheet = true
            }
            .padding(.trailing, DesignTokens.Spacing.lg)
            .padding(.bottom, DesignTokens.Spacing.xl)
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // プロフィールボタン
            Button {
                generateHapticFeedback()
                withAnimation(DesignTokens.Animation.spring) {
                    showingSidebar.toggle()
                }
            } label: {
                profileButton
            }
            
            Spacer()
            
            // ロゴ
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppColors.primaryGradient)
                
                Text("AIsns")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryGradient)
            }
            
            Spacer()
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(
            AppColors.backgroundPrimary
                .shadow(color: Color.black.opacity(0.03), radius: 1, y: 1)
        )
    }
    
    // MARK: - Profile Button
    
    private var profileButton: some View {
        Group {
            if isLoadingUserAvatar {
                SkeletonView(width: 32, height: 32, cornerRadius: 16)
            } else {
                AvatarView(
                    image: userAvatarImage,
                    name: userName,
                    size: 32,
                    placeholderGradient: AppColors.primaryGradient
                )
            }
        }
    }
    
    // MARK: - Tab Bar View
    
    private var tabBarView: some View {
        HStack(spacing: 0) {
            ForEach(TimelineTab.allCases, id: \.self) { tab in
                Button {
                    generateHapticFeedback()
                    withAnimation(DesignTokens.Animation.spring) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: DesignTokens.Spacing.xs) {
                        Text(tab.rawValue)
                            .font(selectedTab == tab ? AppTypography.bodyMedium : AppTypography.body)
                            .foregroundColor(selectedTab == tab ? AppColors.textPrimary : AppColors.textSecondary)
                        
                        // インジケーター
                        ZStack {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 3)
                            
                            if selectedTab == tab {
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(AppColors.primaryGradientH)
                                    .frame(width: 48, height: 3)
                                    .matchedGeometryEffect(id: "tabIndicator", in: tabNamespace)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, DesignTokens.Spacing.xxs)
        .background(AppColors.backgroundPrimary)
        .overlay(
            AppDivider(),
            alignment: .bottom
        )
    }
    
    // MARK: - Empty State
    
    private var timelineEmptyView: some View {
        ScrollView {
            EmptyStateView(
                icon: "bubble.left.and.bubble.right",
                title: selectedTab == .following ? "フォロー中の投稿がありません" : "タイムラインがまだ空です",
                subtitle: selectedTab == .following
                    ? "アカウントをフォローすると\nここに投稿が表示されます"
                    : "新しい投稿を作成するか\nアカウントをフォローしてみましょう",
                actionTitle: "アカウントを探す",
                action: {
                    generateHapticFeedback()
                    navigationPath.append(SidebarDestination.followers)
                }
            )
            .padding(.top, DesignTokens.Spacing.xxxxl)
        }
        .refreshable {
            await viewModel.loadData()
        }
    }
    
    // MARK: - Timeline Scroll View
    
    private var timelineScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredPosts) { post in
                    PostCardView(post: post, viewModel: viewModel)
                    
                    AppDivider(leadingPadding: 68)
                }
            }
            .padding(.bottom, 100)
        }
        .refreshable {
            await viewModel.loadData()
        }
    }
}

// MARK: - Sidebar Menu View

struct SidebarMenuView: View {
    let userName: String
    let userAvatarImage: UIImage?
    @ObservedObject var viewModel: OshiViewModel
    let onClose: () -> Void
    let onNavigate: (SidebarDestination) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            sidebarHeader
            
            AppDivider()
            
            // メニュー項目
            ScrollView(showsIndicators: false) {
                VStack(spacing: DesignTokens.Spacing.xxs) {
                    SidebarMenuItem(icon: "person", title: "プロフィール") {
                        onNavigate(.profile)
                    }
                    
                    SidebarMenuItem(
                        icon: "star",
                        title: "フォロワー",
                        badge: viewModel.oshiList.count
                    ) {
                        onNavigate(.followers)
                    }
                    
                    SidebarMenuItem(
                        icon: "message",
                        title: "メッセージ",
                        badge: viewModel.chatRooms.reduce(0) { $0 + $1.unreadCount }
                    ) {
                        onNavigate(.chat)
                    }
                    
                    SidebarMenuItem(
                        icon: "bell",
                        title: "通知",
                        badge: viewModel.unreadNotificationCount
                    ) {
                        onNavigate(.notifications)
                    }
                    
                    SidebarMenuItem(icon: "bookmark", title: "ブックマーク") {
                        onNavigate(.bookmarks)
                    }
                    
                    AppDivider()
                        .padding(.vertical, DesignTokens.Spacing.sm)
                    
                    SidebarMenuItem(icon: "gearshape", title: "設定") {
                        onNavigate(.settings)
                    }
                }
                .padding(.vertical, DesignTokens.Spacing.sm)
            }
            
            Spacer()
            
            // フッター
            HStack {
                Button {
                    // ダークモード切り替え
                } label: {
                    Image(systemName: "moon")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
            }
            .padding(DesignTokens.Spacing.lg)
        }
        .frame(width: 280)
        .background(AppColors.backgroundPrimary)
        .ignoresSafeArea()
    }
    
    private var sidebarHeader: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            // プロフィール情報
            HStack {
                AvatarView(
                    image: userAvatarImage,
                    name: userName,
                    size: DesignTokens.AvatarSize.lg,
                    placeholderGradient: AppColors.primaryGradient
                )
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(AppColors.backgroundSecondary)
                        .clipShape(Circle())
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(userName)
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("@\(userName.lowercased().replacingOccurrences(of: " ", with: "_"))")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            // フォロー数
            HStack(spacing: DesignTokens.Spacing.lg) {
                HStack(spacing: 4) {
                    Text("\(viewModel.followingCount)")
                        .font(AppTypography.subheadlineMedium)
                        .foregroundColor(AppColors.textPrimary)
                    Text("フォロー中")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                HStack(spacing: 4) {
                    Text("\(viewModel.followerCount)")
                        .font(AppTypography.subheadlineMedium)
                        .foregroundColor(AppColors.textPrimary)
                    Text("フォロワー")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .padding(.top, DesignTokens.Spacing.xxxl)
    }
}

// MARK: - Sidebar Menu Item

struct SidebarMenuItem: View {
    let icon: String
    let title: String
    var badge: Int? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 28)
                
                Text(title)
                    .font(AppTypography.calloutMedium)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                if let badge = badge, badge > 0 {
                    BadgeView(count: badge, size: 18, gradient: AppColors.primaryGradientH)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Post Card View

struct PostCardView: View {
    let post: Post
    @ObservedObject var viewModel: OshiViewModel
    var isNavigable: Bool = true
    
    @State private var avatarImage: UIImage?
    @State private var postImages: [UIImage] = []
    @State private var userAvatarImage: UIImage?
    @State private var isLikeAnimating = false

    var oshi: OshiCharacter? {
        if let authorId = post.authorId {
            return viewModel.oshiList.first { $0.id == authorId }
        }
        return nil
    }
    
    var hasUserLiked: Bool {
        viewModel.hasUserReacted(to: post)
    }

    var body: some View {
        Group {
            if isNavigable {
                NavigationLink {
                    PostDetailView(post: post, viewModel: viewModel)
                } label: {
                    cardContent
                }
                .buttonStyle(.plain)
            } else {
                cardContent
            }
        }
        .task {
            await loadImages()
        }
    }
    
    private func loadImages() async {
        // 推しのアバター
        if let oshi = oshi, let urlString = oshi.avatarImageURL {
            avatarImage = try? await FirebaseStorageManager.shared.downloadImage(from: urlString)
        }
        
        // ユーザーのアバター
        if post.isUserPost, let url = viewModel.userProfileAvatarURL {
            userAvatarImage = try? await FirebaseStorageManager.shared.downloadImage(from: url)
        }
        
        // 投稿画像
        if !post.imageURLs.isEmpty && postImages.count != post.imageURLs.count {
            var loaded: [UIImage] = []
            for imageURL in post.imageURLs {
                if let image = try? await FirebaseStorageManager.shared.downloadImage(from: imageURL) {
                    loaded.append(image)
                }
            }
            await MainActor.run {
                self.postImages = loaded
            }
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // リポストヘッダー
            if viewModel.isReposted(post) && !post.isUserPost {
                repostHeader
            }
            
            HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                // アバター
                avatarView

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    // ヘッダー
                    postHeader
                    
                    // 投稿内容
                    if !post.content.isEmpty {
                        Text(post.content)
                            .font(AppTypography.body)
                            .lineSpacing(4)
                            .foregroundColor(AppColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // 投稿画像
                    if !postImages.isEmpty {
                        postImageGrid
                            .padding(.top, DesignTokens.Spacing.xs)
                    }

                    // アクションボタン
                    actionButtons
                        .padding(.top, DesignTokens.Spacing.sm)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
        .background(AppColors.backgroundPrimary)
    }
    
    // MARK: - Repost Header
    
    private var repostHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.2.squarepath")
                .font(.system(size: 12, weight: .medium))
            Text("\(viewModel.userProfileName)がリポスト")
                .font(AppTypography.footnote)
        }
        .foregroundColor(AppColors.textSecondary)
        .padding(.leading, 56)
        .padding(.top, DesignTokens.Spacing.xs)
        .padding(.bottom, 2)
    }
    
    // MARK: - Avatar View
    
    private var avatarView: some View {
        Group {
            if let oshi = oshi {
                AvatarView(
                    image: avatarImage,
                    name: oshi.name,
                    size: DesignTokens.AvatarSize.md,
                    placeholderGradient: AppColors.pinkGradient
                )
            } else {
                AvatarView(
                    image: post.isUserPost ? userAvatarImage : nil,
                    name: post.isUserPost ? viewModel.userProfileName : post.authorName,
                    size: DesignTokens.AvatarSize.md,
                    placeholderGradient: AppColors.primaryGradient
                )
            }
        }
    }
    
    // MARK: - Post Header
    
    private var postHeader: some View {
        HStack(spacing: 4) {
            Group {
                if let oshi = oshi {
                    Text(oshi.name)
                } else {
                    Text(post.isUserPost ? viewModel.userProfileName : post.authorName)
                }
            }
            .font(AppTypography.bodyMedium)
            .foregroundColor(AppColors.textPrimary)
            .lineLimit(1)

            if post.isUserPost {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.primary)
            }

            Text("·")
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textSecondary)

            RelativeTimeText(date: post.timestamp)
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textSecondary)

            Spacer()
        }
    }
    
    // MARK: - Post Image Grid
    
    private var postImageGrid: some View {
        let columns: [GridItem] = postImages.count == 1
            ? [GridItem(.flexible())]
            : [GridItem(.flexible()), GridItem(.flexible())]
        
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(postImages.enumerated()), id: \.offset) { index, image in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: postImages.count == 1 ? 220 : 130)
                    .clipped()
                    .cornerRadius(DesignTokens.Radius.md)
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 0) {
            // コメント
            ActionButtonView(
                icon: "bubble.left",
                count: post.commentCount,
                activeColor: AppColors.primary
            ) {
                // コメント
            }
            
            Spacer()
            
            // リポスト
            ActionButtonView(
                icon: "arrow.2.squarepath",
                count: post.repostCount,
                isActive: viewModel.isReposted(post),
                activeColor: AppColors.success
            ) {
                generateHapticFeedback()
                viewModel.toggleRepost(for: post)
            }
            
            Spacer()
            
            // いいね
            ActionButtonView(
                icon: "heart",
                count: post.reactionCount,
                isActive: hasUserLiked,
                activeColor: AppColors.pink
            ) {
                generateHapticFeedback()
                withAnimation(DesignTokens.Animation.bouncy) {
                    isLikeAnimating = true
                }
                viewModel.toggleUserReaction(on: post)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isLikeAnimating = false
                }
            }
            .scaleEffect(isLikeAnimating && hasUserLiked ? 1.3 : 1.0)
            
            Spacer()
            
            // ブックマーク
            ActionButtonView(
                icon: "bookmark",
                isActive: viewModel.isBookmarked(post),
                activeColor: AppColors.primary
            ) {
                generateHapticFeedback()
                viewModel.toggleBookmark(for: post)
            }
            
            Spacer()
        }
    }
}

// MARK: - Post Composer View

struct PostComposerView: View {
    @ObservedObject var viewModel: OshiViewModel
    @Binding var isPresented: Bool
    @State private var postText = ""
    @State private var selectedImages: [UIImage] = []
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var isUploading = false
    @FocusState private var isTextFieldFocused: Bool
    
    var canPost: Bool {
        (!postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !selectedImages.isEmpty)
        && postText.count <= 280
        && selectedImages.count <= 4
        && !isUploading
    }
    
    private var characterCountColor: Color {
        if postText.count > 280 { return AppColors.error }
        if postText.count > 260 { return AppColors.warning }
        return AppColors.primary
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        // テキストエディタ
                        ZStack(alignment: .topLeading) {
                            if postText.isEmpty {
                                Text("いまどうしてる？")
                                    .font(AppTypography.callout)
                                    .foregroundColor(AppColors.textTertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                            }
                            
                            TextEditor(text: $postText)
                                .focused($isTextFieldFocused)
                                .font(AppTypography.callout)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 120)
                        }
                        .padding(.horizontal, DesignTokens.Spacing.md)
                        
                        // 選択された画像
                        if !selectedImages.isEmpty {
                            imagePreviewGrid
                                .padding(.horizontal, DesignTokens.Spacing.md)
                        }
                    }
                    .padding(.top, DesignTokens.Spacing.sm)
                }
                
                // ツールバー
                toolbarView
            }
            .navigationTitle("新規投稿")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                    .foregroundColor(AppColors.textPrimary)
                    .disabled(isUploading)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    postButton
                }
            }
            .onTapGesture {
                UIApplication.shared.endEditing()
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isTextFieldFocused = true
                }
            }
        }
    }
    
    // MARK: - Toolbar
    
    private var toolbarView: some View {
        HStack {
            HStack(spacing: DesignTokens.Spacing.lg) {
                // 画像選択
                PhotosPicker(
                    selection: $selectedPhotos,
                    maxSelectionCount: 4,
                    matching: .images
                ) {
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                        .foregroundColor(
                            selectedImages.count >= 4
                            ? AppColors.textTertiary
                            : AppColors.primary
                        )
                }
                .disabled(selectedImages.count >= 4)
                .onChange(of: selectedPhotos) { newItems in
                    Task {
                        await loadImages(from: newItems)
                    }
                }
            }
            .padding(.leading, DesignTokens.Spacing.md)
            
            Spacer()
            
            // 文字数カウンター
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 2)
                    .frame(width: 24, height: 24)
                
                Circle()
                    .trim(from: 0, to: CGFloat(min(postText.count, 280)) / 280)
                    .stroke(
                        characterCountColor,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: 24, height: 24)
                    .rotationEffect(.degrees(-90))
            }
            .padding(.trailing, DesignTokens.Spacing.sm)
            
            if postText.count > 260 {
                Text("\(280 - postText.count)")
                    .font(AppTypography.caption)
                    .foregroundColor(characterCountColor)
                    .padding(.trailing, DesignTokens.Spacing.md)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(AppColors.backgroundPrimary)
        .overlay(AppDivider(), alignment: .top)
    }
    
    // MARK: - Post Button
    
    private var postButton: some View {
        Button {
            Task {
                await createPost()
            }
        } label: {
            if isUploading {
                ProgressView()
                    .tint(.white)
                    .frame(width: 70, height: 32)
                    .background(AppColors.primary.opacity(0.5))
                    .clipShape(Capsule())
            } else {
                Text("投稿")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    .padding(.vertical, DesignTokens.Spacing.xs)
                    .background(
                        canPost
                        ? AppColors.primaryGradientH
                        : LinearGradient(colors: [.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(Capsule())
            }
        }
        .disabled(!canPost)
        .pressableStyle()
    }
    
    // MARK: - Image Preview Grid
    
    private var imagePreviewGrid: some View {
        let columns = selectedImages.count == 1
            ? [GridItem(.flexible())]
            : [GridItem(.flexible()), GridItem(.flexible())]
        
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: selectedImages.count == 1 ? 240 : 130)
                        .clipped()
                        .cornerRadius(DesignTokens.Radius.md)
                    
                    // 削除ボタン
                    Button {
                        withAnimation(DesignTokens.Animation.spring) {
                            selectedImages.remove(at: index)
                            selectedPhotos.remove(at: index)
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(8)
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadImages(from items: [PhotosPickerItem]) async {
        selectedImages.removeAll()
        
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    selectedImages.append(uiImage)
                }
            }
        }
    }
    
    private func createPost() async {
        await MainActor.run {
            isUploading = true
        }
        
        var imageURLs: [String] = []
        
        if !selectedImages.isEmpty {
            let postId = UUID()
            
            for (index, image) in selectedImages.enumerated() {
                do {
                    let url = try await FirebaseStorageManager.shared.uploadPostImage(
                        image,
                        postId: postId,
                        index: index
                    )
                    imageURLs.append(url)
                } catch {
                    print("❌ 画像アップロードエラー: \(error)")
                }
            }
        }
        
        await MainActor.run {
            if imageURLs.isEmpty {
                viewModel.createUserPost(content: postText)
            } else {
                viewModel.createUserPost(content: postText, imageURLs: imageURLs)
            }
            
            isUploading = false
            isPresented = false
        }
    }
}

// MARK: - Supporting Views

struct ReactionBubble: View {
    let reaction: Reaction
    
    var body: some View {
        HStack(spacing: 4) {
            Text(reaction.emoji)
                .font(.system(size: 13))
            Text(reaction.oshiName)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.xxs)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(DesignTokens.Radius.full)
    }
}

struct CommentRow: View {
    let comment: Comment
    @ObservedObject var viewModel: OshiViewModel
    @State private var avatarImage: UIImage?
    
    var isUser: Bool {
        comment.oshiId == UUID(uuidString: "00000000-0000-0000-0000-000000000001")
    }
    
    var oshi: OshiCharacter? {
        viewModel.oshiList.first { $0.id == comment.oshiId }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
            avatarView
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(comment.oshiName)
                        .font(AppTypography.subheadlineMedium)
                    Text("·")
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.textSecondary)
                    RelativeTimeText(date: comment.timestamp)
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Text(comment.content)
                    .font(AppTypography.subheadline)
                    .lineSpacing(2)
            }
            
            Spacer()
        }
        .task {
            if isUser {
                if let url = viewModel.userProfileAvatarURL {
                    avatarImage = try? await FirebaseStorageManager.shared.downloadImage(from: url)
                }
            } else if let oshi = oshi, let urlString = oshi.avatarImageURL {
                avatarImage = try? await FirebaseStorageManager.shared.downloadImage(from: urlString)
            }
        }
    }
    
    @ViewBuilder
    private var avatarView: some View {
        if isUser {
            AvatarView(
                image: avatarImage,
                name: comment.oshiName,
                size: DesignTokens.AvatarSize.sm + 4,
                placeholderGradient: AppColors.primaryGradient
            )
        } else if let oshi = oshi {
            AvatarView(
                image: avatarImage,
                name: oshi.name,
                size: DesignTokens.AvatarSize.sm + 4,
                placeholderGradient: AppColors.pinkGradient
            )
        } else {
            AvatarView(
                image: nil,
                name: comment.oshiName,
                size: DesignTokens.AvatarSize.sm + 4,
                placeholderGradient: AppColors.primaryGradient
            )
        }
    }
}

// Legacy support - XStyleRelativeTimeText
struct XStyleRelativeTimeText: View {
    let date: Date
    
    var body: some View {
        RelativeTimeText(date: date)
    }
}

// Legacy support - ActionButton
struct ActionButton: View {
    let icon: String
    let count: Int?
    let color: Color
    var isFilled: Bool = false
    let action: () -> Void
    
    var body: some View {
        ActionButtonView(
            icon: icon,
            count: count,
            isActive: isFilled,
            activeColor: color,
            inactiveColor: color,
            action: action
        )
    }
}

#Preview {
    TimelineScreenView(viewModel: OshiViewModel())
}

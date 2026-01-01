import SwiftUI
import PhotosUI

// サイドバーの遷移先を定義
enum SidebarDestination: Hashable {
    case profile
    case followers
    case chat
    case notifications
    case bookmarks
    case settings
}

// タイムラインのフィルタータブ
enum TimelineTab: String, CaseIterable {
    case forYou = "おすすめ"
    case following = "フォロー中"
}

struct TimelineScreenView: View {
    @ObservedObject var viewModel: OshiViewModel
    @State private var showingPostSheet = false
    @State private var showingSidebar = false
    @State private var navigationPath = NavigationPath()
    @State private var userAvatarImage: UIImage?
    @State private var isLoadingUserAvatar = false
    @State private var userName: String = "あなた"
    @State private var selectedTab: TimelineTab = .forYou
    @State private var scrollOffset: CGFloat = 0
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
                    .scaleEffect(showingSidebar ? 0.95 : 1.0)
                    .disabled(showingSidebar)
                
                // サイドバーオーバーレイ
                if showingSidebar {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .offset(x: showingSidebar ? 280 : 0)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showingSidebar = false
                            }
                        }
                }
                
                // サイドバー
                sidebarMenu
                    .offset(x: showingSidebar ? 0 : -300)
            }
            .navigationBarTitleDisplayMode(.inline)
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
                    // SettingsView()
                    EmptyView()
                }
            }
            .task {
                await loadInitialData()
            }
            .sheet(isPresented: $showingPostSheet) {
                PostComposerView(viewModel: viewModel, isPresented: $showingPostSheet)
            }
            .sheet(isPresented: $showingSearch) {
                SearchView(viewModel: viewModel)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .global)
                .onEnded { value in
                    let dx = value.translation.width
                    let dy = value.translation.height
                    guard abs(dx) > abs(dy) else { return }
                    
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
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
    
    // MARK: - Initial Data Load
    
    private func loadInitialData() async {
        do {
            let profile = try await dbManager.loadUserProfile()
            userName = profile.userName
            
            if let url = profile.avatarImageURL {
                isLoadingUserAvatar = true
                userAvatarImage = try await FirebaseStorageManager.shared.downloadImage(from: url)
                isLoadingUserAvatar = false
            }
            
            await viewModel.loadUserReposts()
            await viewModel.loadUserLikes()
            await viewModel.loadUserBookmarks()
        } catch {
            print("❌ TimelineScreenView load error:", error.localizedDescription)
            isLoadingUserAvatar = false
        }
    }
    
    // MARK: - Profile Button
    
    private var profileButton: some View {
        Group {
            if isLoadingUserAvatar {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 32, height: 32)
                    .overlay(ProgressView().tint(.gray).scaleEffect(0.6))
            } else if let img = userAvatarImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color(.systemGray4), lineWidth: 0.5)
                    )
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.6, blue: 1.0),
                                Color(red: 0.6, green: 0.4, blue: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    )
            }
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            // ヘッダー
            headerView
            
            // タブビュー
            tabBarView
            
            // コンテンツ
            Group {
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    loadingView
                } else if filteredPosts.isEmpty {
                    emptyStateView
                } else {
                    timelineScrollView
                }
            }
        }
        .background(Color(.systemBackground))
        .overlay(alignment: .bottomTrailing) {
            floatingPostButton
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack(spacing: 16) {
            // プロフィールボタン
            Button {
                generateHapticFeedback()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
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
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.6, blue: 1.0),
                                Color(red: 0.6, green: 0.4, blue: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("AIsns")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.6, blue: 1.0),
                                Color(red: 0.6, green: 0.4, blue: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            
            Spacer()
            
            // 検索ボタン
            Button {
                generateHapticFeedback()
                showingSearch = true
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
        )
    }
    
    // MARK: - Tab Bar View
    
    private var tabBarView: some View {
        HStack(spacing: 0) {
            ForEach(TimelineTab.allCases, id: \.self) { tab in
                Button {
                    generateHapticFeedback()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 8) {
                        Text(tab.rawValue)
                            .font(.system(size: 15, weight: selectedTab == tab ? .bold : .medium))
                            .foregroundColor(selectedTab == tab ? .primary : .secondary)
                        
                        // インジケーター
                        ZStack {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 3)
                            
                            if selectedTab == tab {
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.4, green: 0.6, blue: 1.0),
                                                Color(red: 0.6, green: 0.4, blue: 1.0)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: 60, height: 3)
                                    .matchedGeometryEffect(id: "tabIndicator", in: tabNamespace)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 4)
        .background(Color(.systemBackground))
        .overlay(
            Divider(),
            alignment: .bottom
        )
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 24) {
                ZStack {
                    // 背景リング
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 4)
                        .frame(width: 60, height: 60)
                    
                    // アニメーションリング
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.6, blue: 1.0),
                                    Color(red: 0.6, green: 0.4, blue: 1.0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .modifier(SmoothRotatingModifier())
                }
                
                VStack(spacing: 6) {
                    Text("読み込み中...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("最新の投稿を取得しています")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 80)
                
                // イラスト風アイコン
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.1),
                                    Color(red: 0.6, green: 0.4, blue: 1.0).opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                    
                    VStack(spacing: 8) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.4, green: 0.6, blue: 1.0),
                                        Color(red: 0.6, green: 0.4, blue: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
                
                VStack(spacing: 12) {
                    Text(selectedTab == .following ? "フォロー中の投稿がありません" : "タイムラインがまだ空です")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(selectedTab == .following
                         ? "アカウントをフォローすると\nここに投稿が表示されます"
                         : "新しい投稿を作成するか\nアカウントをフォローしてみましょう")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                
                // アクションボタン
                VStack(spacing: 12) {
                    Button {
                        generateHapticFeedback()
                        navigationPath.append(SidebarDestination.followers)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 16, weight: .semibold))
                            Text("アカウントを探す")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.6, blue: 1.0),
                                    Color(red: 0.6, green: 0.4, blue: 1.0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Button {
                        generateHapticFeedback()
                        showingPostSheet = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 16, weight: .semibold))
                            Text("投稿を作成")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.4, green: 0.6, blue: 1.0),
                                            Color(red: 0.6, green: 0.4, blue: 1.0)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
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
                    
                    Divider()
                        .padding(.leading, 68)
                }
            }
            .padding(.bottom, 100)
        }
        .refreshable {
            await viewModel.loadData()
        }
    }
    
    // MARK: - Sidebar Menu
    
    private var sidebarMenu: some View {
        VStack(spacing: 0) {
            // ヘッダー
            VStack(alignment: .leading, spacing: 16) {
                // プロフィール情報
                HStack {
                    if let img = userAvatarImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.4, green: 0.6, blue: 1.0),
                                        Color(red: 0.6, green: 0.4, blue: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            )
                    }
                    
                    Spacer()
                    
                    Button {
                        generateHapticFeedback()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showingSidebar = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 32, height: 32)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(userName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("@\(userName.lowercased().replacingOccurrences(of: " ", with: "_"))")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                // フォロー数
                HStack(spacing: 20) {
                    Button {
                        // フォロー中一覧へ
                    } label: {
                        HStack(spacing: 4) {
                            Text("\(viewModel.followingCount)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.primary)
                            Text("フォロー中")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        // フォロワー一覧へ
                    } label: {
                        HStack(spacing: 4) {
                            Text("\(viewModel.followerCount)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.primary)
                            Text("フォロワー")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
            .padding(.top, 40)
            
            Divider()
            
            // メニュー項目
            ScrollView(showsIndicators: false) {
                VStack(spacing: 4) {
                    SidebarMenuButton(
                        icon: "person",
                        title: "プロフィール"
                    ) {
                        navigateAndCloseSidebar(.profile)
                    }
                    
                    SidebarMenuButton(
                        icon: "star",
                        title: "フォロワー",
                        badge: viewModel.oshiList.count
                    ) {
                        navigateAndCloseSidebar(.followers)
                    }
                    
                    SidebarMenuButton(
                        icon: "message",
                        title: "メッセージ",
                        badge: viewModel.chatRooms.reduce(0) { $0 + $1.unreadCount }
                    ) {
                        navigateAndCloseSidebar(.chat)
                    }
                    
                    SidebarMenuButton(
                        icon: "bell",
                        title: "通知",
                        badge: viewModel.unreadNotificationCount
                    ) {
                        navigateAndCloseSidebar(.notifications)
                    }
                    
                    SidebarMenuButton(
                        icon: "bookmark",
                        title: "ブックマーク"
                    ) {
                        navigateAndCloseSidebar(.bookmarks)
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    SidebarMenuButton(
                        icon: "gearshape",
                        title: "設定"
                    ) {
                        navigateAndCloseSidebar(.settings)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Spacer()
            
            // フッター
            HStack {
                Button {
                    // ダークモード切り替え
                } label: {
                    Image(systemName: "moon")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(20)
        }
        .frame(width: 280)
        .background(Color(.systemBackground))
        .ignoresSafeArea()
    }
    
    private func navigateAndCloseSidebar(_ destination: SidebarDestination) {
        generateHapticFeedback()
        navigationPath.append(destination)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            showingSidebar = false
        }
    }
    
    // MARK: - Floating Button
    
    private var floatingPostButton: some View {
        Button {
            generateHapticFeedback()
            showingPostSheet = true
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.6, blue: 1.0),
                                Color(red: 0.6, green: 0.4, blue: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.4), radius: 12, x: 0, y: 6)
                
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.trailing, 20)
        .padding(.bottom, 24)
    }
}

// MARK: - Sidebar Menu Button

struct SidebarMenuButton: View {
    let icon: String
    let title: String
    var badge: Int? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(.primary)
                    .frame(width: 28)
                
                Text(title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let badge = badge, badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.4, green: 0.6, blue: 1.0),
                                            Color(red: 0.6, green: 0.4, blue: 1.0)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Smooth Rotating Modifier

struct SmoothRotatingModifier: ViewModifier {
    @State private var isRotating = false
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isRotating ? 360 : 0))
            .onAppear {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    isRotating = true
                }
            }
    }
}

// MARK: - Search View (Placeholder)

struct SearchView: View {
    @ObservedObject var viewModel: OshiViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // 検索バー
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("検索", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                if searchText.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(.secondary)
                        Text("投稿やアカウントを検索")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    // 検索結果表示
                    List {
                        // 実装予定
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("検索")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Updated Post Card View

struct PostCardView: View {
    let post: Post
    @ObservedObject var viewModel: OshiViewModel
    var isNavigable: Bool = true
    @State private var showingReactions = false
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

    var postDetails: PostDetails? {
        viewModel.postDetails[post.id]
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
        // 推しのアバター画像読み込み
        if let oshi = oshi, let urlString = oshi.avatarImageURL {
            avatarImage = try? await FirebaseStorageManager.shared.downloadImage(from: urlString)
        }
        
        // ユーザーのアバター画像読み込み
        if post.isUserPost, let url = viewModel.userProfileAvatarURL {
            userAvatarImage = try? await FirebaseStorageManager.shared.downloadImage(from: url)
        }
        
        // 投稿画像読み込み
        if !post.imageURLs.isEmpty && postImages.count != post.imageURLs.count {
            var loadedImages: [UIImage] = []
            for imageURL in post.imageURLs {
                if let image = try? await FirebaseStorageManager.shared.downloadImage(from: imageURL) {
                    loadedImages.append(image)
                }
            }
            await MainActor.run {
                self.postImages = loadedImages
            }
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // リポストヘッダー
            if viewModel.isReposted(post) && !post.isUserPost {
                repostHeader
            }
            
            HStack(alignment: .top, spacing: 12) {
                // アバター
                avatarView
                    .onTapGesture {
                        if let oshi = oshi {
                            // 推しプロフィールへ遷移（NavigationLinkで対応）
                        }
                    }

                VStack(alignment: .leading, spacing: 6) {
                    // ヘッダー
                    HStack(spacing: 4) {
                        Group {
                            if let oshi = oshi {
                                Text(oshi.name)
                            } else {
                                Text(post.isUserPost ? viewModel.userProfileName : post.authorName)
                            }
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                        if post.isUserPost {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                        }

                        Text("·")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)

                        XStyleRelativeTimeText(date: post.timestamp)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)

                        Spacer()

                        Menu {
                            Button(role: .destructive) {
                                // 報告
                            } label: {
                                Label("報告する", systemImage: "flag")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .frame(width: 28, height: 28)
                                .contentShape(Rectangle())
                        }
                    }

                    // 投稿内容
                    if !post.content.isEmpty {
                        Text(post.content)
                            .font(.system(size: 15))
                            .lineSpacing(4)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // 投稿画像
                    if !postImages.isEmpty {
                        postImageGrid
                            .padding(.top, 8)
                    }

                    // アクションボタン
                    actionButtons
                        .padding(.top, 12)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
    
    // リポストヘッダー
    private var repostHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.2.squarepath")
                .font(.system(size: 12, weight: .medium))
            Text("\(viewModel.userProfileName)がリポスト")
                .font(.system(size: 13))
        }
        .foregroundColor(.secondary)
        .padding(.leading, 56)
        .padding(.top, 8)
        .padding(.bottom, 2)
    }
    
    // 投稿画像グリッド
    private var postImageGrid: some View {
        let columns: [GridItem] = postImages.count == 1
            ? [GridItem(.flexible())]
            : [GridItem(.flexible()), GridItem(.flexible())]
        
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(postImages.enumerated()), id: \.offset) { index, image in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: postImages.count == 1 ? 240 : 140)
                    .clipped()
                    .cornerRadius(12)
            }
        }
    }
    
    // アバター表示
    private var avatarView: some View {
        Group {
            if let oshi = oshi {
                if let avatarImage = avatarImage {
                    Image(uiImage: avatarImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(.systemPink), Color(.systemPink).opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(String(oshi.name.prefix(1)))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
            } else {
                if post.isUserPost, let img = userAvatarImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.6, blue: 1.0),
                                    Color(red: 0.6, green: 0.4, blue: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 18))
                        )
                }
            }
        }
    }
    
    // アクションボタン
    private var actionButtons: some View {
        HStack(spacing: 0) {
            // コメント
            PostActionButton(
                icon: "bubble.left",
                count: post.commentCount,
                color: .secondary
            ) {
                // コメント画面へ
            }
            
            Spacer()
            
            // リポスト
            PostActionButton(
                icon: "arrow.2.squarepath",
                count: post.repostCount,
                color: viewModel.isReposted(post) ? .green : .secondary,
                isActive: viewModel.isReposted(post)
            ) {
                generateHapticFeedback()
                viewModel.toggleRepost(for: post)
            }
            
            Spacer()
            
            // いいね
            PostActionButton(
                icon: "heart",
                count: post.reactionCount,
                color: hasUserLiked ? .pink : .secondary,
                isActive: hasUserLiked,
                isFilled: hasUserLiked
            ) {
                generateHapticFeedback()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
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
            PostActionButton(
                icon: "bookmark",
                count: nil,
                color: viewModel.isBookmarked(post) ? Color(red: 0.4, green: 0.6, blue: 1.0) : .secondary,
                isActive: viewModel.isBookmarked(post),
                isFilled: viewModel.isBookmarked(post)
            ) {
                generateHapticFeedback()
                viewModel.toggleBookmark(for: post)
            }
            
            Spacer()
            
            // シェア
            PostActionButton(
                icon: "square.and.arrow.up",
                count: nil,
                color: .secondary
            ) {
                // シェア
            }
        }
    }
}

// MARK: - Post Action Button

struct PostActionButton: View {
    let icon: String
    let count: Int?
    let color: Color
    var isActive: Bool = false
    var isFilled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: isFilled ? icon + ".fill" : icon)
                    .font(.system(size: 16))
                if let count = count, count > 0 {
                    Text("\(count)")
                        .font(.system(size: 13))
                }
            }
            .foregroundColor(color)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 画像添付対応のPostComposerView

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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // テキストエディタ
                        ZStack(alignment: .topLeading) {
                            if postText.isEmpty {
                                Text("いまどうしてる？")
                                    .foregroundColor(.secondary.opacity(0.6))
                                    .font(.system(size: 17))
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                            }
                            
                            TextEditor(text: $postText)
                                .focused($isTextFieldFocused)
                                .font(.system(size: 17))
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 120)
                        }
                        .padding(.horizontal, 16)
                        
                        // 選択された画像のプレビュー
                        if !selectedImages.isEmpty {
                            imagePreviewGrid
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 12)
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
                    .foregroundColor(.primary)
                    .disabled(isUploading)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    postButton
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isTextFieldFocused = true
                }
            }
        }
    }
    
    // ツールバー
    private var toolbarView: some View {
        HStack {
            HStack(spacing: 20) {
                // 画像選択ボタン
                PhotosPicker(
                    selection: $selectedPhotos,
                    maxSelectionCount: 4,
                    matching: .images
                ) {
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                        .foregroundColor(
                            selectedImages.count >= 4
                            ? Color.gray
                            : Color(red: 0.4, green: 0.6, blue: 1.0)
                        )
                }
                .disabled(selectedImages.count >= 4)
                .onChange(of: selectedPhotos) { newItems in
                    Task {
                        await loadImages(from: newItems)
                    }
                }
                
                // GIF（プレースホルダー）
                Button {
                    // GIF選択
                } label: {
                    Text("GIF")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                }
            }
            .padding(.leading, 16)
            
            Spacer()
            
            // 文字数カウンター
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 2)
                    .frame(width: 24, height: 24)
                
                Circle()
                    .trim(from: 0, to: CGFloat(min(postText.count, 280)) / 280)
                    .stroke(
                        postText.count > 280 ? Color.red :
                            postText.count > 260 ? Color.orange :
                            Color(red: 0.4, green: 0.6, blue: 1.0),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: 24, height: 24)
                    .rotationEffect(.degrees(-90))
            }
            .padding(.trailing, 12)
            
            if postText.count > 260 {
                Text("\(280 - postText.count)")
                    .font(.system(size: 12))
                    .foregroundColor(postText.count > 280 ? .red : .orange)
                    .padding(.trailing, 16)
            }
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .overlay(
            Divider(),
            alignment: .top
        )
    }
    
    // 投稿ボタン
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
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.5),
                                Color(red: 0.6, green: 0.4, blue: 1.0).opacity(0.5)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
            } else {
                Text("投稿")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        canPost ?
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.6, blue: 1.0),
                                Color(red: 0.6, green: 0.4, blue: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [.gray.opacity(0.3), .gray.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
            }
        }
        .disabled(!canPost)
        .buttonStyle(ScaleButtonStyle())
    }
    
    // 画像プレビューグリッド
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
                        .frame(height: selectedImages.count == 1 ? 250 : 140)
                        .clipped()
                        .cornerRadius(12)
                    
                    // 削除ボタン
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
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
    
    // PhotosPickerItemから画像をロード
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
    
    // 投稿作成
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

struct XStyleRelativeTimeText: View {
    let date: Date

    var body: some View {
        SwiftUI.TimelineView(.periodic(from: Date(), by: 60)) { context in
            Text(Self.format(from: date, now: context.date))
        }
    }

    private static func format(from date: Date, now: Date) -> String {
        let diff = max(0, Int(now.timeIntervalSince(date)))

        if diff < 60 { return "たった今" }

        let minutes = diff / 60
        if minutes < 60 { return "\(minutes)分" }

        let hours = minutes / 60
        if hours < 24 { return "\(hours)時間" }

        let days = hours / 24
        if days < 7 { return "\(days)日" }

        return shortDateFormatter.string(from: date)
    }

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "M/d"
        return f
    }()
}

struct ReactionBubble: View {
    let reaction: Reaction
    
    var body: some View {
        HStack(spacing: 4) {
            Text(reaction.emoji)
                .font(.system(size: 13))
            Text(reaction.oshiName)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
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
        HStack(alignment: .top, spacing: 12) {
            avatarView
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(comment.oshiName)
                        .font(.system(size: 14, weight: .bold))
                    Text("·")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    XStyleRelativeTimeText(date: comment.timestamp)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Text(comment.content)
                    .font(.system(size: 14))
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
            if let avatarImage = avatarImage {
                Image(uiImage: avatarImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.6, blue: 1.0),
                                Color(red: 0.6, green: 0.4, blue: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    )
            }
        } else if let oshi = oshi {
            if let avatarImage = avatarImage {
                Image(uiImage: avatarImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(.systemPink), Color(.systemPink).opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(oshi.name.prefix(1)))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
        } else {
            Circle()
                .fill(Color.gray)
                .frame(width: 36, height: 36)
        }
    }
}

struct ActionButton: View {
    let icon: String
    let count: Int?
    let color: Color
    var isFilled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: isFilled ? icon + ".fill" : icon)
                    .font(.system(size: 16))
                if let count = count, count > 0 {
                    Text("\(count)")
                        .font(.system(size: 13))
                }
            }
            .foregroundColor(color)
        }
        .buttonStyle(.borderless)
    }
}

#Preview {
    TimelineScreenView(viewModel: OshiViewModel())
}

import SwiftUI
import PhotosUI

// サイドバーの遷移先を定義
enum SidebarDestination: Hashable {
    case profile
    case followers
    case chat
    case notifications
}

struct TimelineScreenView: View {
    @ObservedObject var viewModel: OshiViewModel
    @State private var showingPostSheet = false
    @State private var showingSidebar = false
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .bottomTrailing) {
                // メインコンテンツ
                mainContent
                
                // サイドバー
                if showingSidebar {
                    sidebarMenu
                        .transition(.move(edge: .leading))
                        .zIndex(1)
                }
                
                // フローティング投稿ボタン
                floatingPostButton
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !showingSidebar {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showingSidebar.toggle()
                            }
                        }) {
                            profileButton
                        }
                    } else {
                        
                    }
                }
            }
            .toolbar(!showingSidebar ? .visible : .visible, for: .navigationBar)
            .navigationDestination(for: SidebarDestination.self) { destination in
                switch destination {
                case .profile:
                    UserProfileView()
                case .followers:
                    OshiListView(viewModel: viewModel)
                case .chat:
                    ChatListView(viewModel: viewModel, isPresented: .constant(true) )
                case .notifications:
                    NotificationView(viewModel: viewModel, isPresented: .constant(true))
                }
            }
            .sheet(isPresented: $showingPostSheet) {
                PostComposerView(viewModel: viewModel, isPresented: $showingPostSheet)
            }
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.posts) { post in
                        PostCardView(post: post, viewModel: viewModel)
                        Divider()
                            .padding(.leading, 64)
                    }
                }
                .padding(.bottom, 80)
            }
            .refreshable {
                // リフレッシュ処理
            }
            
            // サイドバー表示時の半透明オーバーレイ
            if showingSidebar {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showingSidebar = false
                        }
                    }
            }
        }
    }
    
    // MARK: - Profile Button
    
    private var profileButton: some View {
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
            .frame(width: 32, height: 32)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            )
    }
    
    // MARK: - Sidebar Menu
    
    private var sidebarMenu: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                // ヘッダー
                VStack(alignment: .leading, spacing: 12) {
                    // 閉じるボタン
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showingSidebar = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.primary)
                                .frame(width: 32, height: 32)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.trailing, 8)
                    
                    // プロフィール情報
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
                        .frame(width: 64, height: 64)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("あなた")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("@user")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Text("\(viewModel.oshiList.count)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.primary)
                            Text("フォロー中")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Text("\(viewModel.posts.filter { $0.isUserPost }.count)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.primary)
                            Text("投稿")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                
                Divider()
                
                // メニュー項目
                ScrollView {
                    VStack(spacing: 0) {
                        // プロフィール
                        Button {
                            navigationPath.append(SidebarDestination.profile)
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showingSidebar = false
                            }
                        } label: {
                            SidebarMenuItem(
                                icon: "person.fill",
                                title: "プロフィール"
                            )
                        }
                        .buttonStyle(.plain)
                        
                        // フォロワー(推しリスト)
                        Button {
                            navigationPath.append(SidebarDestination.followers)
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showingSidebar = false
                            }
                        } label: {
                            SidebarMenuItem(
                                icon: "star.fill",
                                title: "フォロワー",
                                badge: viewModel.oshiList.count
                            )
                        }
                        .buttonStyle(.plain)
                        
                        // チャット
                        Button {
                            navigationPath.append(SidebarDestination.chat)
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showingSidebar = false
                            }
                        } label: {
                            SidebarMenuItem(
                                icon: "message.fill",
                                title: "チャット",
                                badge: viewModel.chatRooms.reduce(0) { $0 + $1.unreadCount }
                            )
                        }
                        .buttonStyle(.plain)
                        
                        // 通知
                        Button {
                            navigationPath.append(SidebarDestination.notifications)
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showingSidebar = false
                            }
                        } label: {
                            SidebarMenuItem(
                                icon: "bell.fill",
                                title: "通知",
                                badge: viewModel.unreadNotificationCount
                            )
                        }
                        .buttonStyle(.plain)
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        // 設定
                        SidebarMenuItem(
                            icon: "gearshape.fill",
                            title: "設定とプライバシー"
                        )
                    }
                }
                
                Spacer()
            }
            .frame(width: 280)
            .background(Color(.systemBackground))
            .shadow(color: .black.opacity(0.2), radius: 10, x: 2, y: 0)
            .ignoresSafeArea()
            
            Spacer()
        }
    }
    
    // MARK: - Floating Button
    
    private var floatingPostButton: some View {
        Button(action: {
            showingPostSheet = true
        }) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.2, green: 0.7, blue: 1.0),
                            Color(red: 0.5, green: 0.4, blue: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: Color.blue.opacity(0.3), radius: 15, x: 0, y: 8)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }
}

struct SidebarMenuItem: View {
    let icon: String
    let title: String
    var badge: Int? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.primary)
                .frame(width: 28)
            
            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            if let badge = badge, badge > 0 {
                Text("\(badge)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }
}

// MARK: - ✅ 画像添付対応のPostComposerView
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
                        HStack(alignment: .top, spacing: 12) {
                            ZStack(alignment: .topLeading) {
                                if postText.isEmpty {
                                    Text("いまどうしてる?")
                                        .foregroundColor(.secondary.opacity(0.6))
                                        .font(.body)
                                        .padding(.top, 8)
                                        .padding(.leading,8)
                                }
                                
                                TextEditor(text: $postText)
                                    .focused($isTextFieldFocused)
                                    .font(.body)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 120)
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // ✅ 選択された画像のプレビュー
                        if !selectedImages.isEmpty {
                            imagePreviewGrid
                                .padding(.horizontal, 16)
                        }
                    }
                }
                
                // ツールバー
                HStack {
                    HStack(spacing: 16) {
                        // ✅ 画像選択ボタン(PhotosPicker)
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
                                    : Color(red: 0.2, green: 0.7, blue: 1.0)
                                )
                        }
                        .disabled(selectedImages.count >= 4)
                        .onChange(of: selectedPhotos) { newItems in
                            Task {
                                await loadImages(from: newItems)
                            }
                        }
                    }
                    .padding(.leading, 16)
                    
                    Spacer()
                    
                    Text("\(postText.count)/280")
                        .font(.system(size: 13))
                        .foregroundColor(postText.count > 280 ? .red : .secondary)
                        .padding(.trailing, 16)
                }
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color(.separator)),
                    alignment: .top
                )
            }
            .navigationTitle("投稿")
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
                    Button {
                        Task {
                            await createPost()
                        }
                    } label: {
                        if isUploading {
                            ProgressView()
                                .tint(.white)
                                .frame(width: 60, height: 36)
                                .background(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.2, green: 0.7, blue: 1.0).opacity(0.5),
                                            Color(red: 0.5, green: 0.4, blue: 1.0).opacity(0.5)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(20)
                        } else {
                            Text("投稿")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(
                                    canPost ?
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.2, green: 0.7, blue: 1.0),
                                            Color(red: 0.5, green: 0.4, blue: 1.0)
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
                                .cornerRadius(20)
                        }
                    }
                    .disabled(!canPost)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isTextFieldFocused = true
                }
            }
        }
    }
    
    // ✅ 画像プレビューグリッド
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
                        .frame(height: selectedImages.count == 1 ? 300 : 150)
                        .clipped()
                        .cornerRadius(12)
                    
                    // 削除ボタン
                    Button {
                        withAnimation {
                            selectedImages.remove(at: index)
                            selectedPhotos.remove(at: index)
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.5))
                                    .frame(width: 28, height: 28)
                            )
                    }
                    .padding(8)
                }
            }
        }
    }
    
    // ✅ PhotosPickerItemから画像をロード
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
    
    // ✅ 修正版: 投稿作成(画像アップロード含む)
    private func createPost() async {
        print("🚀 createPost開始")
        
        // UIの更新
        await MainActor.run {
            isUploading = true
        }
        
        var imageURLs: [String] = []
        
        // 画像をアップロード
        if !selectedImages.isEmpty {
            print("📸 画像アップロード開始: \(selectedImages.count)枚")
            
            // ✅ 修正: 1つのpostIdを使う
            let postId = UUID()
            
            for (index, image) in selectedImages.enumerated() {
                do {
                    print("  📤 画像\(index + 1)をアップロード中...")
                    let url = try await FirebaseStorageManager.shared.uploadPostImage(
                        image,
                        postId: postId,
                        index: index
                    )
                    imageURLs.append(url)
                    print("  ✅ 画像\(index + 1)アップロード成功: \(url)")
                } catch {
                    print("  ❌ 画像\(index + 1)アップロードエラー: \(error)")
                    // エラーがあっても続行
                }
            }
            
            print("📸 画像アップロード完了: \(imageURLs.count)/\(selectedImages.count)枚成功")
        }
        
        // 投稿作成
        await MainActor.run {
            print("💾 投稿を作成中...")
            
            // ✅ 修正: imageURLsパラメータを確実に渡す
            if imageURLs.isEmpty {
                // 画像なしの場合
                viewModel.createUserPost(content: postText)
            } else {
                // 画像ありの場合
                viewModel.createUserPost(content: postText, imageURLs: imageURLs)
            }
            
            print("✅ 投稿作成完了")
            
            // UIをクローズ
            isUploading = false
            isPresented = false
        }
        
        print("🎉 createPost完了")
    }
}

// MARK: - ✅ 画像表示対応のPostCardView
struct PostCardView: View {
    let post: Post
    @ObservedObject var viewModel: OshiViewModel
    var isNavigable: Bool = true
    @State private var showingReactions = false
    @State private var avatarImage: UIImage?
    @State private var postImages: [UIImage] = [] // ✅ 投稿画像

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
            // アバター画像読み込み
            if let oshi = oshi, let urlString = oshi.avatarImageURL {
                avatarImage = try? await FirebaseStorageManager.shared.downloadImage(from: urlString)
            }
            
            // ✅ 投稿画像読み込み
            if !post.imageURLs.isEmpty {
                for imageURL in post.imageURLs {
                    if let image = try? await FirebaseStorageManager.shared.downloadImage(from: imageURL) {
                        await MainActor.run {
                            postImages.append(image)
                        }
                    }
                }
            }
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Group {
                    if let oshi = oshi {
                        NavigationLink {
                            OshiProfileDetailView(oshi: oshi, viewModel: viewModel)
                        } label: {
                            avatarView
                        }
                        .buttonStyle(.plain)
                    } else {
                        avatarView
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    // ヘッダー
                    HStack(spacing: 4) {
                        if let oshi = oshi {
                            NavigationLink {
                                OshiProfileDetailView(oshi: oshi, viewModel: viewModel)
                            } label: {
                                Text(post.authorName)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Text(post.authorName)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.primary)
                        }

                        if post.isUserPost {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 13))
                                .foregroundColor(Color(red: 0.2, green: 0.7, blue: 1.0))
                        }

                        Text("·")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)

                        XStyleRelativeTimeText(date: post.timestamp)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)

                        Spacer()

                        Button(action: {}) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.borderless)
                    }

                    // 投稿内容
                    if !post.content.isEmpty {
                        Text(post.content)
                            .font(.system(size: 15))
                            .lineSpacing(3)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 2)
                    }
                    
                    // ✅ 投稿画像表示
                    if !postImages.isEmpty {
                        postImageGrid
                            .padding(.top, 8)
                    }

                    // アクションボタン
                    HStack(spacing: 0) {
                        ActionButton(
                            icon: "bubble.left",
                            count: post.commentCount,
                            color: .secondary
                        ) {}
                        .frame(maxWidth: .infinity)

                        ActionButton(
                            icon: "arrow.2.squarepath",
                            count: 0,
                            color: .secondary
                        ) {}
                        .frame(maxWidth: .infinity)

                        ActionButton(
                            icon: "heart",
                            count: post.reactionCount,
                            color: hasUserLiked ? .pink : .secondary,
                            isFilled: hasUserLiked
                        ) {
                            viewModel.toggleUserReaction(on: post)
                        }
                        .frame(maxWidth: .infinity)

                        ActionButton(
                            icon: "bookmark",
                            count: nil,
                            color: .secondary
                        ) {}
                        .frame(maxWidth: .infinity)

                        ActionButton(
                            icon: "square.and.arrow.up",
                            count: nil,
                            color: .secondary
                        ) {}
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 8)

                    // リアクション表示
                    if showingReactions {
                        if let details = postDetails, !details.reactions.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(details.reactions) { reaction in
                                        ReactionBubble(reaction: reaction)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .padding(.top, 6)
                        } else if post.reactionCount > 0 {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("いいねを読み込み中...")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 8)
                        } else {
                            Text("まだいいねはありません")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                    }
                }
                .padding(.trailing, 8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
    
    // ✅ 投稿画像グリッド
    private var postImageGrid: some View {
        let columns: [GridItem] = postImages.count == 1
            ? [GridItem(.flexible())]
            : [GridItem(.flexible()), GridItem(.flexible())]
        
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(postImages.enumerated()), id: \.offset) { index, image in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: postImages.count == 1 ? 300 : 150)
                    .clipped()
                    .cornerRadius(12)
            }
        }
    }
    
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
                                colors: [
                                    Color(.systemPink),
                                    Color(.systemPink).opacity(0.7)
                                ],
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
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    )
            }
        }
    }
}

// アクションボタンコンポーネント
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
    
    var oshi: OshiCharacter? {
        viewModel.oshiList.first { $0.id == comment.oshiId }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let oshi = oshi {
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
                                    Color(.systemPink),
                                    Color(.systemPink).opacity(0.7)
                                ],
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
            }
            
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
            if let oshi = oshi, let urlString = oshi.avatarImageURL {
                avatarImage = try? await FirebaseStorageManager.shared.downloadImage(from: urlString)
            }
        }
    }
}

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

#Preview {
    TimelineScreenView(viewModel: OshiViewModel())
}

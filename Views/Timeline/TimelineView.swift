import SwiftUI

struct TimelineScreenView: View {
    @ObservedObject var viewModel: OshiViewModel
    @State private var showingPostSheet = false
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
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
                
                // フローティング投稿ボタン
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
            .navigationTitle("タイムライン")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingPostSheet) {
                PostComposerView(viewModel: viewModel, isPresented: $showingPostSheet)
            }
        }
    }
}

struct PostComposerView: View {
    @ObservedObject var viewModel: OshiViewModel
    @Binding var isPresented: Bool
    @State private var postText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var canPost: Bool {
        !postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && postText.count <= 280
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
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
                    
                    ZStack(alignment: .topLeading) {
                        if postText.isEmpty {
                            Text("いまどうしてる?")
                                .foregroundColor(.secondary.opacity(0.6))
                                .font(.body)
                                .padding(.top, 8)
                        }
                        
                        TextEditor(text: $postText)
                            .focused($isTextFieldFocused)
                            .font(.body)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 120)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                Spacer()
                
                // ツールバー
                HStack {
                    HStack(spacing: 16) {
                        Button(action: {}) {
                            Image(systemName: "photo")
                                .font(.system(size: 20))
                                .foregroundColor(Color(red: 0.2, green: 0.7, blue: 1.0))
                        }
                        Button(action: {}) {
                            Image(systemName: "face.smiling")
                                .font(.system(size: 20))
                                .foregroundColor(Color(red: 0.2, green: 0.7, blue: 1.0))
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
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("投稿") {
                        viewModel.createUserPost(content: postText)
                        isPresented = false
                    }
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
}

struct PostCardView: View {
    let post: Post
    @ObservedObject var viewModel: OshiViewModel
    var isNavigable: Bool = true
    @State private var showingReactions = false
    @State private var avatarImage: UIImage?

    var oshi: OshiCharacter? {
        if let authorId = post.authorId {
            return viewModel.oshiList.first { $0.id == authorId }
        }
        return nil
    }

    var postDetails: PostDetails? {
        viewModel.postDetails[post.id]
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
            if let oshi = oshi, let urlString = oshi.avatarImageURL {
                avatarImage = try? await FirebaseStorageManager.shared.downloadImage(from: urlString)
            }
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // ✅ アバターをNavigationLinkでラップ（推しの場合のみ）
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
                        // ✅ 名前もタップ可能に（推しの場合のみ）
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
                    Text(post.content)
                        .font(.system(size: 15))
                        .lineSpacing(3)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)

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
                            color: showingReactions ? .pink : .secondary,
                            isFilled: showingReactions
                        ) {
                            showingReactions.toggle()
                            if showingReactions && postDetails == nil {
                                Task { await viewModel.loadPostDetails(for: post.id) }
                            }
                            if !post.isUserPost {
                                viewModel.reactToOshiPost(post)
                            }
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
    
    // ✅ アバター表示を別Viewに分離
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

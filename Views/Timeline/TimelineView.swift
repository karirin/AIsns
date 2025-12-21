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
                        }
                    }
                    .padding(.bottom, 80)
                }
                
                // フローティング投稿ボタン
                Button(action: {
                    showingPostSheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
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

// 投稿作成シート
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
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                                .font(.headline)
                        )
                    
                    ZStack(alignment: .topLeading) {
                        if postText.isEmpty {
                            Text("いまどうしてる？")
                                .foregroundColor(.secondary.opacity(0.5))
                                .padding(.top, 8)
                        }
                        
                        TextEditor(text: $postText)
                            .focused($isTextFieldFocused)
                            .font(.body)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 100)
                    }
                }
                .padding()
                
                Spacer()
                
                HStack {
                    Spacer()
                    Text("\(postText.count)/280")
                        .font(.caption)
                        .foregroundColor(postText.count > 280 ? .red : .secondary)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
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
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        canPost ?
                        LinearGradient(
                            colors: [.blue, .purple],
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

// 投稿カード
struct PostCardView: View {
    let post: Post
    @ObservedObject var viewModel: OshiViewModel
    @State private var showingReactions = false

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
        NavigationLink {
            PostDetailView(post: post, viewModel: viewModel)
        } label: {
            cardContent
        }
        .buttonStyle(.plain)
    }

    // ✅ ここに入れる（PostCardViewの中）
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                if let oshi = oshi {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: oshi.avatarColor),
                                    Color(hex: oshi.avatarColor).opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(String(oshi.name.prefix(1)))
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                        )
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Text(post.authorName)
                            .font(.subheadline)
                            .fontWeight(.bold)

                        if post.isUserPost {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }

                        Text("·")
                            .foregroundColor(.secondary)

                        XStyleRelativeTimeText(date: post.timestamp)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Button(action: {}) {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.borderless)
                    }

                    Text(post.content)
                        .font(.body)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 0) {
                        Button(action: {}) {
                            HStack(spacing: 4) {
                                Image(systemName: "bubble.left")
                                    .font(.subheadline)
                                if post.commentCount > 0 {
                                    Text("\(post.commentCount)")
                                        .font(.caption)
                                }
                            }
                            .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)

                        Button(action: {}) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.2.squarepath")
                                    .font(.subheadline)
                                Text("0")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)

                        Button(action: {
                            showingReactions.toggle()
                            if showingReactions && postDetails == nil {
                                Task { await viewModel.loadPostDetails(for: post.id) }
                            }
                            if !post.isUserPost {
                                viewModel.reactToOshiPost(post)
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "heart")
                                    .font(.subheadline)
                                if post.reactionCount > 0 {
                                    Text("\(post.reactionCount)")
                                        .font(.caption)
                                }
                            }
                            .foregroundColor(showingReactions ? .pink : .secondary)
                        }
                        .frame(maxWidth: .infinity)

                        Button(action: {}) {
                            Image(systemName: "bookmark")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)

                        Button(action: {}) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 12)
                    .buttonStyle(.borderless)

                    if showingReactions {
                        if let details = postDetails, !details.reactions.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(details.reactions) { reaction in
                                        ReactionBubble(reaction: reaction)
                                    }
                                }
                            }
                            .padding(.top, 8)
                        } else if post.reactionCount > 0 {
                            HStack(spacing: 6) {
                                ProgressView().scaleEffect(0.8)
                                Text("いいねを読み込み中...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 8)
                        } else {
                            Text("まだいいねはありません")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
}


struct ReactionBubble: View {
    let reaction: Reaction
    
    var body: some View {
        HStack(spacing: 4) {
            Text(reaction.emoji)
                .font(.caption)
            Text(reaction.oshiName)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CommentRow: View {
    let comment: Comment
    @ObservedObject var viewModel: OshiViewModel
    
    var oshi: OshiCharacter? {
        viewModel.oshiList.first { $0.id == comment.oshiId }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let oshi = oshi {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: oshi.avatarColor),
                                Color(hex: oshi.avatarColor).opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(String(oshi.name.prefix(1)))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(comment.oshiName)
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text("·")
                        .foregroundColor(.secondary)
                    XStyleRelativeTimeText(date: comment.timestamp)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(comment.content)
                    .font(.subheadline)
                    .lineSpacing(2)
            }
            
            Spacer()
        }
    }
}

// ✅ X風：分単位で更新する相対時刻表示
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

        // 7日以上は日付表示（Xっぽく）
        return shortDateFormatter.string(from: date)
    }

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "M/d" // 好みで "M月d日" もOK
        return f
    }()
}


#Preview {
    TimelineScreenView(viewModel: OshiViewModel())
}

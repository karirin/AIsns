import SwiftUI

struct TimelineView: View {
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

// ✅ 修正版: リアクション・コメントを自動的に表示
struct PostCardView: View {
    let post: Post
    @ObservedObject var viewModel: OshiViewModel
    @State private var showingDetails = false
    
    var oshi: OshiCharacter? {
        if let authorId = post.authorId {
            return viewModel.oshiList.first { $0.id == authorId }
        }
        return nil
    }
    
    // ✅ 投稿の詳細情報を取得
    var postDetails: PostDetails? {
        viewModel.postDetails[post.id]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // アバター
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
                    // ヘッダー
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
                        
                        Text(post.timestamp, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 本文
                    Text(post.content)
                        .font(.body)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // ✅ リアクション表示（カウントがあれば自動的に読み込み）
                    if let details = postDetails, !details.reactions.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(details.reactions) { reaction in
                                    ReactionBubble(reaction: reaction)
                                }
                            }
                        }
                        .padding(.top, 4)
                    } else if post.reactionCount > 0 && postDetails == nil {
                        // ✅ カウントはあるが詳細がない場合、読み込み中表示
                        HStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("読み込み中...")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                        .task {
                            // 自動的に詳細を読み込み
                            await viewModel.loadPostDetails(for: post.id)
                        }
                    }
                    
                    // アクションボタン
                    HStack(spacing: 0) {
                        // ✅ コメントボタン（件数を表示）
                        Button(action: {
                            showingDetails.toggle()
                            if showingDetails && postDetails == nil {
                                Task {
                                    await viewModel.loadPostDetails(for: post.id)
                                }
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: showingDetails ? "bubble.left.fill" : "bubble.left")
                                    .font(.subheadline)
                                if post.commentCount > 0 {
                                    Text("\(post.commentCount)")
                                        .font(.caption)
                                }
                            }
                            .foregroundColor(showingDetails ? .blue : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // リポスト
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
                        
                        // ✅ いいねボタン（件数を表示）
                        Button(action: {
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
                            .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // ブックマーク
                        Button(action: {}) {
                            Image(systemName: "bookmark")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // 共有
                        Button(action: {}) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 12)
                    
                    // ✅ コメント表示（詳細を読み込んでいる場合のみ）
                    if showingDetails {
                        if let details = postDetails {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(details.comments) { comment in
                                    CommentRow(comment: comment, viewModel: viewModel)
                                }
                                
                                // ✅ もっと読み込むボタン
                                if details.hasMoreComments {
                                    Button(action: {
                                        Task {
                                            await viewModel.loadMoreComments(for: post.id)
                                        }
                                    }) {
                                        Text("返信をさらに表示")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.leading, 52)
                                }
                            }
                            .padding(.top, 8)
                        } else if post.commentCount > 0 {
                            // 読み込み中
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("コメントを読み込み中...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 8)
                            .padding(.leading, 52)
                        } else {
                            // コメントがない
                            Text("まだコメントはありません")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 52)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        // ✅ 投稿が表示された時に、カウントがあれば自動的に詳細を読み込む
        .task(id: post.id) {
            // リアクションまたはコメントがあり、まだ詳細を読み込んでいない場合
            if (post.reactionCount > 0 || post.commentCount > 0) && postDetails == nil {
                await viewModel.loadPostDetails(for: post.id)
            }
        }
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
            // アバター
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
                    Text(comment.timestamp, style: .relative)
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

#Preview {
    TimelineView(viewModel: OshiViewModel())
}

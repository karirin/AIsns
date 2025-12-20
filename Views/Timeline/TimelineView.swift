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
                // ユーザーアバター + テキストエディタ
                HStack(alignment: .top, spacing: 12) {
                    // ユーザーアバター
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
                    
                    // テキストエディタ
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
                
                // 文字数カウンター
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
    @State private var showAllComments = false
    
    var oshi: OshiCharacter? {
        if let authorId = post.authorId {
            return viewModel.oshiList.first { $0.id == authorId }
        }
        return nil
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
                    
                    // リアクション（投稿直下）
                    if !post.reactions.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(post.reactions) { reaction in
                                    ReactionBubble(reaction: reaction)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                    
                    // アクションボタン
                    HStack(spacing: 0) {
                        // コメント
                        Button(action: {}) {
                            HStack(spacing: 4) {
                                Image(systemName: "bubble.left")
                                    .font(.subheadline)
                                if !post.comments.isEmpty {
                                    Text("\(post.comments.count)")
                                        .font(.caption)
                                }
                            }
                            .foregroundColor(.secondary)
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
                        
                        // いいね
                        Button(action: {
                            if !post.isUserPost {
                                viewModel.reactToOshiPost(post)
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "heart")
                                    .font(.subheadline)
                                if !post.reactions.isEmpty {
                                    Text("\(post.reactions.count)")
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
                    
                    // コメント
                    if !post.comments.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(showAllComments ? post.comments : Array(post.comments.prefix(2))) { comment in
                                CommentRow(comment: comment, viewModel: viewModel)
                            }
                            
                            if post.comments.count > 2 && !showAllComments {
                                Button(action: { showAllComments = true }) {
                                    Text("返信をさらに表示")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                .padding(.leading, 52)
                            }
                        }
                        .padding(.top, 8)
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

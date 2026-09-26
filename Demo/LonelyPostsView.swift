//
//  LonelyPostsView.swift
//  AIsns
//
//  Created by Apple on 2026/01/30.
//

import SwiftUI

// MARK: - Models
struct LonelyPost: Identifiable {
    let id = UUID()
    let content: String
    let imageURL: String?
    let postedAt: Date
    let likes: Int
    let comments: Int
    let reposts: Int
    let views: Int
}

// MARK: - Main View
struct LonelyPostsView: View {
    @State private var posts: [LonelyPost] = []
    @State private var showingComposer = false
    @State private var newPostText = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(posts) { post in
                            LonelyPostCell(post: post)
                            Divider()
                                .padding(.leading, 70)
                        }
                    }
                }
                
                // 投稿ボタン
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showingComposer = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2.bold())
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
                                .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("自分の投稿")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Circle()
                        .fill(LinearGradient(colors: [.gray, .gray.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text("私")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        )
                }
            }
            .sheet(isPresented: $showingComposer) {
                PostComposerView1(posts: $posts, isPresented: $showingComposer)
            }
        }
        .onAppear {
            if posts.isEmpty {
                posts = generateLonelyPosts()
            }
        }
    }
    
    // 過疎った投稿を大量生成
    func generateLonelyPosts() -> [LonelyPost] {
        let sadContents = [
            "今日のランチ美味しかった🍜",
            "新しいカフェ見つけた！雰囲気最高✨",
            "朝活始めました💪 誰か一緒にやりませんか？",
            "この映画めっちゃ良かった…感動した😭",
            "プログラミング勉強中📚 難しいけど楽しい",
            "今日の空きれいだった🌅",
            "新しいスニーカー買った👟 お気に入り！",
            "誰かおすすめの本教えて📖",
            "ジム行ってきた！筋肉痛やばい😅",
            "週末何しよう…予定ない",
            "コーヒー淹れるの上手くなってきた☕️",
            "この曲ずっとリピートしてる🎵",
            "料理作ったけど見た目が…味は良いはず",
            "散歩日和だったので3時間歩いた🚶‍♂️",
            "部屋の模様替えした！誰か見て！",
            "今日から日記つけ始めました✍️",
            "最近ハマってるアプリ紹介します！",
            "おすすめのラーメン屋見つけた🍜 並ばずに入れた",
            "今年の目標立てた💫 頑張るぞ",
            "休日なのに早起きしてしまった…",
            "新しい趣味始めたい 何がいいかな",
            "今日は何もしない日にする宣言",
            "お気に入りの文房具紹介🖊️",
            "夜景撮ってみた📷 一人で",
            "美術館行ってきた 空いてて快適だった",
            "自分へのご褒美にケーキ買った🍰",
            "今日の晩ごはん何にしよう…",
            "推しの新曲最高すぎる😭",
            "観葉植物買った🌱 枯らさないように頑張る",
            "今日で連続投稿30日目！誰も気づいてないけど",
            "面白いYouTube見つけた 共有したい",
            "断捨離中…なかなか捨てられない",
            "天気いいからベランダで仕事してみた☀️",
            "新しいレシピ試してみた 成功！",
            "最近運動不足だな…",
            "お気に入りの喫茶店閉店するらしい😢",
            "今日のコーデ自信作👔",
            "積読がやばい…でも新しい本欲しい",
            "DIYに挑戦してみた 意外とできた！",
            "今月の目標達成できそう！自分を褒めたい",
        ]
        
        var posts: [LonelyPost] = []
        
        for i in 0..<40 {
            let hasImage = i % 3 == 0
            let daysAgo = Double(i) * 0.5 + Double.random(in: 0...0.5)
            
            let post = LonelyPost(
                content: sadContents[i % sadContents.count],
                imageURL: hasImage ? "photo_\(i)" : nil,
                postedAt: Date().addingTimeInterval(-86400 * daysAgo),
                likes: Int.random(in: 0...1),
                comments: Int.random(in: 0...0),
                reposts: 0,
                views: Int.random(in: 3...25)
            )
            posts.append(post)
        }
        
        return posts.sorted { $0.postedAt > $1.postedAt }
    }
}

// MARK: - Post Cell
struct LonelyPostCell: View {
    let post: LonelyPost
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // アイコン
            Circle()
                .fill(LinearGradient(colors: [.gray, .gray.opacity(0.6)], startPoint: .top, endPoint: .bottom))
                .frame(width: 48, height: 48)
                .overlay(
                    Text("私")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 8) {
                // ヘッダー
                HStack(spacing: 4) {
                    Text("自分")
                        .font(.subheadline.bold())
                    Text("@lonely_me")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("·")
                        .foregroundColor(.secondary)
                    Text(timeAgoString(from: post.postedAt))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // 本文
                Text(post.content)
                    .font(.body)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                
                // 画像（あれば）
                if post.imageURL != nil {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.gray.opacity(0.3),
                                    Color.gray.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 180)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray.opacity(0.5))
                        )
                }
                
                // アクションボタン（過疎数値）
                HStack(spacing: 0) {
                    // コメント
                    PostActionButton(
                        icon: "bubble.left",
                        count: post.comments,
                        color: .gray
                    )
                    
                    Spacer()
                    
                    // リポスト
                    PostActionButton(
                        icon: "arrow.2.squarepath",
                        count: post.reposts,
                        color: .gray
                    )
                    
                    Spacer()
                    
                    // いいね
                    PostActionButton(
                        icon: post.likes > 0 ? "heart" : "heart",
                        count: post.likes,
                        color: post.likes > 0 ? .gray : .gray
                    )
                    
                    Spacer()
                    
                    // 閲覧数（少ない）
                    PostActionButton(
                        icon: "chart.bar",
                        count: post.views,
                        color: .gray
                    )
                    
                    Spacer()
                    
                    // 共有
                    Button {
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 4)
                .padding(.trailing, 20)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "たった今"
        } else if interval < 3600 {
            return "\(Int(interval / 60))分"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))時間"
        } else if interval < 604800 {
            return "\(Int(interval / 86400))日"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Action Button
struct PostActionButton: View {
    let icon: String
    let count: Int
    let color: Color
    
    var body: some View {
        Button {
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.subheadline)
                if count > 0 {
                    Text("\(count)")
                        .font(.caption)
                }
            }
            .foregroundColor(color)
        }
    }
}

// MARK: - Post Composer
struct PostComposerView1: View {
    @Binding var posts: [LonelyPost]
    @Binding var isPresented: Bool
    @State private var text = ""
    @State private var includeImage = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    Circle()
                        .fill(LinearGradient(colors: [.gray, .gray.opacity(0.6)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text("私")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("いまどうしてる？", text: $text, axis: .vertical)
                            .font(.body)
                            .focused($isFocused)
                        
                        if includeImage {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 150)
                                .overlay(
                                    VStack {
                                        Image(systemName: "photo.badge.plus")
                                            .font(.title)
                                            .foregroundColor(.gray)
                                        Text("画像を追加")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                )
                                .overlay(alignment: .topTrailing) {
                                    Button {
                                        includeImage = false
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                            .padding(8)
                                    }
                                }
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                // ツールバー
                Divider()
                HStack(spacing: 20) {
                    Button {
                        includeImage.toggle()
                    } label: {
                        Image(systemName: "photo")
                            .foregroundColor(.blue)
                    }
                    
                    Button {
                    } label: {
                        Image(systemName: "gif")
                            .foregroundColor(.blue)
                    }
                    
                    Button {
                    } label: {
                        Image(systemName: "face.smiling")
                            .foregroundColor(.blue)
                    }
                    
                    Button {
                    } label: {
                        Image(systemName: "location")
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        addPost()
                    } label: {
                        Text("投稿する")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(text.isEmpty ? Color.gray : Color.blue)
                            )
                    }
                    .disabled(text.isEmpty)
                }
            }
        }
        .onAppear {
            isFocused = true
        }
    }
    
    func addPost() {
        let newPost = LonelyPost(
            content: text,
            imageURL: includeImage ? "new_photo" : nil,
            postedAt: Date(),
            likes: 0,
            comments: 0,
            reposts: 0,
            views: Int.random(in: 1...5) // 新規投稿も過疎る
        )
        posts.insert(newPost, at: 0)
        isPresented = false
    }
}

// MARK: - Preview
#Preview {
    LonelyPostsView()
}

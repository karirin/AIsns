//
//  BuzzingSNSView.swift
//  AIsns
//
//  Created by Apple on 2026/01/30.
//

import SwiftUI

// MARK: - Main Tab View
struct BuzzingSNSView: View {
    @State private var selectedTab = 0
    @State private var notificationCount = 0
    @State private var posts: [BuzzPost] = []
    @State private var showingComposer = false
    
    let timer = Timer.publish(every: 0.8, on: .main, in: .common).autoconnect()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // ホーム（バズってる投稿一覧）
            BuzzingTimelineView1(posts: $posts, showingComposer: $showingComposer)
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("ホーム")
                }
                .tag(0)
            
            // 検索
            SearchPlaceholderView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "magnifyingglass.circle.fill" : "magnifyingglass")
                    Text("検索")
                }
                .tag(1)
            
            // 通知（バッジ付き）
            NotificationsView(notificationCount: $notificationCount)
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "bell.fill" : "bell")
                    Text("通知")
                }
                .tag(2)
                .badge(notificationCount > 99 ? "99+" : (notificationCount > 0 ? "\(notificationCount)" : nil))
            
            // メッセージ
            MessagesPlaceholderView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "envelope.fill" : "envelope")
                    Text("メッセージ")
                }
                .tag(3)
        }
        .tint(.blue)
        .onAppear {
            if posts.isEmpty {
                posts = generateBuzzingPosts()
            }
        }
        .onReceive(timer) { _ in
            // 通知がどんどん増える！
            if selectedTab != 2 {
                withAnimation(.spring(response: 0.3)) {
                    notificationCount += Int.random(in: 1...5)
                }
                
                // 投稿の数値もリアルタイムで増加
                updatePostEngagement()
            }
        }
        .sheet(isPresented: $showingComposer) {
            BuzzPostComposerView(posts: $posts, isPresented: $showingComposer)
        }
    }
    
    func updatePostEngagement() {
        for i in posts.indices {
            if Bool.random() {
                posts[i].likes += Int.random(in: 10...100)
                posts[i].reposts += Int.random(in: 1...20)
                posts[i].views += Int.random(in: 100...1000)
                if Bool.random() {
                    posts[i].comments += Int.random(in: 1...10)
                }
            }
        }
    }
    
    func generateBuzzingPosts() -> [BuzzPost] {
        let buzzContents = [
            "【朗報】ついに夢が叶いました！！！長かった…😭✨ 応援してくれた皆さん本当にありがとうございます！！",
            "これマジで有益すぎるから保存推奨🔖\n\n知らないと損する〇〇の裏技10選👇",
            "え、待って。これ天才すぎない？？？🤯",
            "3年かけて作ったアプリがついにリリースされました！！良かったらDLお願いします🙏✨",
            "【悲報】会社辞めてフリーランスになった結果wwwww",
            "猫が最高すぎる動画撮れたから見て😺💕",
            "この考え方で人生変わった。まじで。",
            "100万回再生されたあの動画の裏側を公開します",
            "プログラミング初心者だった僕が年収1000万になるまでにやったこと全部書く",
            "【神アプデ】iOS最新版のこの機能やばすぎ！！！",
            "結婚します！！！🎉💒 報告遅くなってごめんなさい！",
            "この投稿が1万いいね行ったら〇〇します",
            "人生で一番美味しいラーメンに出会ってしまった…🍜✨",
            "転職して気づいた「優秀な人」の共通点がこれ",
            "【速報】新サービスの事前登録が10万人突破しました！！！",
            "これ知ってる人RT🔁 知らない人いいね❤️",
            "3ヶ月で20kg痩せた方法を全部公開する",
            "AIに絵を描かせたらとんでもないことになった件について",
            "今日の空がエモすぎて泣いた🌅",
            "子どもが初めて歩いた瞬間を撮れた…😭👶",
        ]
        
        var posts: [BuzzPost] = []
        
        for i in 0..<20 {
            let hasImage = i % 2 == 0
            let hoursAgo = Double(i) * 2 + Double.random(in: 0...1)
            
            let post = BuzzPost(
                content: buzzContents[i],
                imageURL: hasImage ? "viral_photo_\(i)" : nil,
                postedAt: Date().addingTimeInterval(-3600 * hoursAgo),
                likes: Int.random(in: 5000...50000),
                comments: Int.random(in: 500...3000),
                reposts: Int.random(in: 1000...10000),
                views: Int.random(in: 100000...2000000),
                isVerified: i < 5
            )
            posts.append(post)
        }
        
        return posts.sorted { $0.postedAt > $1.postedAt }
    }
}

// MARK: - Models
struct BuzzPost: Identifiable {
    let id = UUID()
    let content: String
    let imageURL: String?
    let postedAt: Date
    var likes: Int
    var comments: Int
    var reposts: Int
    var views: Int
    var isVerified: Bool
}

// MARK: - Buzzing Timeline
struct BuzzingTimelineView1: View {
    @Binding var posts: [BuzzPost]
    @Binding var showingComposer: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(posts) { post in
                            BuzzPostCell(post: post)
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
                                        colors: [.blue, .cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: .blue.opacity(0.4), radius: 10, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.orange, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text("私")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.yellow, lineWidth: 2)
                        )
                }
            }
        }
    }
}

// MARK: - Buzz Post Cell
struct BuzzPostCell: View {
    let post: BuzzPost
    @State private var isLiked = false
    @State private var showFireworks = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // アイコン（グラデーション付き）
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.orange, .pink, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 48)
                .overlay(
                    Text("私")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                )
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2
                        )
                )
            
            VStack(alignment: .leading, spacing: 8) {
                // ヘッダー
                HStack(spacing: 4) {
                    Text("自分")
                        .font(.subheadline.bold())
                    
                    if post.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    Text("@buzz_master")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("·")
                        .foregroundColor(.secondary)
                    Text(timeAgoString(from: post.postedAt))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                }
                
                // 本文
                Text(post.content)
                    .font(.body)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                
                // 画像（あれば）
                if post.imageURL != nil {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.purple.opacity(0.3),
                                    Color.pink.opacity(0.3),
                                    Color.orange.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 200)
                        .overlay(
                            VStack {
                                Image(systemName: "photo.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        )
                }
                
                // アクションボタン（バズり数値）
                HStack(spacing: 0) {
                    // コメント
                    BuzzActionButton(
                        icon: "bubble.left.fill",
                        count: post.comments,
                        color: .blue
                    )
                    
                    Spacer()
                    
                    // リポスト
                    BuzzActionButton(
                        icon: "arrow.2.squarepath",
                        count: post.reposts,
                        color: .green
                    )
                    
                    Spacer()
                    
                    // いいね（アニメーション付き）
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            isLiked.toggle()
                            showFireworks = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showFireworks = false
                        }
                    } label: {
                        HStack(spacing: 4) {
                            ZStack {
                                Image(systemName: isLiked ? "heart.fill" : "heart.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.pink)
                                    .scaleEffect(isLiked ? 1.3 : 1.0)
                                
                                if showFireworks {
                                    ForEach(0..<6, id: \.self) { i in
                                        Circle()
                                            .fill(Color.pink)
                                            .frame(width: 4, height: 4)
                                            .offset(
                                                x: cos(Double(i) * .pi / 3) * 15,
                                                y: sin(Double(i) * .pi / 3) * 15
                                            )
                                            .opacity(showFireworks ? 0 : 1)
                                    }
                                }
                            }
                            Text(formatCount(post.likes + (isLiked ? 1 : 0)))
                                .font(.caption.bold())
                                .foregroundColor(.pink)
                        }
                    }
                    
                    Spacer()
                    
                    // 閲覧数（めちゃ多い）
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")
                            .font(.subheadline)
                        Text(formatCount(post.views))
                            .font(.caption.bold())
                    }
                    .foregroundColor(.cyan)
                    
                    Spacer()
                    
                    // 共有
                    Button {
                    } label: {
                        Image(systemName: "square.and.arrow.up.fill")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.top, 8)
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
        } else {
            return "\(Int(interval / 86400))日"
        }
    }
    
    func formatCount(_ count: Int) -> String {
        if count >= 1000000 {
            return String(format: "%.1fM", Double(count) / 1000000)
        } else if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000)
        }
        return "\(count)"
    }
}

// MARK: - Buzz Action Button
struct BuzzActionButton: View {
    let icon: String
    let count: Int
    let color: Color
    
    var body: some View {
        Button {
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.subheadline)
                Text(formatCount(count))
                    .font(.caption.bold())
            }
            .foregroundColor(color)
        }
    }
    
    func formatCount(_ count: Int) -> String {
        if count >= 1000000 {
            return String(format: "%.1fM", Double(count) / 1000000)
        } else if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000)
        }
        return "\(count)"
    }
}

// MARK: - Notifications View
struct NotificationsView: View {
    @Binding var notificationCount: Int
    @State private var notifications: [BuzzNotification] = []
    
    let notificationTypes: [(String, String, Color)] = [
        ("heart.fill", "いいね", .pink),
        ("arrow.2.squarepath", "リポスト", .green),
        ("bubble.left.fill", "コメント", .blue),
        ("person.badge.plus.fill", "フォロー", .purple),
        ("quote.opening", "引用", .orange),
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(notifications) { notification in
                        NotificationCell(notification: notification)
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            .navigationTitle("通知")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation {
                            notificationCount = 0
                        }
                    } label: {
                        Text("既読")
                            .font(.subheadline)
                    }
                }
            }
        }
        .onAppear {
            if notifications.isEmpty {
                notifications = generateNotifications(count: 50)
            }
            notificationCount = 0
        }
    }
    
    func generateNotifications(count: Int) -> [BuzzNotification] {
        let names = ["田中さん", "佐藤さん", "鈴木くん", "高橋さん", "伊藤くん", "渡辺さん", "山本さん", "中村くん", "小林さん", "加藤くん", "吉田さん", "山田くん", "松本さん", "井上さん", "木村くん", "林さん", "斎藤さん", "清水くん", "山崎さん", "森さん"]
        
        var notifications: [BuzzNotification] = []
        
        for i in 0..<count {
            let type = notificationTypes.randomElement()!
            let minutesAgo = i * 2 + Int.random(in: 0...5)
            
            let notification = BuzzNotification(
                icon: type.0,
                iconColor: type.2,
                userName: names.randomElement()!,
                action: type.1,
                targetPost: "あなたの投稿",
                time: Date().addingTimeInterval(TimeInterval(-minutesAgo * 60)),
                isNew: i < 10
            )
            notifications.append(notification)
        }
        
        return notifications
    }
}

// MARK: - Notification Model
struct BuzzNotification: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let userName: String
    let action: String
    let targetPost: String
    let time: Date
    let isNew: Bool
}

// MARK: - Notification Cell
struct NotificationCell: View {
    let notification: BuzzNotification
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // アイコン
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                
                Image(systemName: notification.icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(notification.userName)
                        .font(.subheadline.bold())
                    Text("さんが\(notification.action)しました")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(notification.targetPost)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(timeAgoString(from: notification.time))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if notification.isNew {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(notification.isNew ? Color.blue.opacity(0.05) : Color(.systemBackground))
    }
    
    func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "たった今"
        } else if interval < 3600 {
            return "\(Int(interval / 60))分前"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))時間前"
        } else {
            return "\(Int(interval / 86400))日前"
        }
    }
}

// MARK: - Placeholder Views
struct SearchPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "magnifyingglass")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("検索")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("検索")
        }
    }
}

struct MessagesPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "envelope")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("メッセージ")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("メッセージ")
        }
    }
}

// MARK: - Post Composer
struct BuzzPostComposerView: View {
    @Binding var posts: [BuzzPost]
    @Binding var isPresented: Bool
    @State private var text = ""
    @State private var includeImage = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.orange, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
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
                                .fill(
                                    LinearGradient(
                                        colors: [.purple.opacity(0.3), .pink.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 150)
                                .overlay(
                                    VStack {
                                        Image(systemName: "photo.badge.plus")
                                            .font(.title)
                                            .foregroundColor(.purple)
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
                    
                    Button {} label: {
                        Image(systemName: "gif")
                            .foregroundColor(.blue)
                    }
                    
                    Button {} label: {
                        Image(systemName: "face.smiling")
                            .foregroundColor(.blue)
                    }
                    
                    Button {} label: {
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
                                    .fill(
                                        text.isEmpty ?
                                        LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing) :
                                        LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)
                                    )
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
        let newPost = BuzzPost(
            content: text,
            imageURL: includeImage ? "new_buzz_photo" : nil,
            postedAt: Date(),
            likes: Int.random(in: 1000...5000),
            comments: Int.random(in: 100...500),
            reposts: Int.random(in: 200...1000),
            views: Int.random(in: 10000...50000),
            isVerified: true
        )
        posts.insert(newPost, at: 0)
        isPresented = false
    }
}

// MARK: - Preview
#Preview {
    BuzzingSNSView()
}

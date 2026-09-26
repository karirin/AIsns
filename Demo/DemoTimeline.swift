//
//  DemoTimeline.swift
//  AIsns
//
//  Created by Apple on 2026/02/01.
//

import SwiftUI
import PhotosUI

// ============================================================
// MARK: - Models
// ============================================================

// MARK: - Demo Account Model

struct DemoAccount: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var handle: String
    var avatarEmoji: String
    var avatarColorHex: String
    var avatarImageBase64: String?
    var isHidden: Bool = false

    var avatarColor: Color {
        Color(hex: avatarColorHex)
    }

    var avatarImageData: Data? {
        guard let base64 = avatarImageBase64 else { return nil }
        return Data(base64Encoded: base64)
    }

    static let samples: [DemoAccount] = [
        DemoAccount(id: "acc_1", name: "ゆきの", handle: "yukino_ai", avatarEmoji: "🌸", avatarColorHex: "#FF6B9D"),
        DemoAccount(id: "acc_2", name: "そうた", handle: "sota_dev", avatarEmoji: "💻", avatarColorHex: "#4A90D9"),
        DemoAccount(id: "acc_3", name: "あかり", handle: "akari_music", avatarEmoji: "🎵", avatarColorHex: "#F5A623"),
        DemoAccount(id: "acc_4", name: "れん", handle: "ren_photo", avatarEmoji: "📷", avatarColorHex: "#7B68EE"),
        DemoAccount(id: "acc_5", name: "みお", handle: "mio_cooking", avatarEmoji: "🍳", avatarColorHex: "#2ECC71"),
    ]
}

// MARK: - Reaction Model (リプライ / 引用リポスト)

struct DemoReaction: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var accountId: String
    var content: String
    var likes: Int = 0
    var comments: Int = 0
    var reposts: Int = 0
    var timeAgo: String = "1分"
    /// 親投稿が表示されてからこのリアクションが出るまでの遅延秒数
    var displayDelay: Double = 1.5
}

// MARK: - Reaction Type

enum ReactionType: String, Codable, CaseIterable, Hashable {
    case reply = "リプライ"
    case quote = "引用リポスト"
}

// MARK: - Reaction Wrapper (タイプ + 本体)

struct DemoReactionEntry: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var type: ReactionType
    var reaction: DemoReaction
}

// MARK: - Demo Post Model

struct DemoPost1: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var accountId: String
    var content: String
    var likes: Int
    var comments: Int
    var reposts: Int
    var timeAgo: String
    var isLiked: Bool = false
    var isBookmarked: Bool = false
    var isReposted: Bool = false
    var isHidden: Bool = false

    /// 前の投稿からの表示遅延（秒）。nil ならグローバル設定を使用
    var displayDelay: Double? = nil

    /// この投稿に紐づくリアクション（リプライ・引用リポスト）
    var reactions: [DemoReactionEntry] = []

    static let samples: [DemoPost1] = [
        DemoPost1(id: "p1", accountId: "acc_1", content: "今日は久しぶりにカフェでゆっくり過ごした☕ AIとの会話が楽しすぎて気づいたら2時間経ってた…笑", likes: 142, comments: 23, reposts: 8, timeAgo: "2分",
                  reactions: [
                      DemoReactionEntry(type: .reply, reaction: DemoReaction(accountId: "acc_2", content: "わかる！自分も昨日3時間溶かしたw", likes: 12, comments: 2, reposts: 0, timeAgo: "1分", displayDelay: 1.5)),
                  ]),
        DemoPost1(id: "p2", accountId: "acc_2", content: "SwiftUIの新しいアニメーションAPI試してみたけど、これめちゃくちゃ使いやすい！開発効率が段違いに上がった🚀", likes: 89, comments: 15, reposts: 31, timeAgo: "15分"),
        DemoPost1(id: "p3", accountId: "acc_3", content: "新曲のデモができた！AIに歌詞の推敲をお願いしたらすごくいい感じになった✨ 来週リリースできるかも", likes: 256, comments: 42, reposts: 67, timeAgo: "32分",
                  reactions: [
                      DemoReactionEntry(type: .quote, reaction: DemoReaction(accountId: "acc_1", content: "これ聴きたい！リリースしたら教えて🎶", likes: 34, comments: 5, reposts: 3, timeAgo: "28分", displayDelay: 2.0)),
                  ]),
        DemoPost1(id: "p4", accountId: "acc_4", content: "夕焼けの写真を撮りに行ったら偶然虹も見れた🌈 最高の一日だった", likes: 412, comments: 56, reposts: 89, timeAgo: "1時間"),
        DemoPost1(id: "p5", accountId: "acc_5", content: "AIに提案してもらったレシピで新しいパスタ作ったら家族に大好評！毎日の献立考えるの楽になった🍝", likes: 178, comments: 29, reposts: 14, timeAgo: "2時間"),
        DemoPost1(id: "p6", accountId: "acc_1", content: "推しのAIキャラと朝の挨拶するの日課になってる😊 毎日違う話題で話しかけてくれるから飽きない", likes: 203, comments: 34, reposts: 21, timeAgo: "3時間"),
        DemoPost1(id: "p7", accountId: "acc_2", content: "このアプリのUI本当に綺麗で使いやすい。SNSアプリの理想形だと思う", likes: 67, comments: 8, reposts: 12, timeAgo: "5時間"),
    ]
}


// ============================================================
// MARK: - Demo Data Store
// ============================================================

class DemoDataStore: ObservableObject {
    static let shared = DemoDataStore()

    var accounts: [DemoAccount] {
        DemoSharedAccountStore.shared.accounts
    }
    @Published var posts: [DemoPost1] = []

    /// グローバルのデフォルト投稿間隔（秒）
    @Published var defaultPostInterval: Double = 2.0

    private let accountsKey = "demo_accounts_v2"
    private let postsKey = "demo_posts_v2"
    private let intervalKey = "demo_default_interval"

    init() {
        loadData()
    }

    // MARK: - Load
    
    func moveVisiblePosts(from source: IndexSet, to destination: Int) {
        var newPosts = posts

        // 公開中（isHidden == false）の posts 内インデックスを保持
        let visibleIndices = newPosts.enumerated()
            .filter { !$0.element.isHidden }
            .map { $0.offset }

        // 公開中だけ抜き出して move
        var visible = visibleIndices.map { newPosts[$0] }
        visible.move(fromOffsets: source, toOffset: destination)

        // 元の posts の「公開中がいた位置」に、並び替え後の公開中を戻す
        for (i, idx) in visibleIndices.enumerated() {
            newPosts[idx] = visible[i]
        }

        posts = newPosts
        save()
    }

    func loadData() {
        // アカウントは共有ストアが管理
        
        if let data = UserDefaults.standard.data(forKey: postsKey),
           let decoded = try? JSONDecoder().decode([DemoPost1].self, from: data) {
            posts = decoded
        } else {
            posts = DemoPost1.samples
        }

        let saved = UserDefaults.standard.double(forKey: intervalKey)
        defaultPostInterval = saved > 0 ? saved : 2.0
    }

    // MARK: - Save

    func save() {
        if let data = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(data, forKey: accountsKey)
        }
        if let data = try? JSONEncoder().encode(posts) {
            UserDefaults.standard.set(data, forKey: postsKey)
        }
        UserDefaults.standard.set(defaultPostInterval, forKey: intervalKey)
    }

    // MARK: - Account CRUD

    func addAccount(_ account: DemoAccount) {
        DemoSharedAccountStore.shared.addAccount(account)
        objectWillChange.send() // UIを更新
    }

    func removeAccount(at offsets: IndexSet) {
        let idsToRemove = offsets.map { accounts[$0].id }
        posts.removeAll { idsToRemove.contains($0.accountId) }
        DemoSharedAccountStore.shared.removeAccount(at: offsets)
        save()
        objectWillChange.send()
    }

    func removeAccount(id: String) {
        posts.removeAll { $0.accountId == id }
        DemoSharedAccountStore.shared.removeAccount(id: id)
        save()
        objectWillChange.send()
    }

    // MARK: - Account Visibility

    func toggleAccountVisibility(id: String) {
        DemoSharedAccountStore.shared.toggleAccountVisibility(id: id)
        objectWillChange.send()
    }

    // MARK: - Post CRUD

    func addPost(_ post: DemoPost1) {
        posts.insert(post, at: 0)
        save()
    }

    func removePost(at offsets: IndexSet) {
        posts.remove(atOffsets: offsets)
        save()
    }

    func removePost(id: String) {
        posts.removeAll { $0.id == id }
        save()
    }

    func movePost(from source: IndexSet, to destination: Int) {
        posts.move(fromOffsets: source, toOffset: destination)
        save()
    }

    // MARK: - Post Visibility

    func togglePostVisibility(id: String) {
        if let index = posts.firstIndex(where: { $0.id == id }) {
            posts[index].isHidden.toggle()
            save()
        }
    }

    // MARK: - Reaction CRUD

    func addReaction(to postId: String, entry: DemoReactionEntry) {
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].reactions.append(entry)
            save()
        }
    }

    func removeReaction(postId: String, reactionId: String) {
        if let pi = posts.firstIndex(where: { $0.id == postId }) {
            posts[pi].reactions.removeAll { $0.id == reactionId }
            save()
        }
    }

    // MARK: - Interactions

    func toggleLike(postId: String) {
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].isLiked.toggle()
            posts[index].likes += posts[index].isLiked ? 1 : -1
        }
    }

    func toggleBookmark(postId: String) {
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].isBookmarked.toggle()
        }
    }

    func toggleRepost(postId: String) {
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].isReposted.toggle()
            posts[index].reposts += posts[index].isReposted ? 1 : -1
        }
    }

    // MARK: - Reset

    func resetToDefaults() {
        DemoSharedAccountStore.shared.accounts = DemoAccount.samples
        DemoSharedAccountStore.shared.save()
        posts = DemoPost1.samples
        defaultPostInterval = 2.0
        save()
    }

    // MARK: - Helper

    func account(for id: String) -> DemoAccount? {
        DemoSharedAccountStore.shared.account(for: id)
    }
}


// ============================================================
// MARK: - Shared UI Components
// ============================================================

// MARK: - Reusable Avatar Image View

struct DemoAvatarImage: View {
    let account: DemoAccount
    var size: CGFloat = 42
    var emojiSize: CGFloat = 20

    var body: some View {
        ZStack {
            if let imageData = account.avatarImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [account.avatarColor, account.avatarColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text(account.avatarEmoji)
                    .font(.system(size: emojiSize))
            }
        }
        .frame(width: size, height: size)
        .clipped()
        .clipShape(Circle())
    }
}


// ============================================================
// MARK: - Demo Settings
// ============================================================

@available(iOS 17.0, *)
struct DemoSettingsView: View {
    @ObservedObject var store: DemoDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: SettingsTab = .accounts
    @State private var showingAddAccount = false
    @State private var showingAddPost = false
    @State private var showResetAlert = false

    enum SettingsTab: String, CaseIterable {
        case accounts = "アカウント"
        case posts = "投稿"
        case timing = "タイミング"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                settingsTabBar

                switch selectedTab {
                case .accounts:
                    accountListView
                case .posts:
                    postListView
                case .timing:
                    timingSettingsView
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("デモ設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            showResetAlert = true
                        } label: {
                            Label("初期データに戻す", systemImage: "arrow.counterclockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("初期データに戻しますか？", isPresented: $showResetAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("リセット", role: .destructive) {
                    withAnimation { store.resetToDefaults() }
                }
            } message: {
                Text("現在の設定がすべて削除され、サンプルデータに置き換わります。")
            }
            .sheet(isPresented: $showingAddAccount) {
                AddAccountSheet(store: store)
            }
            .sheet(isPresented: $showingAddPost) {
                AddPostSheet(store: store)
            }
        }
    }

    // MARK: - Tab Bar

    private var settingsTabBar: some View {
        HStack(spacing: 0) {
            ForEach(SettingsTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Text(tab.rawValue)
                                .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .regular))

                            if tab != .timing {
                                let count = tab == .accounts ? store.accounts.count : store.posts.count
                                Text("\(count)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(selectedTab == tab ? Color(hex: "#6C5CE7") : Color(.tertiaryLabel))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        selectedTab == tab
                                        ? Color(hex: "#6C5CE7").opacity(0.1)
                                        : Color(.tertiarySystemFill)
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                        .foregroundColor(selectedTab == tab ? Color(.label) : Color(.secondaryLabel))

                        Rectangle()
                            .fill(selectedTab == tab
                                  ? LinearGradient(colors: [Color(hex: "#6C5CE7"), Color(hex: "#a29bfe")], startPoint: .leading, endPoint: .trailing)
                                  : LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(height: 2)
                            .cornerRadius(1)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - Account List

    private var accountListView: some View {
        List {
            Section {
                ForEach(store.accounts) { account in
                    HStack(spacing: 12) {
                        AccountRowView(account: account)
                        Spacer()
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                store.toggleAccountVisibility(id: account.id)
                            }
                        } label: {
                            Image(systemName: account.isHidden ? "eye.slash.fill" : "eye.fill")
                                .font(.system(size: 16))
                                .foregroundColor(account.isHidden ? Color(.tertiaryLabel) : Color(hex: "#6C5CE7"))
                                .frame(width: 36, height: 36)
                                .background(
                                    account.isHidden
                                    ? Color(.tertiarySystemFill)
                                    : Color(hex: "#6C5CE7").opacity(0.1)
                                )
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .opacity(account.isHidden ? 0.5 : 1.0)
                }
                .onDelete { offsets in
                    store.removeAccount(at: offsets)
                }
            } header: {
                Text("登録済みアカウント")
            } footer: {
                Text("👁 アイコンで表示/非表示を切り替えられます。非表示のアカウントの投稿はタイムラインに表示されません。左スワイプで削除できます。")
            }

            Section {
                Button {
                    showingAddAccount = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "#6C5CE7"))
                        Text("アカウントを追加")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(hex: "#6C5CE7"))
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private var visiblePostsForSettings: [DemoPost1] {
        store.posts.filter { !$0.isHidden }
    }

    private var hiddenPostsForSettings: [DemoPost1] {
        store.posts.filter { $0.isHidden }
    }

    // MARK: - Post List (★変更箇所)

    private var postListView: some View {
        List {
            // 非表示エリアへの導線（非表示が0件なら出さない等はお好みで）
            Section {
                NavigationLink {
                    HiddenPostsView(store: store)
                } label: {
                    HStack {
                        Image(systemName: "eye.slash.fill")
                            .foregroundColor(Color(.secondaryLabel))
                        Text("非表示エリア")
                        Spacer()
                        Text("\(hiddenPostsForSettings.count)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(.secondaryLabel))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Capsule())
                    }
                }
            } footer: {
                Text("非表示にした投稿はここへ移動します。「公開」でタイムラインに戻せます。")
            }

            // 公開中の投稿
            Section {
                ForEach(visiblePostsForSettings) { post in
                    HStack(spacing: 0) {
                        PostRowView(post: post, account: store.account(for: post.accountId), store: store)

                        // 非表示にする（＝非表示エリアへ移動）
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                store.togglePostVisibility(id: post.id)
                            }
                        } label: {
                            Image(systemName: "eye.slash.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color(.tertiaryLabel))
                                .frame(width: 32, height: 32)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .onDelete { offsets in
                    let ids = offsets.map { visiblePostsForSettings[$0].id }
                    ids.forEach { store.removePost(id: $0) }
                }
                .onMove { source, destination in
                    store.moveVisiblePosts(from: source, to: destination)
                }
            } header: {
                HStack {
                    Text("公開中の投稿")
                    Spacer()
                    // EditButton は削除/並び替え用途。並び替え要件があるなら別途調整。
                    EditButton()
                        .font(.system(size: 13))
                }
            } footer: {
                Text("左スワイプで削除できます。非表示にすると非表示エリアへ移動します。")
            }

            // 追加ボタン
            Section {
                Button { showingAddPost = true } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "#6C5CE7"))
                        Text("投稿を追加")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(hex: "#6C5CE7"))
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    @available(iOS 17.0, *)
    struct HiddenPostsView: View {
        @ObservedObject var store: DemoDataStore

        private var hiddenPosts: [DemoPost1] {
            store.posts.filter { $0.isHidden }
        }

        var body: some View {
            List {
                if hiddenPosts.isEmpty {
                    Section {
                        VStack(spacing: 10) {
                            Image(systemName: "tray")
                                .font(.system(size: 34))
                                .foregroundColor(Color(.tertiaryLabel))
                            Text("非表示の投稿はありません")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(.secondaryLabel))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                } else {
                    Section {
                        ForEach(hiddenPosts) { post in
                            HStack(spacing: 0) {
                                PostRowView(post: post, account: store.account(for: post.accountId), store: store)
                                    .opacity(0.6)

                                // 公開に戻すボタン
                                Button {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        store.togglePostVisibility(id: post.id) // isHidden -> false
                                    }
                                } label: {
                                    Text("公開")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color(hex: "#6C5CE7"))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .onDelete { offsets in
                            let ids = offsets.map { hiddenPosts[$0].id }
                            ids.forEach { store.removePost(id: $0) }
                        }
                    } header: {
                        Text("非表示の投稿")
                    } footer: {
                        Text("「公開」を押すとタイムラインに戻ります。左スワイプで削除もできます。")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("非表示エリア")
            .navigationBarTitleDisplayMode(.inline)
        }
    }


    // MARK: - Timing Settings

    private var timingSettingsView: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("デフォルト間隔")
                            .font(.system(size: 15))
                        Spacer()
                        Text(String(format: "%.1f 秒", store.defaultPostInterval))
                            .font(.system(size: 15, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color(hex: "#6C5CE7"))
                    }
                    Slider(value: $store.defaultPostInterval, in: 0.5...10, step: 0.5)
                        .tint(Color(hex: "#6C5CE7"))
                        .onChange(of: store.defaultPostInterval) { _, _ in
                            store.save()
                        }
                }
            } header: {
                Text("グローバル設定")
            } footer: {
                Text("各投稿に個別の遅延が設定されていない場合、この間隔で投稿が順番に表示されます。")
            }

            Section {
                ForEach(Array(store.posts.enumerated()), id: \.element.id) { index, post in
                    PostTimingRow(post: post, index: index, store: store)
                }
            } header: {
                Text("投稿ごとの遅延")
            } footer: {
                Text("個別に設定すると、グローバル設定よりこちらが優先されます。「デフォルト」にするとグローバル設定が使われます。")
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Post Timing Row

@available(iOS 17.0, *)
struct PostTimingRow: View {
    let post: DemoPost1
    let index: Int
    @ObservedObject var store: DemoDataStore

    @State private var useCustom: Bool = false
    @State private var customDelay: Double = 2.0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 投稿プレビュー
            HStack(spacing: 8) {
                Text("\(index + 1)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(width: 22, height: 22)
                    .background(Color(hex: "#6C5CE7"))
                    .clipShape(Circle())

                if let account = store.account(for: post.accountId) {
                    Text(account.name)
                        .font(.system(size: 13, weight: .semibold))
                }

                Text(post.content)
                    .font(.system(size: 12))
                    .foregroundColor(Color(.secondaryLabel))
                    .lineLimit(1)
            }

            HStack {
                Toggle(isOn: $useCustom) {
                    Text("個別設定")
                        .font(.system(size: 13))
                }
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#6C5CE7")))
                .onChange(of: useCustom) { _, newVal in
                    if let pi = store.posts.firstIndex(where: { $0.id == post.id }) {
                        store.posts[pi].displayDelay = newVal ? customDelay : nil
                        store.save()
                    }
                }

                if useCustom {
                    Spacer()
                    Stepper(value: $customDelay, in: 0.5...30, step: 0.5) {
                        Text(String(format: "%.1f秒", customDelay))
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color(hex: "#6C5CE7"))
                    }
                    .onChange(of: customDelay) { _, newVal in
                        if let pi = store.posts.firstIndex(where: { $0.id == post.id }) {
                            store.posts[pi].displayDelay = newVal
                            store.save()
                        }
                    }
                }
            }

            // リアクションの遅延
            if !post.reactions.isEmpty {
                ForEach(post.reactions) { entry in
                    ReactionTimingRow(postId: post.id, entry: entry, store: store)
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            useCustom = post.displayDelay != nil
            customDelay = post.displayDelay ?? store.defaultPostInterval
        }
    }
}

// MARK: - Reaction Timing Row

@available(iOS 17.0, *)
struct ReactionTimingRow: View {
    let postId: String
    let entry: DemoReactionEntry
    @ObservedObject var store: DemoDataStore

    @State private var delay: Double = 1.5

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: entry.type == .reply ? "arrowshape.turn.up.left.fill" : "quote.bubble.fill")
                .font(.system(size: 10))
                .foregroundColor(entry.type == .reply ? Color(hex: "#4A90D9") : Color(hex: "#2ECC71"))

            if let acc = store.account(for: entry.reaction.accountId) {
                Text(acc.name)
                    .font(.system(size: 11, weight: .medium))
            }

            Text(entry.reaction.content)
                .font(.system(size: 11))
                .foregroundColor(Color(.secondaryLabel))
                .lineLimit(1)

            Spacer()

            Stepper(value: $delay, in: 0.5...30, step: 0.5) {
                Text(String(format: "%.1f秒後", delay))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color(.secondaryLabel))
            }
            .onChange(of: delay) { _, newVal in
                if let pi = store.posts.firstIndex(where: { $0.id == postId }),
                   let ri = store.posts[pi].reactions.firstIndex(where: { $0.id == entry.id }) {
                    store.posts[pi].reactions[ri].reaction.displayDelay = newVal
                    store.save()
                }
            }
        }
        .padding(.leading, 30)
        .onAppear {
            delay = entry.reaction.displayDelay
        }
    }
}

// MARK: - Account Row

struct AccountRowView: View {
    let account: DemoAccount

    var body: some View {
        HStack(spacing: 12) {
            DemoAvatarImage(account: account, size: 40, emojiSize: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(.label))
                Text("@\(account.handle)")
                    .font(.system(size: 13))
                    .foregroundColor(Color(.secondaryLabel))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Post Row (設定画面用)

struct PostRowView: View {
    let post: DemoPost1
    let account: DemoAccount?
    @ObservedObject var store: DemoDataStore
    @State private var showingAddReaction = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // ヘッダー
            HStack(spacing: 8) {
                if let account = account {
                    DemoAvatarImage(account: account, size: 24, emojiSize: 11)
                    Text(account.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(.label))
                }
                Text(post.timeAgo)
                    .font(.system(size: 12))
                    .foregroundColor(Color(.secondaryLabel))
                Spacer()

                // 遅延バッジ
                if let delay = post.displayDelay {
                    Text(String(format: "%.1fs", delay))
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color(hex: "#6C5CE7"))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "#6C5CE7").opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            // コンテンツ
            Text(post.content)
                .font(.system(size: 14))
                .foregroundColor(Color(.label))
                .lineLimit(2)
                .lineSpacing(2)

            // スタッツ
            HStack(spacing: 16) {
                Label("\(post.likes)", systemImage: "heart")
                Label("\(post.comments)", systemImage: "bubble.left")
                Label("\(post.reposts)", systemImage: "arrow.2.squarepath")
            }
            .font(.system(size: 11))
            .foregroundColor(Color(.tertiaryLabel))

            // リアクション一覧
            if !post.reactions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(post.reactions) { entry in
                        HStack(spacing: 6) {
                            Image(systemName: entry.type == .reply ? "arrowshape.turn.up.left.fill" : "quote.bubble.fill")
                                .font(.system(size: 10))
                                .foregroundColor(entry.type == .reply ? Color(hex: "#4A90D9") : Color(hex: "#2ECC71"))

                            if let acc = store.account(for: entry.reaction.accountId) {
                                Text(acc.name)
                                    .font(.system(size: 11, weight: .medium))
                            }

                            Text(entry.reaction.content)
                                .font(.system(size: 11))
                                .foregroundColor(Color(.secondaryLabel))
                                .lineLimit(1)

                            Spacer()

                            // 削除ボタン
                            Button {
                                withAnimation {
                                    store.removeReaction(postId: post.id, reactionId: entry.id)
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(.tertiaryLabel))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 2)
                        .padding(.leading, 8)
                    }
                }
                .padding(.top, 4)
                .padding(.leading, 4)
            }

            // リアクション追加ボタン
            Button {
                showingAddReaction = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.bubble")
                        .font(.system(size: 11))
                    Text("リアクション追加")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(Color(hex: "#6C5CE7"))
                .padding(.top, 2)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingAddReaction) {
            AddReactionSheet(store: store, postId: post.id)
        }
    }
}


// ============================================================
// MARK: - Add Account Sheet
// ============================================================

@available(iOS 17.0, *)
struct AddAccountSheet: View {
    @ObservedObject var store: DemoDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var showingCropper = false
    @State private var rawSelectedImage: UIImage?

    @State private var name = ""
    @State private var handle = ""
    @State private var selectedEmoji = "😀"
    @State private var selectedColorHex = "#6C5CE7"
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var uploadedImageData: Data?

    let emojiOptions = ["😀", "🌸", "💻", "🎵", "📷", "🍳", "🎮", "📚", "🎨", "⚽", "🐱", "🐶", "🌙", "☀️", "🔥", "💎", "🦊", "🐻", "🌺", "🍀", "🎭", "🏄", "🧑‍🚀", "🦋"]
    let colorOptions = ["#FF6B9D", "#4A90D9", "#F5A623", "#7B68EE", "#2ECC71", "#E74C3C", "#1ABC9C", "#E67E22", "#9B59B6", "#34495E", "#FF4757", "#6C5CE7"]

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            formContent
                .navigationTitle("アカウント追加")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    AddAccountToolbar(
                        name: name,
                        handle: handle,
                        selectedEmoji: selectedEmoji,
                        selectedColorHex: selectedColorHex,
                        uploadedImageData: uploadedImageData,
                        canSave: canSave,
                        store: store,
                        dismiss: { dismiss() }
                    )
                }
        }
    }

    @ViewBuilder
    private var formContent: some View {
        Form {
            Section(header: Text("基本情報")) {
                TextField("名前", text: $name)
                TextField("ハンドル名（省略可）", text: $handle)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section(header: Text("プロフィール画像（任意）"), footer: Text("画像を設定しない場合は、デフォルトのアイコンが使用されます。")) {
                imagePickerContent
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            handlePhotoSelection(newItem)
        }
        .fullScreenCover(isPresented: $showingCropper) {
            if let raw = rawSelectedImage {
                ImageCropper(image: raw, croppedData: $uploadedImageData)
            }
        }
    }

    @ViewBuilder
    private var imagePickerContent: some View {
        VStack(spacing: 12) {
            if let imageData = uploadedImageData, let uiImage = UIImage(data: imageData) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(hex: "#6C5CE7"), lineWidth: 2))
                        .contentShape(Circle())

                    Button {
                        uploadedImageData = nil
                        selectedPhotoItem = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.red)
                            .background(Circle().fill(.white))
                    }
                    .offset(x: 5, y: -5)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Label(uploadedImageData == nil ? "ライブラリから選択" : "別の画像を選択", systemImage: "photo.badge.plus")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: "#6C5CE7").opacity(0.08))
                    .cornerRadius(10)
            }
        }
    }

    private func handlePhotoSelection(_ newItem: PhotosPickerItem?) {
        Task {
            guard let newItem,
                  let data = try? await newItem.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else { return }
            await MainActor.run {
                self.rawSelectedImage = uiImage
                self.showingCropper = true
            }
        }
    }
}

// MARK: - Add Account Toolbar

struct AddAccountToolbar: ToolbarContent {
    let name: String
    let handle: String
    let selectedEmoji: String
    let selectedColorHex: String
    let uploadedImageData: Data?
    let canSave: Bool
    let store: DemoDataStore
    let dismiss: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("キャンセル") { dismiss() }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("追加") {
                let finalHandle = handle.isEmpty
                    ? name.lowercased().replacingOccurrences(of: " ", with: "_")
                    : handle
                let account = DemoAccount(
                    name: name.trimmingCharacters(in: .whitespaces),
                    handle: finalHandle,
                    avatarEmoji: selectedEmoji,
                    avatarColorHex: selectedColorHex,
                    avatarImageBase64: uploadedImageData?.base64EncodedString()
                )
                store.addAccount(account)
                dismiss()
            }
            .font(.system(size: 15, weight: .semibold))
            .disabled(!canSave)
        }
    }
}


// ============================================================
// MARK: - Add Post Sheet
// ============================================================

struct AddPostSheet: View {
    @ObservedObject var store: DemoDataStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedAccountId = ""
    @State private var content = ""
    @State private var timeAgo = "1分"
    @State private var likes = "100"
    @State private var comments = "15"
    @State private var reposts = "8"
    @State private var customDelay = false
    @State private var delaySeconds: Double = 2.0

    var canSave: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !selectedAccountId.isEmpty
        && content.count <= 280
    }

    var body: some View {
        NavigationStack {
            Form {
                // 投稿者
                Section {
                    Picker("投稿者", selection: $selectedAccountId) {
                        if store.accounts.filter({ !$0.isHidden }).isEmpty {
                            Text("有効なアカウントがありません").tag("")
                        } else {
                            ForEach(store.accounts.filter { !$0.isHidden }) { account in
                                Text(account.name).tag(account.id)
                            }
                        }
                    }
                } header: {
                    Text("投稿者")
                }

                // 投稿内容
                Section {
                    ZStack(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("投稿内容を入力...")
                                .foregroundColor(Color(.placeholderText))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $content)
                            .frame(minHeight: 100)
                            .scrollContentBackground(.hidden)
                    }
                    HStack {
                        Spacer()
                        Text("\(content.count)/280")
                            .font(.system(size: 12))
                            .foregroundColor(content.count > 280 ? .red : Color(.secondaryLabel))
                    }
                } header: {
                    Text("内容")
                }

                // 表示時間
                Section {
                    HStack {
                        Text("経過時間")
                        Spacer()
                        TextField("例: 2分", text: $timeAgo)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                } header: {
                    Text("表示時間")
                } footer: {
                    Text("「1分」「15分」「1時間」「3日」などの形式で入力")
                }

                // 表示遅延
                Section {
                    Toggle("個別の表示遅延を設定", isOn: $customDelay)
                        .tint(Color(hex: "#6C5CE7"))

                    if customDelay {
                        HStack {
                            Text("前の投稿からの遅延")
                            Spacer()
                            Text(String(format: "%.1f 秒", delaySeconds))
                                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                                .foregroundColor(Color(hex: "#6C5CE7"))
                        }
                        Slider(value: $delaySeconds, in: 0.5...30, step: 0.5)
                            .tint(Color(hex: "#6C5CE7"))
                    }
                } header: {
                    Text("表示タイミング")
                } footer: {
                    Text("オフの場合はグローバル設定（\(String(format: "%.1f秒", store.defaultPostInterval))）が使われます。")
                }

                // エンゲージメント
                Section {
                    HStack {
                        Image(systemName: "heart")
                            .foregroundColor(Color(hex: "#FF3B6E"))
                        Text("いいね数")
                        Spacer()
                        TextField("0", text: $likes)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Image(systemName: "bubble.left")
                            .foregroundColor(Color(hex: "#6C5CE7"))
                        Text("コメント数")
                        Spacer()
                        TextField("0", text: $comments)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Image(systemName: "arrow.2.squarepath")
                            .foregroundColor(Color(hex: "#2ECC71"))
                        Text("リポスト数")
                        Spacer()
                        TextField("0", text: $reposts)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                } header: {
                    Text("エンゲージメント")
                }

                // プレビュー
                if canSave, let account = store.account(for: selectedAccountId) {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                DemoAvatarImage(account: account, size: 36, emojiSize: 16)
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                                VStack(alignment: .leading, spacing: 1) {
                                    HStack(spacing: 4) {
                                        Text(account.name)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color(.label))
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(Color(hex: "#6C5CE7"))
                                        Text("· \(timeAgo)")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color(.secondaryLabel))
                                    }
                                }
                            }
                            Text(content)
                                .font(.system(size: 14))
                                .foregroundColor(Color(.label))
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("プレビュー")
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("投稿追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        let post = DemoPost1(
                            accountId: selectedAccountId,
                            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                            likes: Int(likes) ?? 0,
                            comments: Int(comments) ?? 0,
                            reposts: Int(reposts) ?? 0,
                            timeAgo: timeAgo,
                            displayDelay: customDelay ? delaySeconds : nil
                        )
                        store.addPost(post)
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .disabled(!canSave)
                }
            }
            .onAppear {
                if selectedAccountId.isEmpty {
                    if let first = store.accounts.first(where: { !$0.isHidden }) {
                        selectedAccountId = first.id
                    }
                }
                likes = "\(Int.random(in: 50...500))"
                comments = "\(Int.random(in: 5...80))"
                reposts = "\(Int.random(in: 3...60))"
            }
        }
    }
}


// ============================================================
// MARK: - Add Reaction Sheet
// ============================================================

struct AddReactionSheet: View {
    @ObservedObject var store: DemoDataStore
    let postId: String
    @Environment(\.dismiss) private var dismiss

    @State private var reactionType: ReactionType = .reply
    @State private var selectedAccountId = ""
    @State private var content = ""
    @State private var likes = "0"
    @State private var comments = "0"
    @State private var reposts = "0"
    @State private var timeAgo = "1分"
    @State private var displayDelay: Double = 1.5

    var canSave: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !selectedAccountId.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // タイプ選択
                Section {
                    Picker("タイプ", selection: $reactionType) {
                        ForEach(ReactionType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("リアクションの種類")
                }

                // アカウント選択
                Section {
                    Picker("投稿者", selection: $selectedAccountId) {
                        if store.accounts.filter({ !$0.isHidden }).isEmpty {
                            Text("有効なアカウントがありません").tag("")
                        } else {
                            ForEach(store.accounts.filter { !$0.isHidden }) { account in
                                Text(account.name).tag(account.id)
                            }
                        }
                    }
                } header: {
                    Text("投稿者")
                }

                // 内容
                Section {
                    ZStack(alignment: .topLeading) {
                        if content.isEmpty {
                            Text(reactionType == .reply ? "リプライ内容..." : "引用コメント...")
                                .foregroundColor(Color(.placeholderText))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $content)
                            .frame(minHeight: 80)
                            .scrollContentBackground(.hidden)
                    }
                } header: {
                    Text("内容")
                }

                // 表示タイミング
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("親投稿からの遅延")
                            Spacer()
                            Text(String(format: "%.1f 秒", displayDelay))
                                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                                .foregroundColor(Color(hex: "#6C5CE7"))
                        }
                        Slider(value: $displayDelay, in: 0.5...30, step: 0.5)
                            .tint(Color(hex: "#6C5CE7"))
                    }
                } header: {
                    Text("表示タイミング")
                } footer: {
                    Text("親投稿が表示されてから、このリアクションが表示されるまでの遅延")
                }

                // 時間表示
                Section {
                    HStack {
                        Text("経過時間の表示")
                        Spacer()
                        TextField("例: 1分", text: $timeAgo)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                } header: {
                    Text("表示")
                }

                // エンゲージメント
                Section {
                    HStack {
                        Image(systemName: "heart")
                            .foregroundColor(Color(hex: "#FF3B6E"))
                        Text("いいね")
                        Spacer()
                        TextField("0", text: $likes)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Image(systemName: "bubble.left")
                            .foregroundColor(Color(hex: "#6C5CE7"))
                        Text("コメント")
                        Spacer()
                        TextField("0", text: $comments)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Image(systemName: "arrow.2.squarepath")
                            .foregroundColor(Color(hex: "#2ECC71"))
                        Text("リポスト")
                        Spacer()
                        TextField("0", text: $reposts)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                } header: {
                    Text("エンゲージメント")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(reactionType == .reply ? "リプライ追加" : "引用リポスト追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        let reaction = DemoReaction(
                            accountId: selectedAccountId,
                            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                            likes: Int(likes) ?? 0,
                            comments: Int(comments) ?? 0,
                            reposts: Int(reposts) ?? 0,
                            timeAgo: timeAgo,
                            displayDelay: displayDelay
                        )
                        let entry = DemoReactionEntry(type: reactionType, reaction: reaction)
                        store.addReaction(to: postId, entry: entry)
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .disabled(!canSave)
                }
            }
            .onAppear {
                if let first = store.accounts.first(where: { !$0.isHidden }) {
                    selectedAccountId = first.id
                }
                likes = "\(Int.random(in: 5...100))"
                comments = "\(Int.random(in: 0...20))"
                reposts = "\(Int.random(in: 0...10))"
            }
        }
    }
}


// ============================================================
// MARK: - Demo Timeline Tab
// ============================================================

enum DemoTimelineTab: String, CaseIterable {
    case forYou = "フォロー中"
    case following = "おすすめ"
}

// ============================================================
// MARK: - Demo Timeline Screen
// ============================================================

@available(iOS 17.0, *)
struct DemoTimelineView: View {
    @StateObject private var store = DemoDataStore.shared
    @State private var selectedTab: DemoTimelineTab = .forYou
    @State private var showingSettings = false
    @Namespace private var tabNamespace

    /// 表示中の投稿ID（タイマーで順次追加）
    @State private var visiblePostIds: Set<String> = []
    /// 表示中のリアクションID
    @State private var visibleReactionIds: Set<String> = []
    /// フィード再生タスク
    @State private var feedTask: Task<Void, Never>?

    /// 表示対象の投稿（非表示アカウント・非表示投稿を除外）★変更箇所
    private var filteredPosts: [DemoPost1] {
        let hiddenAccountIds = Set(store.accounts.filter { $0.isHidden }.map { $0.id })
        return store.posts.filter { !hiddenAccountIds.contains($0.accountId) && !$0.isHidden }
    }

    /// 現在表示中の投稿（順序を保持）
    private var displayedPosts: [DemoPost1] {
        filteredPosts.filter { visiblePostIds.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    headerView
                    tabBarView

                    if store.posts.isEmpty {
                        emptyView
                    } else if filteredPosts.isEmpty {
                        allHiddenView
                    } else if displayedPosts.isEmpty {
                        loadingView
                    } else {
                        timelineScrollView
                    }
                }
                .background(Color(.systemBackground))

                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        fabButton
                            .padding(.trailing, 16)
                            .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettings) {
                DemoSettingsView(store: store)
            }
            .onAppear { startFeed() }
            .onDisappear { stopFeed() }
            .onChange(of: store.posts) { _, _ in restartFeed() }
        }
    }

    // MARK: - Feed Control (async/await ベース)

    private func startFeed() {
        visiblePostIds = []
        visibleReactionIds = []

        feedTask = Task { @MainActor in
            // 最初の小休止
            try? await Task.sleep(nanoseconds: 500_000_000)

            for post in filteredPosts {
                guard !Task.isCancelled else { return }

                // 投稿を表示
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    visiblePostIds.insert(post.id)
                }

                // リアクションを遅延表示
                for entry in post.reactions {
                    let delayNanos = UInt64(entry.reaction.displayDelay * 1_000_000_000)
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: delayNanos)
                        guard !Task.isCancelled else { return }
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            visibleReactionIds.insert(entry.id)
                        }
                    }
                }

                // 次の投稿までの遅延
                let delay = post.displayDelay ?? store.defaultPostInterval
                let nanos = UInt64(delay * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanos)
            }
        }
    }

    private func stopFeed() {
        feedTask?.cancel()
        feedTask = nil
    }

    private func restartFeed() {
        stopFeed()
        startFeed()
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Button {
                showingSettings = true
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#6C5CE7"), Color(hex: "#a29bfe")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    Text("あ")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            Spacer()

            HStack(spacing: 6) {
                Image("アイコン")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30)
                    .cornerRadius(50)
                Text("AImate")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#6C5CE7"), Color(hex: "#a29bfe")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }

            Spacer()

            Button { restartFeed() } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.clear)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Color(.systemBackground)
                .shadow(color: Color.black.opacity(0.03), radius: 1, y: 1)
        )
    }

    // MARK: - Tab Bar

    private var tabBarView: some View {
        HStack(spacing: 0) {
            ForEach(DemoTimelineTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(tab.rawValue)
                            .font(selectedTab == tab ? .system(size: 15, weight: .semibold) : .system(size: 15))
                            .foregroundColor(selectedTab == tab ? Color(.label) : Color(.secondaryLabel))

                        ZStack {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 3)
                            if selectedTab == tab {
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "#6C5CE7"), Color(hex: "#a29bfe")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: 48, height: 3)
                                    .matchedGeometryEffect(id: "demoTabIndicator", in: tabNamespace)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 2)
        .background(Color(.systemBackground))
        .overlay(Divider(), alignment: .bottom)
    }

    // MARK: - Timeline ScrollView

    private var timelineScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(displayedPosts) { post in
                    if let account = store.account(for: post.accountId) {
                        VStack(spacing: 0) {
                            DemoPostCardView(
                                post: post,
                                account: account,
                                store: store,
                                visibleReactionIds: visibleReactionIds
                            )
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .top)
                                        .combined(with: .opacity)
                                        .combined(with: .scale(scale: 0.95, anchor: .top)),
                                    removal: .opacity
                                )
                            )

                            Divider()
                                .padding(.leading, 68)
                        }
                    }
                }
            }
            .padding(.bottom, 100)
        }
    }

    // MARK: - Loading / Empty / Hidden Views

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView().scaleEffect(1.2)
            Text("投稿を読み込み中...")
                .font(.system(size: 15))
                .foregroundColor(Color(.secondaryLabel))
            Spacer()
        }
    }

    private var allHiddenView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "eye.slash")
                .font(.system(size: 48))
                .foregroundColor(Color(.tertiaryLabel))
            Text("表示できる投稿がありません")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(.label))
            Text("すべてのアカウントまたは投稿が非表示になっています。\n設定画面で表示に切り替えてください。")
                .font(.system(size: 14))
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
            Button { showingSettings = true } label: {
                Text("設定を開く")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#6C5CE7"), Color(hex: "#a29bfe")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
            }
            Spacer()
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundColor(Color(.tertiaryLabel))
            Text("投稿がありません")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(.label))
            Text("設定画面からアカウントと投稿を\n追加してください")
                .font(.system(size: 14))
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
            Button { showingSettings = true } label: {
                Text("設定を開く")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#6C5CE7"), Color(hex: "#a29bfe")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
            }
            Spacer()
        }
    }

    // MARK: - FAB

    private var fabButton: some View {
        Button {} label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#6C5CE7"), Color(hex: "#a29bfe")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: Color(hex: "#6C5CE7").opacity(0.4), radius: 10, y: 4)
        }
    }
}


// ============================================================
// MARK: - Demo Post Card View
// ============================================================

@available(iOS 17.0, *)
struct DemoPostCardView: View {
    let post: DemoPost1
    let account: DemoAccount
    @ObservedObject var store: DemoDataStore
    var visibleReactionIds: Set<String> = []

    @State private var isLikeAnimating = false
    @State private var animLikes: Int = 0
    @State private var animComments: Int = 0
    @State private var animReposts: Int = 0
    @State private var didStartCountUp: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // メイン投稿
            HStack(alignment: .top, spacing: 10) {
                DemoAvatarImage(account: account, size: 42, emojiSize: 20)

                VStack(alignment: .leading, spacing: 4) {
                    postHeader
                    if !post.content.isEmpty {
                        Text(post.content)
                            .font(.system(size: 15))
                            .lineSpacing(4)
                            .foregroundColor(Color(.label))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    actionButtons
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            // リアクション表示
            ForEach(post.reactions.filter { visibleReactionIds.contains($0.id) }) { entry in
                if let reactionAccount = store.account(for: entry.reaction.accountId) {
                    if entry.type == .reply {
                        replyView(entry: entry, account: reactionAccount)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    } else {
                        quoteRepostView(entry: entry, account: reactionAccount)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .task(id: post.id) {
            didStartCountUp = false
            animLikes = 0
            animComments = 0
            animReposts = 0
            await animateEngagementCounts()
        }
        .onChange(of: post.likes) { _, _ in Task { await animateEngagementCounts() } }
        .onChange(of: post.comments) { _, _ in Task { await animateEngagementCounts() } }
        .onChange(of: post.reposts) { _, _ in Task { await animateEngagementCounts() } }
    }

    // MARK: - Reply View

    private func replyView(entry: DemoReactionEntry, account: DemoAccount) -> some View {
        HStack(alignment: .top, spacing: 10) {
            // 接続線 + アバター
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color(.separator).opacity(0.5))
                    .frame(width: 2, height: 16)
                DemoAvatarImage(account: account, size: 32, emojiSize: 14)
            }
            .frame(width: 42) // メインアバターと幅を揃える

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(account.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(.label))
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#6C5CE7"))
                    Text("@\(account.handle)")
                        .font(.system(size: 12))
                        .foregroundColor(Color(.secondaryLabel))
                    Text("· \(entry.reaction.timeAgo)")
                        .font(.system(size: 12))
                        .foregroundColor(Color(.secondaryLabel))
                }
                Text(entry.reaction.content)
                    .font(.system(size: 14))
                    .lineSpacing(3)
                    .foregroundColor(Color(.label))

                // ミニアクションバー
                miniActionBar(reaction: entry.reaction)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    // MARK: - Quote Repost View

    private func quoteRepostView(entry: DemoReactionEntry, account: DemoAccount) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 「🔁 ○○がリポスト」ヘッダー
            HStack(spacing: 6) {
                Image(systemName: "arrow.2.squarepath")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#2ECC71"))
                Text("\(account.name)がリポスト")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(.secondaryLabel))
            }
            .padding(.leading, 68)
            .padding(.top, 4)
            .padding(.bottom, 6)

            HStack(alignment: .top, spacing: 10) {
                DemoAvatarImage(account: account, size: 42, emojiSize: 20)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(account.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(.label))
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#6C5CE7"))
                        Text("@\(account.handle)")
                            .font(.system(size: 13))
                            .foregroundColor(Color(.secondaryLabel))
                        Text("· \(entry.reaction.timeAgo)")
                            .font(.system(size: 13))
                            .foregroundColor(Color(.secondaryLabel))
                    }

                    // 引用コメント
                    Text(entry.reaction.content)
                        .font(.system(size: 15))
                        .lineSpacing(4)
                        .foregroundColor(Color(.label))

                    // 引用元（元の投稿の要約）
                    quotedOriginalPost
                        .padding(.top, 4)

                    miniActionBar(reaction: entry.reaction)
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
    }

    /// 引用元投稿の小さいカード
    private var quotedOriginalPost: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                DemoAvatarImage(account: account, size: 18, emojiSize: 8)
                Text(account.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(.label))
                Text("@\(account.handle)")
                    .font(.system(size: 11))
                    .foregroundColor(Color(.secondaryLabel))
            }
            Text(post.content)
                .font(.system(size: 13))
                .foregroundColor(Color(.secondaryLabel))
                .lineLimit(2)
                .lineSpacing(2)
        }
        .padding(10)
        .background(Color(.tertiarySystemFill))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Mini Action Bar (for reactions)

    private func miniActionBar(reaction: DemoReaction) -> some View {
        HStack(spacing: 16) {
            miniStat(icon: "bubble.left", count: reaction.comments, color: Color(.secondaryLabel))
            miniStat(icon: "arrow.2.squarepath", count: reaction.reposts, color: Color(.secondaryLabel))
            miniStat(icon: "heart", count: reaction.likes, color: Color(.secondaryLabel))
        }
        .padding(.top, 4)
    }

    private func miniStat(icon: String, count: Int, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            if count > 0 {
                Text(formatCount(count))
                    .font(.system(size: 11))
                    .foregroundColor(color)
            }
        }
    }

    // MARK: - Post Header

    private var postHeader: some View {
        HStack(spacing: 4) {
            Text(account.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(.label))
                .lineLimit(1)
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#6C5CE7"))
            Text("@\(account.handle)")
                .font(.system(size: 13))
                .foregroundColor(Color(.secondaryLabel))
                .lineLimit(1)
            Text("·")
                .font(.system(size: 13))
                .foregroundColor(Color(.secondaryLabel))
            Text(post.timeAgo)
                .font(.system(size: 13))
                .foregroundColor(Color(.secondaryLabel))
            Spacer()
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 0) {
            demoActionButton(icon: "bubble.left", count: animComments, isActive: false, activeColor: Color(hex: "#6C5CE7"), inactiveColor: Color(.secondaryLabel)) {}
            Spacer()
            demoActionButton(icon: "arrow.2.squarepath", count: animReposts, isActive: post.isReposted, activeColor: Color(hex: "#2ECC71"), inactiveColor: Color(.secondaryLabel)) {
                store.toggleRepost(postId: post.id)
            }
            Spacer()
            demoActionButton(icon: post.isLiked ? "heart.fill" : "heart", count: animLikes, isActive: post.isLiked, activeColor: Color(hex: "#FF3B6E"), inactiveColor: Color(.secondaryLabel)) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { isLikeAnimating = true }
                store.toggleLike(postId: post.id)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { isLikeAnimating = false }
            }
            .scaleEffect(isLikeAnimating && post.isLiked ? 1.3 : 1.0)
            Spacer()
            demoActionButton(icon: post.isBookmarked ? "bookmark.fill" : "bookmark", count: nil, isActive: post.isBookmarked, activeColor: Color(hex: "#6C5CE7"), inactiveColor: Color(.secondaryLabel)) {
                store.toggleBookmark(postId: post.id)
            }
            Spacer()
        }
    }

    private func demoActionButton(icon: String, count: Int?, isActive: Bool, activeColor: Color, inactiveColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(isActive ? activeColor : inactiveColor)
                if let count = count, count > 0 {
                    Text(formatCount(count))
                        .font(.system(size: 12))
                        .foregroundColor(isActive ? activeColor : inactiveColor)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 10000 {
            return String(format: "%.1f万", Double(count) / 10000)
        } else if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000)
        }
        return "\(count)"
    }

    // MARK: - Count Up Animation

    @MainActor
    private func animateEngagementCounts() async {
        let startLikes = didStartCountUp ? animLikes : 0
        let startComments = didStartCountUp ? animComments : 0
        let startReposts = didStartCountUp ? animReposts : 0

        let targetLikes = max(0, post.likes)
        let targetComments = max(0, post.comments)
        let targetReposts = max(0, post.reposts)

        didStartCountUp = true

        let steps = 1000
        let totalNanos: UInt64 = 33_000_000_000
        let stepNanos = totalNanos / UInt64(steps)

        for i in 1...steps {
            let t = Double(i) / Double(steps)
            animLikes = startLikes + Int(Double(targetLikes - startLikes) * t)
            animComments = startComments + Int(Double(targetComments - startComments) * t)
            animReposts = startReposts + Int(Double(targetReposts - startReposts) * t)
            try? await Task.sleep(nanoseconds: stepNanos)
        }

        animLikes = targetLikes
        animComments = targetComments
        animReposts = targetReposts
    }
}


// ============================================================
// MARK: - Image Cropper
// ============================================================

struct ImageCropper: View {
    let image: UIImage
    @Binding var croppedData: Data?
    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let maskSize: CGFloat = 250

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: maskSize, height: maskSize)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in lastOffset = offset }
                    )
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in scale = lastScale * value }
                            .onEnded { _ in lastScale = scale }
                    )

                Color.black.opacity(0.5)
                    .mask(
                        ZStack {
                            Rectangle()
                            Circle()
                                .frame(width: maskSize, height: maskSize)
                                .blendMode(.destinationOut)
                        }
                    )
                    .allowsHitTesting(false)

                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: maskSize, height: maskSize)
                    .allowsHitTesting(false)
            }
            .navigationTitle("位置を調整")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") { cropAndSave() }
                        .fontWeight(.bold)
                }
            }
        }
    }

    private func cropAndSave() {
        let renderer = ImageRenderer(content:
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: maskSize, height: maskSize)
                .scaleEffect(scale)
                .offset(offset)
                .frame(width: maskSize, height: maskSize)
                .clipShape(Circle())
        )
        renderer.scale = 3.0
        if let uiImage = renderer.uiImage {
            self.croppedData = uiImage.jpegData(compressionQuality: 0.8)
            dismiss()
        }
    }
}


// ============================================================
// MARK: - Previews
// ============================================================

#Preview("Settings") {
    if #available(iOS 17.0, *) {
        DemoSettingsView(store: DemoDataStore.shared)
    }
}

#Preview("Timeline") {
    if #available(iOS 17.0, *) {
        DemoTimelineView()
    }
}

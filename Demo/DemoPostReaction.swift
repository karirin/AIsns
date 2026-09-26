//
//  DemoPostReaction.swift
//  AIsns
//
//  Created by Apple on 2026/02/04.
//
//  自分が投稿したらフォロワーからコメントが来るデモ画面
//

import SwiftUI
import PhotosUI

// ============================================================
// MARK: - Models
// ============================================================

// MARK: - Demo Follower Model (フォロワー)

struct DemoFollower: Identifiable, Codable, Hashable {
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
    
    static let samples: [DemoFollower] = [
        DemoFollower(id: "fol_1", name: "ゆきの", handle: "yukino_ai", avatarEmoji: "🌸", avatarColorHex: "#FF6B9D"),
        DemoFollower(id: "fol_2", name: "そうた", handle: "sota_dev", avatarEmoji: "💻", avatarColorHex: "#4A90D9"),
        DemoFollower(id: "fol_3", name: "あかり", handle: "akari_music", avatarEmoji: "🎵", avatarColorHex: "#F5A623"),
        DemoFollower(id: "fol_4", name: "れん", handle: "ren_photo", avatarEmoji: "📷", avatarColorHex: "#7B68EE"),
        DemoFollower(id: "fol_5", name: "みお", handle: "mio_cooking", avatarEmoji: "🍳", avatarColorHex: "#2ECC71"),
    ]
}

// MARK: - Demo Comment Template Model (コメントテンプレート)

struct DemoCommentTemplate: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var followerId: String
    var content: String
    var emoji: String = "❤️"
    /// 投稿からの遅延秒数
    var displayDelay: Double = 2.0
    var isHidden: Bool = false
    
    static let samples: [DemoCommentTemplate] = [
        DemoCommentTemplate(id: "cmt_1", followerId: "fol_1", content: "素敵な投稿ですね！✨", emoji: "❤️", displayDelay: 1.5),
        DemoCommentTemplate(id: "cmt_2", followerId: "fol_2", content: "共感します！", emoji: "👍", displayDelay: 3.0),
        DemoCommentTemplate(id: "cmt_3", followerId: "fol_3", content: "いいね！応援してます🎵", emoji: "🎉", displayDelay: 4.5),
        DemoCommentTemplate(id: "cmt_4", followerId: "fol_4", content: "写真も見たいです📷", emoji: "📷", displayDelay: 6.0),
        DemoCommentTemplate(id: "cmt_5", followerId: "fol_5", content: "また教えてください！", emoji: "😊", displayDelay: 8.0),
    ]
}

// MARK: - Demo User Profile (自分のプロフィール)

struct DemoUserProfile: Codable, Hashable {
    var name: String = "あなた"
    var handle: String = "you"
    var avatarEmoji: String = "😊"
    var avatarColorHex: String = "#6C5CE7"
    var avatarImageBase64: String?
    
    var avatarColor: Color {
        Color(hex: avatarColorHex)
    }
    
    var avatarImageData: Data? {
        guard let base64 = avatarImageBase64 else { return nil }
        return Data(base64Encoded: base64)
    }
    
    static let `default` = DemoUserProfile()
}

// MARK: - Demo User Post (ユーザーの投稿)

struct DemoUserPost: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var content: String
    var timestamp: Date = Date()
    var likes: Int = 0
    var comments: Int = 0
    var reposts: Int = 0
}

// MARK: - Received Comment (受信したコメント)

struct ReceivedComment: Identifiable, Hashable {
    var id: String = UUID().uuidString
    var followerId: String
    var content: String
    var emoji: String
    var timestamp: Date = Date()
    var isLiked: Bool = false
}


// ============================================================
// MARK: - Demo Post Reaction Data Store
// ============================================================

class DemoPostReactionStore: ObservableObject {
    static let shared = DemoPostReactionStore()
    
    @Published var followers: [DemoFollower] = []
    @Published var commentTemplates: [DemoCommentTemplate] = []
    @Published var defaultCommentInterval: Double = 2.0
    @Published var userProfile: DemoUserProfile = .default
    
    private let followersKey = "demo_pr_followers_v1"
    private let templatesKey = "demo_pr_templates_v1"
    private let intervalKey = "demo_pr_interval_v1"
    private let userProfileKey = "demo_pr_user_profile_v1"
    
    init() {
        loadData()
    }
    
    func updateCommentTemplate(
        id: String,
        followerId: String,
        content: String,
        emoji: String,
        displayDelay: Double
    ) {
        guard let index = commentTemplates.firstIndex(where: { $0.id == id }) else { return }
        commentTemplates[index].followerId = followerId
        commentTemplates[index].content = content
        commentTemplates[index].emoji = emoji
        commentTemplates[index].displayDelay = displayDelay
        save()
    }
    
    // MARK: - Load
    
    func loadData() {
        if let data = UserDefaults.standard.data(forKey: followersKey),
           let decoded = try? JSONDecoder().decode([DemoFollower].self, from: data) {
            followers = decoded
        } else {
            followers = DemoFollower.samples
        }
        
        if let data = UserDefaults.standard.data(forKey: templatesKey),
           let decoded = try? JSONDecoder().decode([DemoCommentTemplate].self, from: data) {
            commentTemplates = decoded
        } else {
            commentTemplates = DemoCommentTemplate.samples
        }
        
        let saved = UserDefaults.standard.double(forKey: intervalKey)
        defaultCommentInterval = saved > 0 ? saved : 2.0
        
        if let data = UserDefaults.standard.data(forKey: userProfileKey),
           let decoded = try? JSONDecoder().decode(DemoUserProfile.self, from: data) {
            userProfile = decoded
        } else {
            userProfile = .default
        }
    }
    
    // MARK: - Save
    
    func save() {
        if let data = try? JSONEncoder().encode(followers) {
            UserDefaults.standard.set(data, forKey: followersKey)
        }
        if let data = try? JSONEncoder().encode(commentTemplates) {
            UserDefaults.standard.set(data, forKey: templatesKey)
        }
        UserDefaults.standard.set(defaultCommentInterval, forKey: intervalKey)
        if let data = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(data, forKey: userProfileKey)
        }
    }
    
    // MARK: - Follower CRUD
    
    func addFollower(_ follower: DemoFollower) {
        followers.append(follower)
        save()
    }
    
    func removeFollower(at offsets: IndexSet) {
        let idsToRemove = offsets.map { followers[$0].id }
        commentTemplates.removeAll { idsToRemove.contains($0.followerId) }
        followers.remove(atOffsets: offsets)
        save()
    }
    
    func removeFollower(id: String) {
        followers.removeAll { $0.id == id }
        commentTemplates.removeAll { $0.followerId == id }
        save()
    }
    
    func toggleFollowerVisibility(id: String) {
        if let index = followers.firstIndex(where: { $0.id == id }) {
            followers[index].isHidden.toggle()
            save()
        }
    }
    
    // MARK: - Comment Template CRUD
    
    func addCommentTemplate(_ template: DemoCommentTemplate) {
        commentTemplates.append(template)
        save()
    }
    
    func removeCommentTemplate(at offsets: IndexSet) {
        commentTemplates.remove(atOffsets: offsets)
        save()
    }
    
    func removeCommentTemplate(id: String) {
        commentTemplates.removeAll { $0.id == id }
        save()
    }
    
    func moveCommentTemplate(from source: IndexSet, to destination: Int) {
        commentTemplates.move(fromOffsets: source, toOffset: destination)
        save()
    }
    
    func toggleCommentTemplateVisibility(id: String) {
        if let index = commentTemplates.firstIndex(where: { $0.id == id }) {
            commentTemplates[index].isHidden.toggle()
            save()
        }
    }
    
    // MARK: - Reset
    
    func resetToDefaults() {
        followers = DemoFollower.samples
        commentTemplates = DemoCommentTemplate.samples
        defaultCommentInterval = 2.0
        userProfile = .default
        save()
    }
    
    // MARK: - User Profile
    
    func updateUserProfile(_ profile: DemoUserProfile) {
        userProfile = profile
        save()
    }
    
    // MARK: - Helper
    
    func follower(for id: String) -> DemoFollower? {
        followers.first { $0.id == id }
    }
    
    /// 有効なコメントテンプレート（非表示のフォロワー・テンプレートを除外）
    var activeCommentTemplates: [DemoCommentTemplate] {
        let hiddenFollowerIds = Set(followers.filter { $0.isHidden }.map { $0.id })
        return commentTemplates.filter { !$0.isHidden && !hiddenFollowerIds.contains($0.followerId) }
    }
}


// ============================================================
// MARK: - Shared UI Components
// ============================================================

// MARK: - Follower Avatar Image View

struct DemoFollowerAvatar: View {
    let follower: DemoFollower
    var size: CGFloat = 42
    var emojiSize: CGFloat = 20
    
    var body: some View {
        ZStack {
            if let imageData = follower.avatarImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [follower.avatarColor, follower.avatarColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text(follower.avatarEmoji)
                    .font(.system(size: emojiSize))
            }
        }
        .frame(width: size, height: size)
        .clipped()
        .clipShape(Circle())
    }
}

// MARK: - User Avatar Image View (自分のアバター)

struct DemoUserAvatar: View {
    let profile: DemoUserProfile
    var size: CGFloat = 42
    var emojiSize: CGFloat = 20
    
    var body: some View {
        ZStack {
            if let imageData = profile.avatarImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [profile.avatarColor, profile.avatarColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text(profile.avatarEmoji)
                    .font(.system(size: emojiSize))
            }
        }
        .frame(width: size, height: size)
        .clipped()
        .clipShape(Circle())
    }
}


// ============================================================
// MARK: - Demo Post Reaction Settings View
// ============================================================

@available(iOS 17.0, *)
struct DemoPostReactionSettingsView: View {
    @ObservedObject var store: DemoPostReactionStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: SettingsTab = .profile
    @State private var showingAddFollower = false
    @State private var showingAddComment = false
    @State private var showResetAlert = false
    @State private var editingTemplate: DemoCommentTemplate?
    
    enum SettingsTab: String, CaseIterable {
        case profile = "プロフィール"
        case followers = "フォロワー"
        case comments = "コメント"
        case timing = "タイミング"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                settingsTabBar
                
                switch selectedTab {
                case .profile:
                    profileSettingsView
                case .followers:
                    followerListView
                case .comments:
                    commentListView
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
            .sheet(isPresented: $showingAddFollower) {
                AddFollowerSheet(store: store)
            }
            .sheet(isPresented: $showingAddComment) {
                AddCommentTemplateSheet(store: store)
            }
            .sheet(item: $editingTemplate) { template in
                EditCommentTemplateSheet(store: store, template: template)
            }
        }
    }
    
    // MARK: - Tab Bar
    
    private var settingsTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
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
                                
                                if tab == .followers {
                                    Text("\(store.followers.count)")
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
                                } else if tab == .comments {
                                    Text("\(store.commentTemplates.count)")
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
                        .frame(minWidth: 80)
                        .padding(.horizontal, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.top, 8)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Profile Settings
    
    private var profileSettingsView: some View {
        UserProfileEditView1(store: store)
    }
    
    // MARK: - Follower List
    
    private var followerListView: some View {
        List {
            Section {
                ForEach(store.followers) { follower in
                    HStack(spacing: 12) {
                        FollowerRowView(follower: follower)
                        Spacer()
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                store.toggleFollowerVisibility(id: follower.id)
                            }
                        } label: {
                            Image(systemName: follower.isHidden ? "eye.slash.fill" : "eye.fill")
                                .font(.system(size: 16))
                                .foregroundColor(follower.isHidden ? Color(.tertiaryLabel) : Color(hex: "#6C5CE7"))
                                .frame(width: 36, height: 36)
                                .background(
                                    follower.isHidden
                                    ? Color(.tertiarySystemFill)
                                    : Color(hex: "#6C5CE7").opacity(0.1)
                                )
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .opacity(follower.isHidden ? 0.5 : 1.0)
                }
                .onDelete { offsets in
                    store.removeFollower(at: offsets)
                }
            } header: {
                Text("登録済みフォロワー")
            } footer: {
                Text("👁 アイコンで表示/非表示を切り替えられます。非表示のフォロワーのコメントは表示されません。")
            }
            
            Section {
                Button {
                    showingAddFollower = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "#6C5CE7"))
                        Text("フォロワーを追加")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(hex: "#6C5CE7"))
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Comment List
    
    private var commentListView: some View {
        List {
            Section {
                ForEach(store.commentTemplates) { template in
                    CommentTemplateRowView(template: template, store: store)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingTemplate = template
                        }
                }
                .onDelete { offsets in
                    store.removeCommentTemplate(at: offsets)
                }
                .onMove { source, destination in
                    store.moveCommentTemplate(from: source, to: destination)
                }
            } header: {
                HStack {
                    Text("コメントテンプレート")
                    Spacer()
                    EditButton()
                        .font(.system(size: 13))
                }
            } footer: {
                Text("投稿後、設定した遅延時間でコメントが順番に表示されます。ドラッグで順序を変更できます。")
            }
            
            Section {
                Button {
                    showingAddComment = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "#6C5CE7"))
                        Text("コメントを追加")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(hex: "#6C5CE7"))
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
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
                        Text(String(format: "%.1f 秒", store.defaultCommentInterval))
                            .font(.system(size: 15, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color(hex: "#6C5CE7"))
                    }
                    Slider(value: $store.defaultCommentInterval, in: 0.5...10, step: 0.5)
                        .tint(Color(hex: "#6C5CE7"))
                        .onChange(of: store.defaultCommentInterval) { _, _ in
                            store.save()
                        }
                }
            } header: {
                Text("グローバル設定")
            } footer: {
                Text("各コメントに個別の遅延が設定されていない場合、この間隔でコメントが順番に表示されます。")
            }
            
            Section {
                ForEach(Array(store.commentTemplates.enumerated()), id: \.element.id) { index, template in
                    CommentTimingRowView(template: template, index: index, store: store)
                }
            } header: {
                Text("コメントごとの遅延")
            } footer: {
                Text("投稿してからコメントが表示されるまでの遅延時間を個別に設定できます。")
            }
        }
        .listStyle(.insetGrouped)
    }
}

@available(iOS 17.0, *)
struct EditCommentTemplateSheet: View {
    @ObservedObject var store: DemoPostReactionStore
    let template: DemoCommentTemplate
    @Environment(\.dismiss) private var dismiss

    @State private var selectedFollowerId: String
    @State private var content: String
    @State private var selectedEmoji: String
    @State private var displayDelay: Double

    let emojiOptions = ["❤️", "👍", "🎉", "😊", "✨", "🔥", "💪", "👏", "🙌", "💕", "😍", "🥰", "💯", "⭐", "🌟", "💖", "😆", "🤩", "👀", "💬"]

    init(store: DemoPostReactionStore, template: DemoCommentTemplate) {
        self.store = store
        self.template = template
        _selectedFollowerId = State(initialValue: template.followerId)
        _content = State(initialValue: template.content)
        _selectedEmoji = State(initialValue: template.emoji)
        _displayDelay = State(initialValue: template.displayDelay)
    }

    var canSave: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !selectedFollowerId.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("投稿者", selection: $selectedFollowerId) {
                        ForEach(store.followers.filter { !$0.isHidden }) { follower in
                            Text(follower.name).tag(follower.id)
                        }
                    }
                } header: {
                    Text("コメントするフォロワー")
                }

                Section {
                    ZStack(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("コメント内容を入力...")
                                .foregroundColor(Color(.placeholderText))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $content)
                            .frame(minHeight: 80)
                            .scrollContentBackground(.hidden)
                    }
                } header: {
                    Text("コメント内容")
                }

                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 10), spacing: 12) {
                        ForEach(emojiOptions, id: \.self) { emoji in
                            Button {
                                selectedEmoji = emoji
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 22))
                                    .frame(width: 32, height: 32)
                                    .background(
                                        selectedEmoji == emoji
                                        ? Color(hex: "#6C5CE7").opacity(0.2)
                                        : Color.clear
                                    )
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("リアクション絵文字")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("投稿からの遅延")
                            Spacer()
                            Text(String(format: "%.1f 秒", displayDelay))
                                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                                .foregroundColor(Color(hex: "#6C5CE7"))
                        }
                        Slider(value: $displayDelay, in: 0.5...60, step: 0.5)
                            .tint(Color(hex: "#6C5CE7"))
                    }
                } header: {
                    Text("表示タイミング")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("コメント編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        store.updateCommentTemplate(
                            id: template.id,
                            followerId: selectedFollowerId,
                            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                            emoji: selectedEmoji,
                            displayDelay: displayDelay
                        )
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}


// MARK: - Follower Row View

struct FollowerRowView: View {
    let follower: DemoFollower
    
    var body: some View {
        HStack(spacing: 12) {
            DemoFollowerAvatar(follower: follower, size: 40, emojiSize: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(follower.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(.label))
                Text("@\(follower.handle)")
                    .font(.system(size: 13))
                    .foregroundColor(Color(.secondaryLabel))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Comment Template Row View

struct CommentTemplateRowView: View {
    let template: DemoCommentTemplate
    @ObservedObject var store: DemoPostReactionStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                if let follower = store.follower(for: template.followerId) {
                    DemoFollowerAvatar(follower: follower, size: 28, emojiSize: 12)
                    Text(follower.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(.label))
                }
                
                Spacer()
                
                // 遅延バッジ
                Text(String(format: "%.1fs", template.displayDelay))
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(hex: "#6C5CE7"))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(hex: "#6C5CE7").opacity(0.1))
                    .clipShape(Capsule())
                
                // 表示/非表示トグル
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        store.toggleCommentTemplateVisibility(id: template.id)
                    }
                } label: {
                    Image(systemName: template.isHidden ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 14))
                        .foregroundColor(template.isHidden ? Color(.tertiaryLabel) : Color(hex: "#6C5CE7"))
                }
                .buttonStyle(.plain)
            }
            
            HStack(spacing: 6) {
                Text(template.content)
                    .font(.system(size: 14))
                    .foregroundColor(Color(.label))
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
        .opacity(template.isHidden ? 0.5 : 1.0)
    }
}

// MARK: - Comment Timing Row View

@available(iOS 17.0, *)
struct CommentTimingRowView: View {
    let template: DemoCommentTemplate
    let index: Int
    @ObservedObject var store: DemoPostReactionStore
    
    @State private var delay: Double = 2.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("\(index + 1)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(width: 22, height: 22)
                    .background(Color(hex: "#6C5CE7"))
                    .clipShape(Circle())
                
                if let follower = store.follower(for: template.followerId) {
                    Text(follower.name)
                        .font(.system(size: 13, weight: .semibold))
                }
                
                Text(template.content)
                    .font(.system(size: 12))
                    .foregroundColor(Color(.secondaryLabel))
                    .lineLimit(1)
            }
            
            HStack {
                Text("投稿からの遅延")
                    .font(.system(size: 13))
                Spacer()
                Stepper(value: $delay, in: 0.5...60, step: 0.5) {
                    Text(String(format: "%.1f秒", delay))
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color(hex: "#6C5CE7"))
                }
                .onChange(of: delay) { _, newVal in
                    if let ti = store.commentTemplates.firstIndex(where: { $0.id == template.id }) {
                        store.commentTemplates[ti].displayDelay = newVal
                        store.save()
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            delay = template.displayDelay
        }
    }
}


// ============================================================
// MARK: - User Profile Edit View
// ============================================================

@available(iOS 17.0, *)
struct UserProfileEditView1: View {
    @ObservedObject var store: DemoPostReactionStore
    @State private var showingCropper = false
    @State private var rawSelectedImage: UIImage?
    
    @State private var name: String = ""
    @State private var handle: String = ""
    @State private var selectedEmoji: String = "😊"
    @State private var selectedColorHex: String = "#6C5CE7"
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var uploadedImageData: Data?
    
    private struct CropTarget: Identifiable {
        let id = UUID()
        let image: UIImage
    }
    
    @State private var cropTarget: CropTarget?
    
    let emojiOptions = ["😊", "😀", "🌸", "💻", "🎵", "📷", "🍳", "🎮", "📚", "🎨", "⚽", "🐱", "🐶", "🌙", "☀️", "🔥", "💎", "🦊", "🐻", "🌺", "🍀", "🎭", "🏄", "🧑‍🚀"]
    let colorOptions = ["#6C5CE7", "#FF6B9D", "#4A90D9", "#F5A623", "#7B68EE", "#2ECC71", "#E74C3C", "#1ABC9C", "#E67E22", "#9B59B6", "#34495E", "#FF4757"]
    
    var body: some View {
        Form {
            // プレビュー
            Section {
                HStack(spacing: 16) {
                    Spacer()
                    VStack(spacing: 12) {
                        // アバタープレビュー
                        ZStack {
                            if let imageData = uploadedImageData, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: selectedColorHex), Color(hex: selectedColorHex).opacity(0.6)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                Text(selectedEmoji)
                                    .font(.system(size: 36))
                            }
                        }
                        
                        VStack(spacing: 2) {
                            HStack(spacing: 4) {
                                Text(name.isEmpty ? "あなた" : name)
                                    .font(.system(size: 16, weight: .semibold))
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "#6C5CE7"))
                            }
                            Text("@\(handle.isEmpty ? "you" : handle)")
                                .font(.system(size: 14))
                                .foregroundColor(Color(.secondaryLabel))
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 12)
            } header: {
                Text("プレビュー")
            }
            
            // 基本情報
            Section {
                TextField("名前", text: $name)
                    .onChange(of: name) { _, newVal in
                        saveProfile()
                    }
                TextField("ハンドル名", text: $handle)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: handle) { _, newVal in
                        saveProfile()
                    }
            } header: {
                Text("基本情報")
            }
            
            // プロフィール画像
            Section {
                imagePickerContent
            } header: {
                Text("プロフィール画像")
            } footer: {
                Text("画像を設定しない場合は、絵文字アイコンが使用されます。")
            }
            
            // 絵文字アイコン（画像がない場合のみ）
            if uploadedImageData == nil {
                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(emojiOptions, id: \.self) { emoji in
                            Button {
                                selectedEmoji = emoji
                                saveProfile()
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 24))
                                    .frame(width: 36, height: 36)
                                    .background(
                                        selectedEmoji == emoji
                                        ? Color(hex: "#6C5CE7").opacity(0.2)
                                        : Color.clear
                                    )
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("絵文字アイコン")
                }
                
                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(colorOptions, id: \.self) { colorHex in
                            Button {
                                selectedColorHex = colorHex
                                saveProfile()
                            } label: {
                                Circle()
                                    .fill(Color(hex: colorHex))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColorHex == colorHex ? 3 : 0)
                                    )
                                    .shadow(color: selectedColorHex == colorHex ? Color(hex: colorHex).opacity(0.5) : .clear, radius: 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("アイコンカラー")
                }
            }
        }
        .onAppear {
            loadProfile()
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            handlePhotoSelection(newItem)
        }
        .fullScreenCover(item: $cropTarget) { target in
            DemoImageCropper(image: target.image, croppedData: $uploadedImageData)
        }
        .onChange(of: uploadedImageData) { _, _ in
            saveProfile()
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
                    
                    Button {
                        uploadedImageData = nil
                        selectedPhotoItem = nil
                        saveProfile()
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
    
    private func loadProfile() {
        name = store.userProfile.name
        handle = store.userProfile.handle
        selectedEmoji = store.userProfile.avatarEmoji
        selectedColorHex = store.userProfile.avatarColorHex
        uploadedImageData = store.userProfile.avatarImageData
    }
    
    private func saveProfile() {
        let profile = DemoUserProfile(
            name: name.isEmpty ? "あなた" : name,
            handle: handle.isEmpty ? "you" : handle,
            avatarEmoji: selectedEmoji,
            avatarColorHex: selectedColorHex,
            avatarImageBase64: uploadedImageData?.base64EncodedString()
        )
        store.updateUserProfile(profile)
    }
    
    private func handlePhotoSelection(_ newItem: PhotosPickerItem?) {
        Task {
            guard let newItem,
                  let data = try? await newItem.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else { return }
            await MainActor.run {
                self.cropTarget = CropTarget(image: uiImage)
            }
        }
    }
}


// ============================================================
// MARK: - Add Follower Sheet
// ============================================================

@available(iOS 17.0, *)
struct AddFollowerSheet: View {
    @ObservedObject var store: DemoPostReactionStore
    @Environment(\.dismiss) private var dismiss
    @State private var showingCropper = false
    @State private var rawSelectedImage: UIImage?
    
    @State private var name = ""
    @State private var handle = ""
    @State private var selectedEmoji = "😀"
    @State private var selectedColorHex = "#6C5CE7"
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var uploadedImageData: Data?
    
    private struct CropTarget: Identifiable {
        let id = UUID()
        let image: UIImage
    }

    @State private var cropTarget: CropTarget?
    
    let emojiOptions = ["😀", "🌸", "💻", "🎵", "📷", "🍳", "🎮", "📚", "🎨", "⚽", "🐱", "🐶", "🌙", "☀️", "🔥", "💎", "🦊", "🐻", "🌺", "🍀", "🎭", "🏄", "🧑‍🚀", "🦋"]
    let colorOptions = ["#FF6B9D", "#4A90D9", "#F5A623", "#7B68EE", "#2ECC71", "#E74C3C", "#1ABC9C", "#E67E22", "#9B59B6", "#34495E", "#FF4757", "#6C5CE7"]
    
    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("基本情報")) {
                    TextField("名前", text: $name)
                    TextField("ハンドル名（省略可）", text: $handle)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section(header: Text("プロフィール画像（任意）"), footer: Text("画像を設定しない場合は、絵文字アイコンが使用されます。")) {
                    imagePickerContent
                }
                
                if uploadedImageData == nil {
                    Section(header: Text("絵文字アイコン")) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                            ForEach(emojiOptions, id: \.self) { emoji in
                                Button {
                                    selectedEmoji = emoji
                                } label: {
                                    Text(emoji)
                                        .font(.system(size: 24))
                                        .frame(width: 36, height: 36)
                                        .background(
                                            selectedEmoji == emoji
                                            ? Color(hex: "#6C5CE7").opacity(0.2)
                                            : Color.clear
                                        )
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    Section(header: Text("アイコンカラー")) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(colorOptions, id: \.self) { colorHex in
                                Button {
                                    selectedColorHex = colorHex
                                } label: {
                                    Circle()
                                        .fill(Color(hex: colorHex))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: selectedColorHex == colorHex ? 3 : 0)
                                        )
                                        .shadow(color: selectedColorHex == colorHex ? Color(hex: colorHex).opacity(0.5) : .clear, radius: 4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .navigationTitle("フォロワー追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        let finalHandle = handle.isEmpty
                        ? name.lowercased().replacingOccurrences(of: " ", with: "_")
                        : handle
                        let follower = DemoFollower(
                            name: name.trimmingCharacters(in: .whitespaces),
                            handle: finalHandle,
                            avatarEmoji: selectedEmoji,
                            avatarColorHex: selectedColorHex,
                            avatarImageBase64: uploadedImageData?.base64EncodedString()
                        )
                        store.addFollower(follower)
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .disabled(!canSave)
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                handlePhotoSelection(newItem)
            }
            .fullScreenCover(item: $cropTarget) { target in
                DemoImageCropper(image: target.image, croppedData: $uploadedImageData)
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
                self.cropTarget = CropTarget(image: uiImage)
            }
        }
    }
}


// ============================================================
// MARK: - Add Comment Template Sheet
// ============================================================

@available(iOS 17.0, *)
struct AddCommentTemplateSheet: View {
    @ObservedObject var store: DemoPostReactionStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFollowerId = ""
    @State private var content = ""
    @State private var selectedEmoji = "❤️"
    @State private var displayDelay: Double = 2.0
    
    let emojiOptions = ["❤️", "👍", "🎉", "😊", "✨", "🔥", "💪", "👏", "🙌", "💕", "😍", "🥰", "💯", "⭐", "🌟", "💖", "😆", "🤩", "👀", "💬"]
    
    var canSave: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !selectedFollowerId.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("投稿者", selection: $selectedFollowerId) {
                        if store.followers.filter({ !$0.isHidden }).isEmpty {
                            Text("有効なフォロワーがありません").tag("")
                        } else {
                            ForEach(store.followers.filter { !$0.isHidden }) { follower in
                                Text(follower.name).tag(follower.id)
                            }
                        }
                    }
                } header: {
                    Text("コメントするフォロワー")
                }
                
                Section {
                    ZStack(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("コメント内容を入力...")
                                .foregroundColor(Color(.placeholderText))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $content)
                            .frame(minHeight: 80)
                            .scrollContentBackground(.hidden)
                    }
                } header: {
                    Text("コメント内容")
                }
                
                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 10), spacing: 12) {
                        ForEach(emojiOptions, id: \.self) { emoji in
                            Button {
                                selectedEmoji = emoji
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 22))
                                    .frame(width: 32, height: 32)
                                    .background(
                                        selectedEmoji == emoji
                                        ? Color(hex: "#6C5CE7").opacity(0.2)
                                        : Color.clear
                                    )
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("リアクション絵文字")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("投稿からの遅延")
                            Spacer()
                            Text(String(format: "%.1f 秒", displayDelay))
                                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                                .foregroundColor(Color(hex: "#6C5CE7"))
                        }
                        Slider(value: $displayDelay, in: 0.5...60, step: 0.5)
                            .tint(Color(hex: "#6C5CE7"))
                    }
                } header: {
                    Text("表示タイミング")
                } footer: {
                    Text("投稿してからこのコメントが表示されるまでの遅延時間")
                }
                
                // プレビュー
                if canSave, let follower = store.follower(for: selectedFollowerId) {
                    Section {
                        HStack(spacing: 10) {
                            DemoFollowerAvatar(follower: follower, size: 36, emojiSize: 16)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(follower.name)
                                    .font(.system(size: 14, weight: .semibold))
                                HStack(spacing: 4) {
                                    Text(content)
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(.label))
                                        .lineLimit(2)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("プレビュー")
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("コメント追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        let template = DemoCommentTemplate(
                            followerId: selectedFollowerId,
                            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                            emoji: selectedEmoji,
                            displayDelay: displayDelay
                        )
                        store.addCommentTemplate(template)
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .disabled(!canSave)
                }
            }
            .onAppear {
                if let first = store.followers.first(where: { !$0.isHidden }) {
                    selectedFollowerId = first.id
                }
            }
        }
    }
}


// ============================================================
// MARK: - Demo Post Reaction Main View
// ============================================================

@available(iOS 17.0, *)
struct DemoPostReactionView: View {
    @StateObject private var store = DemoPostReactionStore.shared
    @State private var showingSettings = false
    @State private var showingPostComposer = false
    
    // 投稿状態
    @State private var currentPost: DemoUserPost?
    @State private var receivedComments: [ReceivedComment] = []
    @State private var commentTask: Task<Void, Never>?
    
    // アニメーション用
    @State private var isPosting = false
    @State private var postAnimationComplete = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    headerView
                    
                    if currentPost == nil {
                        emptyStateView
                    } else {
                        postDetailView
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
                DemoPostReactionSettingsView(store: store)
            }
            .sheet(isPresented: $showingPostComposer) {
                DemoPostComposerSheet(onPost: { content in
                    createPost(content: content)
                }, store: store)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Button {
                showingSettings = true
            } label: {
                DemoUserAvatar(profile: store.userProfile, size: 32, emojiSize: 14)
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
            
            // リセットボタン
            Button {
                resetDemo()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(currentPost != nil ? Color(hex: "#6C5CE7") : Color.clear)
                    .frame(width: 32, height: 32)
            }
            .opacity(0)
            .disabled(currentPost == nil)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Color(.systemBackground)
                .shadow(color: Color.black.opacity(0.03), radius: 1, y: 1)
        )
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 56))
                .foregroundColor(Color(.tertiaryLabel))
            
            Text("投稿してみましょう！")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(.label))
            
            Text("投稿するとフォロワーから\nコメントが届きます")
                .font(.system(size: 15))
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
            
            Button {
                showingPostComposer = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                    Text("投稿する")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#6C5CE7"), Color(hex: "#a29bfe")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color(hex: "#6C5CE7").opacity(0.3), radius: 8, y: 4)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Post Detail View
    
    private var postDetailView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 自分の投稿
                if let post = currentPost {
                    myPostCard(post: post)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.9).combined(with: .opacity),
                            removal: .opacity
                        ))
                    
                    Divider()
                    
                    // コメントセクション
                    commentsSection
                }
            }
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - My Post Card
    
    private func myPostCard(post: DemoUserPost) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                // 自分のアバター
                DemoUserAvatar(profile: store.userProfile, size: 42, emojiSize: 18)
                
                VStack(alignment: .leading, spacing: 4) {
                    // ヘッダー
                    HStack(spacing: 4) {
                        Text(store.userProfile.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(.label))
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#6C5CE7"))
                        Text("@\(store.userProfile.handle)")
                            .font(.system(size: 13))
                            .foregroundColor(Color(.secondaryLabel))
                        Text("· たった今")
                            .font(.system(size: 13))
                            .foregroundColor(Color(.secondaryLabel))
                        Spacer()
                    }
                    
                    // 投稿内容
                    Text(post.content)
                        .font(.system(size: 15))
                        .lineSpacing(4)
                        .foregroundColor(Color(.label))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // アクションバー
                    HStack(spacing: 0) {
                        postActionButton(icon: "bubble.left", count: receivedComments.count)
                        Spacer()
                        postActionButton(icon: "arrow.2.squarepath", count: 0)
                        Spacer()
                        postActionButton(icon: "heart", count: receivedComments.filter { $0.isLiked }.count)
                        Spacer()
                        postActionButton(icon: "bookmark", count: nil)
                        Spacer()
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
    
    private func postActionButton(icon: String, count: Int?) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(Color(.secondaryLabel))
            if let count = count, count > 0 {
                Text("\(count)")
                    .font(.system(size: 12))
                    .foregroundColor(Color(.secondaryLabel))
            }
        }
    }
    
    // MARK: - Comments Section
    
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // セクションヘッダー
            HStack {
                Text("コメント")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(.label))
                
                if !receivedComments.isEmpty {
                    Text("\(receivedComments.count)")
                        .font(.system(size: 14))
                        .foregroundColor(Color(.secondaryLabel))
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            if receivedComments.isEmpty {
                // ローディング表示
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // コメント一覧
                LazyVStack(spacing: 0) {
                    ForEach(receivedComments) { comment in
                        if let follower = store.follower(for: comment.followerId) {
                            commentRow(comment: comment, follower: follower)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .opacity
                                ))
                            
                            Divider()
                                .padding(.leading, 68)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Comment Row
    
    private func commentRow(comment: ReceivedComment, follower: DemoFollower) -> some View {
        HStack(alignment: .top, spacing: 10) {
            DemoFollowerAvatar(follower: follower, size: 36, emojiSize: 16)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(follower.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(.label))
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#6C5CE7"))
                    Text("@\(follower.handle)")
                        .font(.system(size: 12))
                        .foregroundColor(Color(.secondaryLabel))
                    Text("· たった今")
                        .font(.system(size: 12))
                        .foregroundColor(Color(.secondaryLabel))
                }
                
                HStack(spacing: 6) {
                    Text(comment.content)
                        .font(.system(size: 14))
                        .foregroundColor(Color(.label))
                        .lineSpacing(2)
                }
                
                // コメントアクション
                HStack(spacing: 20) {
                    Button {} label: {
                        Image(systemName: "heart")
                            .font(.system(size: 12))
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                    
                    Button {} label: {
                        Text("返信")
                            .font(.system(size: 12))
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
                .padding(.top, 4)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    // MARK: - FAB
    
    private var fabButton: some View {
        Button {
            showingPostComposer = true
        } label: {
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
    
    // MARK: - Actions
    
    private func createPost(content: String) {
        // 既存のタスクをキャンセル
        commentTask?.cancel()
        receivedComments = []
        
        // 投稿を作成
        let post = DemoUserPost(content: content)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentPost = post
        }
        
        // コメントを順番に表示
        startCommentStream()
    }
    
    private func startCommentStream() {
        let templates = store.activeCommentTemplates.sorted { $0.displayDelay < $1.displayDelay }
        
        commentTask = Task { @MainActor in
            for template in templates {
                guard !Task.isCancelled else { return }
                
                let delayNanos = UInt64(template.displayDelay * 1_000_000_000)
                try? await Task.sleep(nanoseconds: delayNanos)
                
                guard !Task.isCancelled else { return }
                
                let comment = ReceivedComment(
                    followerId: template.followerId,
                    content: template.content,
                    emoji: template.emoji
                )
                
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    receivedComments.append(comment)
                }
                
                // ハプティックフィードバック
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        }
    }
    
    private func resetDemo() {
        commentTask?.cancel()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentPost = nil
            receivedComments = []
        }
    }
}


// ============================================================
// MARK: - Demo Post Composer Sheet
// ============================================================

struct DemoPostComposerSheet: View {
    let onPost: (String) -> Void
    @ObservedObject var store: DemoPostReactionStore
    @Environment(\.dismiss) private var dismiss
    @State private var postText = ""
    @FocusState private var isFocused: Bool
    
    var canPost: Bool {
        !postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && postText.count <= 280
    }
    
    private var characterCountColor: Color {
        if postText.count > 280 { return .red }
        if postText.count > 260 { return .orange }
        return Color(hex: "#6C5CE7")
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 10) {
                            // 自分のアバター
                            DemoUserAvatar(profile: store.userProfile, size: 42, emojiSize: 18)
                            
                            ZStack(alignment: .topLeading) {
                                if postText.isEmpty {
                                    Text("いまどうしてる？")
                                        .font(.system(size: 17))
                                        .foregroundColor(Color(.placeholderText))
                                        .padding(.top, 8)
                                        .padding(.leading, 8)
                                }
                                
                                TextEditor(text: $postText)
                                    .focused($isFocused)
                                    .font(.system(size: 17))
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 120)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }
                }
                
                // ツールバー
                HStack {
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
                    
                    if postText.count > 260 {
                        Text("\(280 - postText.count)")
                            .font(.system(size: 13))
                            .foregroundColor(characterCountColor)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
                .overlay(Divider(), alignment: .top)
            }
            .navigationTitle("新規投稿")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Color(.label))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        onPost(postText.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    } label: {
                        Text("投稿")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(
                                canPost
                                ? LinearGradient(colors: [Color(hex: "#6C5CE7"), Color(hex: "#a29bfe")], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [Color(.systemGray4)], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(Capsule())
                    }
                    .disabled(!canPost)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isFocused = true
                }
            }
        }
    }
}


// ============================================================
// MARK: - Image Cropper for DemoPostReaction
// ============================================================

struct DemoImageCropper: View {
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
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") { cropAndSave() }
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
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

#Preview("Post Reaction Demo") {
    if #available(iOS 17.0, *) {
        DemoPostReactionView()
    }
}

#Preview("Settings") {
    if #available(iOS 17.0, *) {
        DemoPostReactionSettingsView(store: DemoPostReactionStore.shared)
    }
}

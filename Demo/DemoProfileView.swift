//
//  DemoProfileView.swift
//  AIsns
//
//  Created by Apple on 2026/02/08.
//

import SwiftUI
import PhotosUI

// ============================================================
// MARK: - Models
// ============================================================

// MARK: - Demo Profile Data Model

struct DemoProfileData: Codable, Hashable {
    var displayName: String = "あなた"
    var username: String = "you"
    var bio: String = "AIと暮らす日常を発信中 ✨\nテクノロジー × クリエイティブ"
    var followingCount: Int = 128
    var followersCount: Int = 1024
    var postsCount: Int = 42
    var avatarEmoji: String = "😊"
    var avatarColorHex: String = "#6C5CE7"
    var avatarImageBase64: String?
    var headerColorHex1: String = "#6C5CE7"
    var headerColorHex2: String = "#a29bfe"
    var headerColorHex3: String = "#fd79a8"
    var isVerified: Bool = true
    var verifiedColorHex: String = "#6C5CE7"
    
    // カウントアップ設定
    var isCountUpEnabled: Bool = false
    var countMode: CountMode = .up
    var countInterval: Double = 0.5
    var countMinDelta: Int = 1
    var countMaxDelta: Int = 5
    
    enum CountMode: String, Codable, CaseIterable, Hashable {
        case up = "カウントアップ"
        case down = "カウントダウン"
    }
    
    var avatarColor: Color { Color(hex: avatarColorHex) }
    var headerColor1: Color { Color(hex: headerColorHex1) }
    var headerColor2: Color { Color(hex: headerColorHex2) }
    var headerColor3: Color { Color(hex: headerColorHex3) }
    var verifiedColor: Color { Color(hex: verifiedColorHex) }
    
    var avatarImageData: Data? {
        guard let base64 = avatarImageBase64 else { return nil }
        return Data(base64Encoded: base64)
    }
    
    static let `default` = DemoProfileData()
}

// MARK: - Demo Post Grid Item

struct DemoGridPost: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var colorHex1: String
    var colorHex2: String
    var iconName: String = "photo"
    var imageBase64: String?
    var isHidden: Bool = false
    
    var color1: Color { Color(hex: colorHex1) }
    var color2: Color { Color(hex: colorHex2) }
    
    var imageData: Data? {
        guard let base64 = imageBase64 else { return nil }
        return Data(base64Encoded: base64)
    }
    
    static let samples: [DemoGridPost] = {
        let hues: [Double] = [0.0, 0.1, 0.2, 0.3, 0.45, 0.55, 0.65, 0.75, 0.85]
        let icons = ["photo", "heart.fill", "star.fill", "camera.fill", "leaf.fill", "music.note", "paintbrush.fill", "sparkles", "globe"]
        return hues.enumerated().map { i, hue in
            DemoGridPost(
                id: "grid_\(i)",
                colorHex1: Color(hue: hue, saturation: 0.6, brightness: 0.9).toHex(),
                colorHex2: Color(hue: hue + 0.1, saturation: 0.7, brightness: 0.8).toHex(),
                iconName: icons[i]
            )
        }
    }()
}

// MARK: - Profile Tab

enum DemoProfileTab: String, CaseIterable, Hashable {
    case grid = "grid"
    case reels = "play.square.stack"
    case bookmarks = "bookmark"
}


// ============================================================
// MARK: - Demo Profile Data Store
// ============================================================

class DemoProfileStore: ObservableObject {
    static let shared = DemoProfileStore()
    
    @Published var profileData: DemoProfileData = .default
    @Published var gridPosts: [DemoGridPost] = []
    
    private let profileKey = "demo_profile_data_v1"
    private let gridKey = "demo_profile_grid_v1"
    
    private var countTimer: Timer?
    
    init() {
        loadData()
    }
    
    // MARK: - Load
    
    func loadData() {
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let decoded = try? JSONDecoder().decode(DemoProfileData.self, from: data) {
            profileData = decoded
        } else {
            profileData = .default
        }
        
        if let data = UserDefaults.standard.data(forKey: gridKey),
           let decoded = try? JSONDecoder().decode([DemoGridPost].self, from: data) {
            gridPosts = decoded
        } else {
            gridPosts = DemoGridPost.samples
        }
    }
    
    // MARK: - Save
    
    func save() {
        if let data = try? JSONEncoder().encode(profileData) {
            UserDefaults.standard.set(data, forKey: profileKey)
        }
        if let data = try? JSONEncoder().encode(gridPosts) {
            UserDefaults.standard.set(data, forKey: gridKey)
        }
    }
    
    // MARK: - Update Profile
    
    func updateProfile(_ profile: DemoProfileData) {
        profileData = profile
        save()
    }
    
    // MARK: - Grid CRUD
    
    func addGridPost(_ post: DemoGridPost) {
        gridPosts.append(post)
        save()
    }
    
    func removeGridPost(id: String) {
        gridPosts.removeAll { $0.id == id }
        save()
    }
    
    func removeGridPost(at offsets: IndexSet) {
        gridPosts.remove(atOffsets: offsets)
        save()
    }
    
    // MARK: - Count Up/Down
    
    func startCounting() {
        guard profileData.isCountUpEnabled else { return }
        stopCounting()
        countTimer = Timer.scheduledTimer(withTimeInterval: profileData.countInterval, repeats: true) { [weak self] _ in
            guard let self = self, self.profileData.isCountUpEnabled else {
                self?.stopCounting()
                return
            }
            let delta = Int.random(in: self.profileData.countMinDelta...max(self.profileData.countMinDelta, self.profileData.countMaxDelta))
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                switch self.profileData.countMode {
                case .up:
                    self.profileData.followersCount += delta
                case .down:
                    self.profileData.followersCount = max(0, self.profileData.followersCount - delta)
                }
            }
        }
    }
    
    func stopCounting() {
        countTimer?.invalidate()
        countTimer = nil
    }
    
    // MARK: - Reset
    
    func resetToDefaults() {
        stopCounting()
        profileData = .default
        gridPosts = DemoGridPost.samples
        save()
    }
    
    deinit {
        countTimer?.invalidate()
    }
}


// ============================================================
// MARK: - Demo Profile Main View
// ============================================================

@available(iOS 17.0, *)
struct DemoProfileView: View {
    @StateObject private var store = DemoProfileStore.shared
    @State private var showingSettings = false
    @State private var selectedTab: DemoProfileTab = .grid
    @State private var selectedPhotoItem: PhotosPickerItem?
    @Namespace private var profileTabNamespace
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                        .padding(.top, -60)
                    
                    VStack(spacing: 20) {
                        profileImageSection
                            .offset(y: -50)
                        
                        userInfoSection
                            .offset(y: -30)
                        
                        statsSection
                            .offset(y: -20)
                        
                        actionButtonsSection
                        
                        postsGridSection
                    }
                    .padding(.horizontal)
                }
            }
            .ignoresSafeArea(edges: .top)
            .background(Color(.systemGroupedBackground))
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                DemoProfileSettingsView(store: store)
            }
            .onAppear {
                if store.profileData.isCountUpEnabled {
                    store.startCounting()
                }
            }
            .onDisappear {
                store.stopCounting()
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                handlePhotoSelection(newItem)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        ZStack {
            LinearGradient(
                colors: [
                    store.profileData.headerColor1,
                    store.profileData.headerColor2,
                    store.profileData.headerColor3
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // パターンオーバーレイ
            GeometryReader { geo in
                Canvas { context, size in
                    for i in 0..<20 {
                        let seed = UInt64(i * 12345 + 6789)
                        let x = CGFloat(seed % UInt64(size.width))
                        let y = CGFloat((seed / 3) % UInt64(max(1, size.height)))
                        let circle = Path(ellipseIn: CGRect(x: x, y: y, width: 50, height: 50))
                        context.fill(circle, with: .color(.white.opacity(0.05)))
                    }
                }
            }
        }
        .frame(height: 240)
    }
    
    // MARK: - Profile Image Section
    
    private var profileImageSection: some View {
        ZStack {
            // 外側グラデーションリング
            Circle()
                .fill(
                    LinearGradient(
                        colors: [store.profileData.headerColor1, store.profileData.headerColor3],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 110, height: 110)
            
            // アバター
            if let imageData = store.profileData.avatarImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [store.profileData.avatarColor, store.profileData.avatarColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .overlay {
                        Text(store.profileData.avatarEmoji)
                            .font(.system(size: 44))
                    }
            }
            
            // カメラボタン
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Circle()
                    .fill(.white)
                    .frame(width: 32, height: 32)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    .overlay {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(store.profileData.headerColor1)
                    }
            }
            .offset(x: 35, y: 35)
        }
    }
    
    // MARK: - User Info Section
    
    private var userInfoSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Text(store.profileData.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if store.profileData.isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(store.profileData.verifiedColor)
                        .font(.subheadline)
                }
            }
            
            Text("@\(store.profileData.username)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if !store.profileData.bio.isEmpty {
                Text(store.profileData.bio)
                    .font(.system(size: 14))
                    .foregroundColor(Color(.label))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.top, 4)
                    .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        HStack(spacing: 0) {
            DemoStatItem(value: store.profileData.postsCount, label: "投稿", accentColor: store.profileData.headerColor1)
            
            Divider()
                .frame(height: 40)
            
            DemoStatItem(value: store.profileData.followersCount, label: "フォロワー", accentColor: store.profileData.headerColor1)
            
            Divider()
                .frame(height: 40)
            
            DemoStatItem(value: store.profileData.followingCount, label: "フォロー中", accentColor: store.profileData.headerColor1)
        }
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        }
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            Button {} label: {
                Text("フォロー")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background {
                        LinearGradient(
                            colors: [store.profileData.headerColor1, store.profileData.headerColor3],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
            }
            
            Button {} label: {
                Text("メッセージ")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                    }
            }
            
            Button {} label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                    }
            }
        }
    }
    
    // MARK: - Posts Grid Section
    
    private var postsGridSection: some View {
        VStack(spacing: 16) {
            // Tab Bar
            HStack(spacing: 0) {
                ForEach(DemoProfileTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: tab.rawValue)
                                .font(.title3)
                                .foregroundStyle(selectedTab == tab ? Color(.label) : Color(.secondaryLabel))
                            
                            ZStack {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(height: 2)
                                if selectedTab == tab {
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(
                                            LinearGradient(
                                                colors: [store.profileData.headerColor1, store.profileData.headerColor2],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: 40, height: 2)
                                        .matchedGeometryEffect(id: "profileTabIndicator", in: profileTabNamespace)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
            
            // Grid
            let visiblePosts = store.gridPosts.filter { !$0.isHidden }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2) {
                ForEach(visiblePosts) { post in
                    if let imageData = post.imageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .aspectRatio(1, contentMode: .fill)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [post.color1, post.color2],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                Image(systemName: post.iconName)
                                    .font(.title)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.top, 8)
    }
    
    // MARK: - Photo Handling
    
    private func handlePhotoSelection(_ newItem: PhotosPickerItem?) {
        Task {
            guard let newItem,
                  let data = try? await newItem.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else { return }
            await MainActor.run {
                if let jpegData = uiImage.jpegData(compressionQuality: 0.8) {
                    var profile = store.profileData
                    profile.avatarImageBase64 = jpegData.base64EncodedString()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        store.updateProfile(profile)
                    }
                }
            }
        }
    }
}


// MARK: - Stat Item

@available(iOS 17.0, *)
struct DemoStatItem: View {
    let value: Int
    let label: String
    var accentColor: Color = Color(hex: "#6C5CE7")
    
    var body: some View {
        VStack(spacing: 4) {
            Text(formatNumber(value))
                .font(.title3)
                .fontWeight(.bold)
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(value)))
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func formatNumber(_ num: Int) -> String {
        if num >= 10000 {
            return String(format: "%.1f万", Double(num) / 10000)
        } else if num >= 1000 {
            return String(format: "%.1fK", Double(num) / 1000)
        }
        return "\(num)"
    }
}


// ============================================================
// MARK: - Demo Profile Settings View
// ============================================================

@available(iOS 17.0, *)
struct DemoProfileSettingsView: View {
    @ObservedObject var store: DemoProfileStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: ProfileSettingsTab = .profile
    @State private var showResetAlert = false
    
    enum ProfileSettingsTab: String, CaseIterable {
        case profile = "プロフィール"
        case stats = "数値"
        case appearance = "外観"
        case grid = "投稿グリッド"
        case counter = "カウンター"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                settingsTabBar
                
                switch selectedTab {
                case .profile:
                    profileEditView
                case .stats:
                    statsEditView
                case .appearance:
                    appearanceEditView
                case .grid:
                    gridEditView
                case .counter:
                    counterSettingsView
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("プロフィール設定")
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
                Text("現在の設定がすべて削除され、初期データに置き換わります。")
            }
        }
    }
    
    // MARK: - Tab Bar
    
    private var settingsTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(ProfileSettingsTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Text(tab.rawValue)
                                .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .regular))
                                .foregroundColor(selectedTab == tab ? Color(.label) : Color(.secondaryLabel))
                            
                            Rectangle()
                                .fill(selectedTab == tab
                                      ? LinearGradient(colors: [Color(hex: "#6C5CE7"), Color(hex: "#a29bfe")], startPoint: .leading, endPoint: .trailing)
                                      : LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
                                )
                                .frame(height: 2)
                                .cornerRadius(1)
                        }
                        .frame(minWidth: 70)
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
    
    // MARK: - Profile Edit
    
    private var profileEditView: some View {
        DemoProfileBasicEditView(store: store)
    }
    
    // MARK: - Stats Edit
    
    private var statsEditView: some View {
        DemoProfileStatsEditView(store: store)
    }
    
    // MARK: - Appearance Edit
    
    private var appearanceEditView: some View {
        DemoProfileAppearanceView(store: store)
    }
    
    // MARK: - Grid Edit
    
    private var gridEditView: some View {
        DemoProfileGridEditView(store: store)
    }
    
    // MARK: - Counter Settings
    
    private var counterSettingsView: some View {
        DemoProfileCounterView(store: store)
    }
}


// ============================================================
// MARK: - Profile Basic Edit View
// ============================================================

@available(iOS 17.0, *)
struct DemoProfileBasicEditView: View {
    @ObservedObject var store: DemoProfileStore
    
    @State private var displayName: String = ""
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var selectedEmoji: String = "😊"
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var uploadedImageData: Data?
    
    private struct CropTarget: Identifiable {
        let id = UUID()
        let image: UIImage
    }
    @State private var cropTarget: CropTarget?
    
    let emojiOptions = ["😊", "😀", "🌸", "💻", "🎵", "📷", "🍳", "🎮", "📚", "🎨", "⚽", "🐱", "🐶", "🌙", "☀️", "🔥", "💎", "🦊", "🐻", "🌺", "🍀", "🎭", "🏄", "🧑‍🚀"]
    
    var body: some View {
        Form {
            // プレビュー
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
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
                                            colors: [store.profileData.avatarColor, store.profileData.avatarColor.opacity(0.6)],
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
                                Text(displayName.isEmpty ? "あなた" : displayName)
                                    .font(.system(size: 16, weight: .semibold))
                                if store.profileData.isVerified {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(store.profileData.verifiedColor)
                                }
                            }
                            Text("@\(username.isEmpty ? "you" : username)")
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
                TextField("表示名", text: $displayName)
                    .onChange(of: displayName) { _, _ in saveProfile() }
                TextField("ユーザー名", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: username) { _, _ in saveProfile() }
            } header: {
                Text("基本情報")
            }
            
            // 自己紹介
            Section {
                ZStack(alignment: .topLeading) {
                    if bio.isEmpty {
                        Text("自己紹介を入力...")
                            .foregroundColor(Color(.placeholderText))
                            .padding(.top, 8)
                            .padding(.leading, 4)
                    }
                    TextEditor(text: $bio)
                        .frame(minHeight: 80)
                        .scrollContentBackground(.hidden)
                        .onChange(of: bio) { _, _ in saveProfile() }
                }
            } header: {
                Text("自己紹介")
            }
            
            // プロフィール画像
            Section {
                profileImagePicker
            } header: {
                Text("プロフィール画像")
            } footer: {
                Text("画像を設定しない場合は、絵文字アイコンが使用されます。")
            }
            
            // 絵文字アイコン
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
            }
            
            // 認証バッジ
            Section {
                Toggle("認証バッジを表示", isOn: Binding(
                    get: { store.profileData.isVerified },
                    set: { newVal in
                        var p = store.profileData
                        p.isVerified = newVal
                        store.updateProfile(p)
                    }
                ))
                .tint(Color(hex: "#6C5CE7"))
            } header: {
                Text("認証バッジ")
            }
        }
        .onAppear { loadProfile() }
        .onChange(of: selectedPhotoItem) { _, newItem in
            handlePhotoSelection(newItem)
        }
        .fullScreenCover(item: $cropTarget) { target in
            DemoImageCropper(image: target.image, croppedData: $uploadedImageData)
        }
        .onChange(of: uploadedImageData) { _, _ in saveProfile() }
    }
    
    @ViewBuilder
    private var profileImagePicker: some View {
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
        displayName = store.profileData.displayName
        username = store.profileData.username
        bio = store.profileData.bio
        selectedEmoji = store.profileData.avatarEmoji
        uploadedImageData = store.profileData.avatarImageData
    }
    
    private func saveProfile() {
        var p = store.profileData
        p.displayName = displayName.isEmpty ? "あなた" : displayName
        p.username = username.isEmpty ? "you" : username
        p.bio = bio
        p.avatarEmoji = selectedEmoji
        p.avatarImageBase64 = uploadedImageData?.base64EncodedString()
        store.updateProfile(p)
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
// MARK: - Stats Edit View
// ============================================================

@available(iOS 17.0, *)
struct DemoProfileStatsEditView: View {
    @ObservedObject var store: DemoProfileStore
    
    var body: some View {
        Form {
            Section {
                statRow(icon: "square.grid.2x2", iconColor: Color(hex: "#6C5CE7"), label: "投稿数",
                        value: Binding(
                            get: { store.profileData.postsCount },
                            set: { store.profileData.postsCount = $0; store.save() }
                        ))
                
                statRow(icon: "person.2", iconColor: Color(hex: "#FF6B9D"), label: "フォロワー",
                        value: Binding(
                            get: { store.profileData.followersCount },
                            set: { store.profileData.followersCount = $0; store.save() }
                        ))
                
                statRow(icon: "person.badge.plus", iconColor: Color(hex: "#2ECC71"), label: "フォロー中",
                        value: Binding(
                            get: { store.profileData.followingCount },
                            set: { store.profileData.followingCount = $0; store.save() }
                        ))
            } header: {
                Text("数値設定")
            } footer: {
                Text("各数値を直接入力するか、ステッパーで調整できます。")
            }
            
            // クイックプリセット
            Section {
                Button {
                    applyPreset(posts: 42, followers: 1024, following: 128)
                } label: {
                    presetRow(label: "一般ユーザー", detail: "投稿42 / フォロワー1,024 / フォロー128")
                }
                
                Button {
                    applyPreset(posts: 356, followers: 15800, following: 520)
                } label: {
                    presetRow(label: "インフルエンサー", detail: "投稿356 / フォロワー15,800 / フォロー520")
                }
                
                Button {
                    applyPreset(posts: 2480, followers: 284000, following: 890)
                } label: {
                    presetRow(label: "有名人", detail: "投稿2,480 / フォロワー284,000 / フォロー890")
                }
            } header: {
                Text("プリセット")
            }
        }
    }
    
    private func statRow(icon: String, iconColor: Color, label: String, value: Binding<Int>) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)
            Text(label)
            Spacer()
            TextField("0", value: value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 100)
            Stepper("", value: value, in: 0...9999999)
                .labelsHidden()
        }
    }
    
    private func presetRow(label: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "#6C5CE7"))
            Text(detail)
                .font(.system(size: 12))
                .foregroundColor(Color(.secondaryLabel))
        }
        .padding(.vertical, 2)
    }
    
    private func applyPreset(posts: Int, followers: Int, following: Int) {
        withAnimation(.spring(response: 0.3)) {
            var p = store.profileData
            p.postsCount = posts
            p.followersCount = followers
            p.followingCount = following
            store.updateProfile(p)
        }
    }
}


// ============================================================
// MARK: - Appearance Edit View
// ============================================================

@available(iOS 17.0, *)
struct DemoProfileAppearanceView: View {
    @ObservedObject var store: DemoProfileStore
    
    let colorOptions = ["#6C5CE7", "#a29bfe", "#FF6B9D", "#fd79a8", "#4A90D9", "#74b9ff", "#F5A623", "#ffeaa7", "#7B68EE", "#2ECC71", "#E74C3C", "#1ABC9C", "#E67E22", "#9B59B6", "#34495E", "#FF4757", "#00cec9", "#fdcb6e", "#e17055", "#636e72"]
    
    var body: some View {
        Form {
            // ヘッダーグラデーションプレビュー
            Section {
                ZStack {
                    LinearGradient(
                        colors: [
                            store.profileData.headerColor1,
                            store.profileData.headerColor2,
                            store.profileData.headerColor3
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 100)
                    .cornerRadius(12)
                    
                    Text("ヘッダープレビュー")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
            } header: {
                Text("ヘッダーグラデーション")
            }
            
            // カラー1
            Section {
                colorGrid(selectedHex: Binding(
                    get: { store.profileData.headerColorHex1 },
                    set: { var p = store.profileData; p.headerColorHex1 = $0; store.updateProfile(p) }
                ))
            } header: {
                Text("ヘッダー色 1（左上）")
            }
            
            // カラー2
            Section {
                colorGrid(selectedHex: Binding(
                    get: { store.profileData.headerColorHex2 },
                    set: { var p = store.profileData; p.headerColorHex2 = $0; store.updateProfile(p) }
                ))
            } header: {
                Text("ヘッダー色 2（中央）")
            }
            
            // カラー3
            Section {
                colorGrid(selectedHex: Binding(
                    get: { store.profileData.headerColorHex3 },
                    set: { var p = store.profileData; p.headerColorHex3 = $0; store.updateProfile(p) }
                ))
            } header: {
                Text("ヘッダー色 3（右下）")
            }
            
            // アバターカラー
            Section {
                colorGrid(selectedHex: Binding(
                    get: { store.profileData.avatarColorHex },
                    set: { var p = store.profileData; p.avatarColorHex = $0; store.updateProfile(p) }
                ))
            } header: {
                Text("アバター背景色")
            } footer: {
                Text("プロフィール画像が設定されていない場合に表示される絵文字アイコンの背景色です。")
            }
            
            // 認証バッジ色
            Section {
                colorGrid(selectedHex: Binding(
                    get: { store.profileData.verifiedColorHex },
                    set: { var p = store.profileData; p.verifiedColorHex = $0; store.updateProfile(p) }
                ))
            } header: {
                Text("認証バッジの色")
            }
        }
    }
    
    private func colorGrid(selectedHex: Binding<String>) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 10), spacing: 10) {
            ForEach(colorOptions, id: \.self) { hex in
                Button {
                    selectedHex.wrappedValue = hex
                } label: {
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: selectedHex.wrappedValue == hex ? 3 : 0)
                        )
                        .shadow(color: selectedHex.wrappedValue == hex ? Color(hex: hex).opacity(0.5) : .clear, radius: 3)
                }
                .buttonStyle(.plain)
            }
        }
    }
}


// ============================================================
// MARK: - Grid Edit View
// ============================================================

@available(iOS 17.0, *)
struct DemoProfileGridEditView: View {
    @ObservedObject var store: DemoProfileStore
    @State private var showingAddPost = false
    
    var body: some View {
        List {
            Section {
                ForEach(store.gridPosts) { post in
                    HStack(spacing: 12) {
                        // サムネイル
                        if let imageData = post.imageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        } else {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [post.color1, post.color2],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                                .overlay {
                                    Image(systemName: post.iconName)
                                        .font(.system(size: 16))
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(post.iconName)
                                .font(.system(size: 14, weight: .medium))
                            Text(post.isHidden ? "非表示" : "表示中")
                                .font(.system(size: 12))
                                .foregroundColor(post.isHidden ? Color(.tertiaryLabel) : Color(hex: "#2ECC71"))
                        }
                        
                        Spacer()
                        
                        Button {
                            withAnimation {
                                if let idx = store.gridPosts.firstIndex(where: { $0.id == post.id }) {
                                    store.gridPosts[idx].isHidden.toggle()
                                    store.save()
                                }
                            }
                        } label: {
                            Image(systemName: post.isHidden ? "eye.slash.fill" : "eye.fill")
                                .font(.system(size: 14))
                                .foregroundColor(post.isHidden ? Color(.tertiaryLabel) : Color(hex: "#6C5CE7"))
                                .frame(width: 32, height: 32)
                                .background(
                                    post.isHidden
                                    ? Color(.tertiarySystemFill)
                                    : Color(hex: "#6C5CE7").opacity(0.1)
                                )
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .opacity(post.isHidden ? 0.5 : 1.0)
                }
                .onDelete { offsets in
                    store.removeGridPost(at: offsets)
                }
            } header: {
                Text("投稿グリッド (\(store.gridPosts.count))")
            } footer: {
                Text("グリッドに表示される投稿の管理ができます。左スワイプで削除、👁アイコンで表示切り替え。")
            }
            
            Section {
                Button {
                    showingAddPost = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "#6C5CE7"))
                        Text("グリッド投稿を追加")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(hex: "#6C5CE7"))
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .sheet(isPresented: $showingAddPost) {
            AddGridPostSheet(store: store)
        }
    }
}


// ============================================================
// MARK: - Add Grid Post Sheet
// ============================================================

@available(iOS 17.0, *)
struct AddGridPostSheet: View {
    @ObservedObject var store: DemoProfileStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var uploadedImageData: Data?
    @State private var selectedIcon = "photo"
    @State private var colorHex1 = "#6C5CE7"
    @State private var colorHex2 = "#a29bfe"
    
    let iconOptions = ["photo", "heart.fill", "star.fill", "camera.fill", "leaf.fill", "music.note", "paintbrush.fill", "sparkles", "globe", "flame.fill", "moon.fill", "sun.max.fill"]
    let colorOptions = ["#6C5CE7", "#a29bfe", "#FF6B9D", "#fd79a8", "#4A90D9", "#74b9ff", "#F5A623", "#2ECC71", "#E74C3C", "#1ABC9C", "#E67E22", "#9B59B6"]
    
    var body: some View {
        NavigationStack {
            Form {
                // 画像選択
                Section {
                    VStack(spacing: 12) {
                        if let imageData = uploadedImageData, let uiImage = UIImage(data: imageData) {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                
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
                        }
                        
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Label(uploadedImageData == nil ? "画像を選択" : "別の画像を選択", systemImage: "photo.badge.plus")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(hex: "#6C5CE7").opacity(0.08))
                                .cornerRadius(10)
                        }
                    }
                } header: {
                    Text("投稿画像（任意）")
                } footer: {
                    Text("画像がない場合はグラデーション背景にアイコンが表示されます。")
                }
                
                // アイコン（画像なしの場合）
                if uploadedImageData == nil {
                    Section {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(iconOptions, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.system(size: 20))
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(selectedIcon == icon ? .white : Color(.secondaryLabel))
                                        .background(
                                            selectedIcon == icon
                                            ? Color(hex: "#6C5CE7")
                                            : Color(.tertiarySystemFill)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } header: {
                        Text("アイコン")
                    }
                    
                    Section {
                        Text("グラデーション色 1")
                            .font(.system(size: 13))
                            .foregroundColor(Color(.secondaryLabel))
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                            ForEach(colorOptions, id: \.self) { hex in
                                Button {
                                    colorHex1 = hex
                                } label: {
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: colorHex1 == hex ? 3 : 0)
                                        )
                                        .shadow(color: colorHex1 == hex ? Color(hex: hex).opacity(0.5) : .clear, radius: 3)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        Text("グラデーション色 2")
                            .font(.system(size: 13))
                            .foregroundColor(Color(.secondaryLabel))
                            .padding(.top, 8)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                            ForEach(colorOptions, id: \.self) { hex in
                                Button {
                                    colorHex2 = hex
                                } label: {
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: colorHex2 == hex ? 3 : 0)
                                        )
                                        .shadow(color: colorHex2 == hex ? Color(hex: hex).opacity(0.5) : .clear, radius: 3)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } header: {
                        Text("背景色")
                    }
                }
                
                // プレビュー
                Section {
                    HStack {
                        Spacer()
                        if let imageData = uploadedImageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: colorHex1), Color(hex: colorHex2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .overlay {
                                    Image(systemName: selectedIcon)
                                        .font(.title)
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("プレビュー")
                }
            }
            .navigationTitle("グリッド投稿追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        let post = DemoGridPost(
                            colorHex1: colorHex1,
                            colorHex2: colorHex2,
                            iconName: selectedIcon,
                            imageBase64: uploadedImageData?.base64EncodedString()
                        )
                        store.addGridPost(post)
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    guard let newItem,
                          let data = try? await newItem.loadTransferable(type: Data.self) else { return }
                    await MainActor.run {
                        uploadedImageData = data
                    }
                }
            }
        }
    }
}


// ============================================================
// MARK: - Counter Settings View
// ============================================================

@available(iOS 17.0, *)
struct DemoProfileCounterView: View {
    @ObservedObject var store: DemoProfileStore
    
    var body: some View {
        Form {
            Section {
                Toggle("カウンターを有効化", isOn: Binding(
                    get: { store.profileData.isCountUpEnabled },
                    set: { newVal in
                        var p = store.profileData
                        p.isCountUpEnabled = newVal
                        store.updateProfile(p)
                        if newVal {
                            store.startCounting()
                        } else {
                            store.stopCounting()
                        }
                    }
                ))
                .tint(Color(hex: "#6C5CE7"))
            } header: {
                Text("カウンター")
            } footer: {
                Text("ONにすると、フォロワー数が自動で変動します。デモ動画撮影時にリアルタイム感を演出できます。")
            }
            
            Section {
                Picker("モード", selection: Binding(
                    get: { store.profileData.countMode },
                    set: { newVal in
                        var p = store.profileData
                        p.countMode = newVal
                        store.updateProfile(p)
                        if p.isCountUpEnabled {
                            store.startCounting()
                        }
                    }
                )) {
                    ForEach(DemoProfileData.CountMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("カウントモード")
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("更新間隔")
                        Spacer()
                        Text(String(format: "%.1f 秒", store.profileData.countInterval))
                            .font(.system(size: 15, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color(hex: "#6C5CE7"))
                    }
                    Slider(value: Binding(
                        get: { store.profileData.countInterval },
                        set: { var p = store.profileData; p.countInterval = $0; store.updateProfile(p) }
                    ), in: 0.1...5.0, step: 0.1)
                    .tint(Color(hex: "#6C5CE7"))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("変動量（最小）")
                        Spacer()
                        Text("\(store.profileData.countMinDelta)")
                            .font(.system(size: 15, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color(hex: "#6C5CE7"))
                    }
                    Stepper("", value: Binding(
                        get: { store.profileData.countMinDelta },
                        set: { var p = store.profileData; p.countMinDelta = $0; store.updateProfile(p) }
                    ), in: 1...100)
                    .labelsHidden()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("変動量（最大）")
                        Spacer()
                        Text("\(store.profileData.countMaxDelta)")
                            .font(.system(size: 15, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color(hex: "#6C5CE7"))
                    }
                    Stepper("", value: Binding(
                        get: { store.profileData.countMaxDelta },
                        set: { var p = store.profileData; p.countMaxDelta = $0; store.updateProfile(p) }
                    ), in: 1...100)
                    .labelsHidden()
                }
            } header: {
                Text("詳細設定")
            } footer: {
                Text("更新間隔ごとに、最小〜最大の範囲でランダムにフォロワー数が変動します。")
            }
            
            // リアルタイムプレビュー
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Text("フォロワー")
                            .font(.system(size: 13))
                            .foregroundColor(Color(.secondaryLabel))
                        Text(formatNumber(store.profileData.followersCount))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(Color(hex: "#6C5CE7"))
                            .contentTransition(.numericText(value: Double(store.profileData.followersCount)))
                            .animation(.spring(response: 0.3), value: store.profileData.followersCount)
                        
                        if store.profileData.isCountUpEnabled {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color(hex: "#2ECC71"))
                                    .frame(width: 8, height: 8)
                                Text("カウント中...")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "#2ECC71"))
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 12)
            } header: {
                Text("リアルタイムプレビュー")
            }
        }
    }
    
    private func formatNumber(_ num: Int) -> String {
        if num >= 10000 {
            return String(format: "%.1f万", Double(num) / 10000)
        } else if num >= 1000 {
            return String(format: "%.1fK", Double(num) / 1000)
        }
        return "\(num)"
    }
}


// ============================================================
// MARK: - Previews
// ============================================================

#Preview("Demo Profile") {
    if #available(iOS 17.0, *) {
        DemoProfileView()
    }
}

#Preview("Demo Profile Settings") {
    if #available(iOS 17.0, *) {
        DemoProfileSettingsView(store: DemoProfileStore.shared)
    }
}

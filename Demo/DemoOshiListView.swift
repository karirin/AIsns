//
//  DemoOshiListView.swift
//  AIsns
//
//  Created by Apple on 2026/02/08.
//
//  フォロワー/フォロー中リストのデモ画面
//

import SwiftUI
import PhotosUI

// ============================================================
// MARK: - Models
// ============================================================

// MARK: - Demo Oshi Character

struct DemoOshiCharacter: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var accountId: String  // DemoAccount の id を参照
    var isFollowingUser: Bool = true   // フォロワー(相手→自分)
    var isFollowedByUser: Bool = false // フォロー中(自分→相手)
    var isHidden: Bool = false
    
    /// 表示遅延(秒)
    var displayDelay: Double = 1.0
    
    var isMutualFollow: Bool {
        isFollowingUser && isFollowedByUser
    }
    
    var relationshipLabel: String {
        if isMutualFollow { return "相互フォロー" }
        if isFollowingUser { return "フォロワー" }
        if isFollowedByUser { return "フォロー中" }
        return "なし"
    }
    
    static let samples: [DemoOshiCharacter] = [
        DemoOshiCharacter(
            id: "oshi_1", accountId: "acc_1",
            isFollowingUser: true, isFollowedByUser: true, displayDelay: 0.8
        ),
        DemoOshiCharacter(
            id: "oshi_2", accountId: "acc_2",
            isFollowingUser: true, isFollowedByUser: false, displayDelay: 1.2
        ),
        DemoOshiCharacter(
            id: "oshi_3", accountId: "acc_3",
            isFollowingUser: true, isFollowedByUser: true, displayDelay: 1.6
        ),
        DemoOshiCharacter(
            id: "oshi_4", accountId: "acc_4",
            isFollowingUser: false, isFollowedByUser: true, displayDelay: 2.0
        ),
        DemoOshiCharacter(
            id: "oshi_5", accountId: "acc_5",
            isFollowingUser: true, isFollowedByUser: false, displayDelay: 2.4
        ),
    ]
}


// ============================================================
// MARK: - Demo Oshi List Data Store
// ============================================================

class DemoOshiListStore: ObservableObject {
    static let shared = DemoOshiListStore()
    
    @Published var oshis: [DemoOshiCharacter] = []
    @Published var defaultDisplayInterval: Double = 0.8
    @Published var showMutualBadge: Bool = true
    @Published var animateEntrance: Bool = true
    
    private let oshisKey = "demo_oshi_list_v1"
    private let intervalKey = "demo_oshi_interval_v1"
    private let badgeKey = "demo_oshi_badge_v1"
    private let animateKey = "demo_oshi_animate_v1"
    
    init() { loadData() }
    
    // MARK: - Load
    
    func syncAccountsFromShared() {
        let shared = DemoSharedAccountStore.shared.accounts
        let sharedIds = Set(shared.map { $0.id })

        // 共有アカウントに存在するのに、oshis に無い分を「登録」しておく（関係は "なし"）
        for acc in shared {
            if !oshis.contains(where: { $0.accountId == acc.id }) {
                oshis.append(
                    DemoOshiCharacter(
                        accountId: acc.id,
                        isFollowingUser: false,
                        isFollowedByUser: false,
                        displayDelay: defaultDisplayInterval
                    )
                )
            }
        }

        // 共有から消えたアカウントに紐づく oshis は掃除（整合性維持）
        oshis.removeAll { !sharedIds.contains($0.accountId) }

        save()
    }
    
    func loadData() {
        if let data = UserDefaults.standard.data(forKey: oshisKey),
           let decoded = try? JSONDecoder().decode([DemoOshiCharacter].self, from: data) {
            oshis = decoded
        } else {
            oshis = DemoOshiCharacter.samples
        }
        
        let saved = UserDefaults.standard.double(forKey: intervalKey)
        defaultDisplayInterval = saved > 0 ? saved : 0.8
        
        showMutualBadge = UserDefaults.standard.object(forKey: badgeKey) as? Bool ?? true
        animateEntrance = UserDefaults.standard.object(forKey: animateKey) as? Bool ?? true
    }
    
    // MARK: - Save
    
    func save() {
        if let data = try? JSONEncoder().encode(oshis) {
            UserDefaults.standard.set(data, forKey: oshisKey)
        }
        UserDefaults.standard.set(defaultDisplayInterval, forKey: intervalKey)
        UserDefaults.standard.set(showMutualBadge, forKey: badgeKey)
        UserDefaults.standard.set(animateEntrance, forKey: animateKey)
    }
    
    // MARK: - CRUD
    
    func addOshi(_ oshi: DemoOshiCharacter) {
        oshis.append(oshi)
        save()
    }
    
    func removeOshi(at offsets: IndexSet) {
        oshis.remove(atOffsets: offsets)
        save()
    }
    
    func removeOshi(id: String) {
        oshis.removeAll { $0.id == id }
        save()
    }
    
    func moveOshi(from source: IndexSet, to destination: Int) {
        oshis.move(fromOffsets: source, toOffset: destination)
        save()
    }
    
    func toggleVisibility(id: String) {
        if let idx = oshis.firstIndex(where: { $0.id == id }) {
            oshis[idx].isHidden.toggle()
            save()
        }
    }
    
    func updateOshi(id: String, updater: (inout DemoOshiCharacter) -> Void) {
        if let idx = oshis.firstIndex(where: { $0.id == id }) {
            updater(&oshis[idx])
            save()
        }
    }
    
    
    
    func oshi(for id: String) -> DemoOshiCharacter? {
        oshis.first { $0.id == id }
    }
    
    func account(for oshi: DemoOshiCharacter) -> DemoAccount? {
        DemoSharedAccountStore.shared.account(for: oshi.accountId)
    }
    
    // フィルタ済みリスト
    var followers: [DemoOshiCharacter] {
        oshis.filter { $0.isFollowingUser && !$0.isHidden }
    }
    
    var following: [DemoOshiCharacter] {
        oshis.filter { $0.isFollowedByUser && !$0.isHidden }
    }
    
    // MARK: - Reset
    
    func resetToDefaults() {
        oshis = DemoOshiCharacter.samples
        defaultDisplayInterval = 0.8
        showMutualBadge = true
        animateEntrance = true
        save()
    }
}


// ============================================================
// MARK: - Demo Oshi List Main View
// ============================================================

@available(iOS 17.0, *)
struct DemoOshiListView: View {
    @StateObject private var store = DemoOshiListStore.shared
    @StateObject private var accountStore = DemoSharedAccountStore.shared
    @State private var selectedTab: Int = 0
    @State private var showingSettings = false
    @Namespace private var tabAnimation
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerView
                tabBarView
                
                TabView(selection: $selectedTab) {
                    oshiListPage(
                        oshis: store.followers,
                        emptyTitle: "フォロワーはいません",
                        emptySubtitle: "投稿してフォローしてもらいましょう",
                        iconName: "person.2.slash"
                    )
                    .tag(0)
                    
                    oshiListPage(
                        oshis: store.following,
                        emptyTitle: "フォロー中のアカウントはいません",
                        emptySubtitle: "気になるアカウントを見つけてフォローしましょう",
                        iconName: "person.slash"
                    )
                    .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedTab)
            }
            .onAppear {
                store.syncAccountsFromShared()
            }
            .onReceive(accountStore.$accounts) { _ in
                store.syncAccountsFromShared()
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettings) {
                DemoOshiListSettingsView(store: store)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Button {
                showingSettings = true
            } label: {
                DemoUserAvatar(profile: DemoPostReactionStore.shared.userProfile, size: 32, emojiSize: 14)
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
            
            Color.clear
                .frame(width: 32, height: 32)
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
            demoTabButton(title: "フォロワー", count: store.followers.count, tag: 0)
            demoTabButton(title: "フォロー中", count: store.following.count, tag: 1)
        }
        .padding(.top, 4)
        .background(Color(.systemBackground))
        .overlay(Divider(), alignment: .bottom)
    }
    
    private func demoTabButton(title: String, count: Int, tag: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedTab = tag
            }
        } label: {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 15, weight: selectedTab == tag ? .semibold : .regular))
                        .foregroundColor(selectedTab == tag ? Color(.label) : Color(.secondaryLabel))
                    
                    Text("\(count)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(selectedTab == tag ? Color(hex: "#6C5CE7") : Color(.tertiaryLabel))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            selectedTab == tag
                            ? Color(hex: "#6C5CE7").opacity(0.1)
                            : Color(.tertiarySystemFill)
                        )
                        .clipShape(Capsule())
                }
                
                ZStack {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 3)
                    if selectedTab == tag {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#6C5CE7"), Color(hex: "#a29bfe")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 60, height: 3)
                            .matchedGeometryEffect(id: "oshiTabIndicator", in: tabAnimation)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - List Page
    
    @ViewBuilder
    private func oshiListPage(
        oshis: [DemoOshiCharacter],
        emptyTitle: String,
        emptySubtitle: String,
        iconName: String
    ) -> some View {
        if oshis.isEmpty {
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: iconName)
                    .font(.system(size: 48))
                    .foregroundColor(Color(.tertiaryLabel))
                Text(emptyTitle)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(.label))
                Text(emptySubtitle)
                    .font(.system(size: 14))
                    .foregroundColor(Color(.secondaryLabel))
                    .multilineTextAlignment(.center)
                Spacer()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(oshis) { oshi in
                        if let account = store.account(for: oshi) {
                            DemoOshiRow(oshi: oshi, account: account, store: store)
                            
                            if oshi.id != oshis.last?.id {
                                Divider()
                                    .padding(.leading, 78)
                            }
                        }
                    }
                }
                .padding(.bottom, 100)
            }
        }
    }
}


// ============================================================
// MARK: - Demo Oshi Row
// ============================================================

struct DemoOshiRow: View {
    let oshi: DemoOshiCharacter
    let account: DemoAccount
    @ObservedObject var store: DemoOshiListStore
    @State private var isFollowed: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            DemoAvatarImage(account: account, size: 50, emojiSize: 22)
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(account.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(.label))
                    
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#6C5CE7"))
                    
                    if oshi.isMutualFollow && store.showMutualBadge {
                        Text("相互")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#6C5CE7"), Color(hex: "#a29bfe")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                    }
                }
                
                Text("@\(account.handle)")
                    .font(.system(size: 12))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            
            Spacer()
            
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isFollowed.toggle()
                }
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            } label: {
                Text(isFollowed ? "フォロー中" : "フォロー")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isFollowed ? Color(.label) : .white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        Group {
                            if isFollowed {
                                Capsule()
                                    .stroke(Color(.separator), lineWidth: 1)
                            } else {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "#6C5CE7"), Color(hex: "#a29bfe")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                        }
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .onAppear {
            isFollowed = oshi.isFollowedByUser
        }
    }
}


// ============================================================
// MARK: - Demo Oshi List Settings View
// ============================================================

@available(iOS 17.0, *)
struct DemoOshiListSettingsView: View {
    @ObservedObject var store: DemoOshiListStore
    @StateObject private var accountStore = DemoSharedAccountStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: SettingsTab = .accounts
    @State private var showingAddOshi = false
    @State private var showResetAlert = false
    @State private var editingOshi: DemoOshiCharacter?
    
    @Environment(\.editMode) private var editMode
    
    enum SettingsTab: String, CaseIterable {
        case accounts = "アカウント"
        case display = "表示"
        case timing = "タイミング"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                settingsTabBar
                
                switch selectedTab {
                case .accounts:
                    accountListView
                case .display:
                    displaySettingsView
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

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if selectedTab == .accounts {
                        EditButton()
                    }

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
            .alert("初期データに戻しますか?", isPresented: $showResetAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("リセット", role: .destructive) {
                    withAnimation { store.resetToDefaults() }
                }
            } message: {
                Text("現在の設定がすべて削除され、サンプルデータに置き換わります。")
            }
            .sheet(isPresented: $showingAddOshi) {
                DemoAddOshiSheet(store: store)
            }
            .sheet(item: $editingOshi) { oshi in
                DemoEditOshiSheet(store: store, oshi: oshi)
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
                            
                            if tab == .accounts {
                                Text("\(store.oshis.count)")
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
                ForEach(store.oshis) { oshi in
                    if let account = store.account(for: oshi) {
                        HStack(spacing: 12) {
                            DemoAvatarImage(account: account, size: 40, emojiSize: 18)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 4) {
                                    Text(account.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Color(.label))
                                    
                                    if oshi.isMutualFollow {
                                        Text("相互")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 1)
                                            .background(Color(hex: "#6C5CE7"))
                                            .clipShape(Capsule())
                                    }
                                }
                                
                                HStack(spacing: 8) {
                                    Text("@\(account.handle)")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(.secondaryLabel))
                                    
                                    Text(oshi.relationshipLabel)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(Color(hex: "#6C5CE7"))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(Color(hex: "#6C5CE7").opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                            
                            Spacer()
                            
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    store.toggleVisibility(id: oshi.id)
                                }
                            } label: {
                                Image(systemName: oshi.isHidden ? "eye.slash.fill" : "eye.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(oshi.isHidden ? Color(.tertiaryLabel) : Color(hex: "#6C5CE7"))
                                    .frame(width: 32, height: 32)
                                    .background(
                                        oshi.isHidden
                                        ? Color(.tertiarySystemFill)
                                        : Color(hex: "#6C5CE7").opacity(0.1)
                                    )
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        .opacity(oshi.isHidden ? 0.5 : 1.0)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard editMode?.wrappedValue.isEditing != true else { return }
                            editingOshi = oshi
                        }
                    }
                }
                .onDelete { offsets in
                    store.removeOshi(at: offsets)
                }
                .onMove { source, dest in
                    store.moveOshi(from: source, to: dest)
                }
            } header: {
                HStack {
                    Text("登録済みアカウント")
                    Spacer()
                }
            } footer: {
                Text("タップで編集、左スワイプで削除、👁アイコンで表示切替。ドラッグで順序変更。")
            }
            
            Section {
                Button {
                    showingAddOshi = true
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
    
    // MARK: - Display Settings
    
    private var displaySettingsView: some View {
        List {
            Section {
                Toggle("相互フォローバッジを表示", isOn: $store.showMutualBadge)
                    .tint(Color(hex: "#6C5CE7"))
                    .onChange(of: store.showMutualBadge) { _, _ in store.save() }
                
                Toggle("入場アニメーション", isOn: $store.animateEntrance)
                    .tint(Color(hex: "#6C5CE7"))
                    .onChange(of: store.animateEntrance) { _, _ in store.save() }
            } header: {
                Text("表示オプション")
            } footer: {
                Text("入場アニメーションをOFFにすると、全アカウントが即座に表示されます。")
            }
            
            Section {
                HStack {
                    statBox(label: "フォロワー", count: store.followers.count, color: "#FF6B9D")
                    statBox(label: "フォロー中", count: store.following.count, color: "#4A90D9")
                    statBox(label: "相互", count: store.oshis.filter { $0.isMutualFollow && !$0.isHidden }.count, color: "#6C5CE7")
                }
            } header: {
                Text("統計")
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private func statBox(label: String, count: Int, color: String) -> some View {
        VStack(spacing: 6) {
            Text("\(count)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: color))
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Color(.secondaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(hex: color).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
                        Text(String(format: "%.1f 秒", store.defaultDisplayInterval))
                            .font(.system(size: 15, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color(hex: "#6C5CE7"))
                    }
                    Slider(value: $store.defaultDisplayInterval, in: 0.2...5.0, step: 0.2)
                        .tint(Color(hex: "#6C5CE7"))
                        .onChange(of: store.defaultDisplayInterval) { _, _ in store.save() }
                }
            } header: {
                Text("グローバル設定")
            } footer: {
                Text("入場アニメーション有効時、各アカウントの表示間隔のベースとなります。")
            }
            
            Section {
                ForEach(Array(store.oshis.enumerated()), id: \.element.id) { index, oshi in
                    if let account = store.account(for: oshi) {
                        DemoOshiTimingRow(oshi: oshi, account: account, index: index, store: store)
                    }
                }
            } header: {
                Text("アカウントごとの遅延")
            } footer: {
                Text("画面表示開始からこのアカウントが現れるまでの遅延時間です。")
            }
        }
        .listStyle(.insetGrouped)
    }
}


// ============================================================
// MARK: - Timing Row
// ============================================================

@available(iOS 17.0, *)
struct DemoOshiTimingRow: View {
    let oshi: DemoOshiCharacter
    let account: DemoAccount
    let index: Int
    @ObservedObject var store: DemoOshiListStore
    @State private var delay: Double = 1.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("\(index + 1)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(width: 22, height: 22)
                    .background(Color(hex: "#6C5CE7"))
                    .clipShape(Circle())
                
                Text(account.name)
                    .font(.system(size: 13, weight: .semibold))
                
                Text(oshi.relationshipLabel)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(hex: "#6C5CE7"))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Color(hex: "#6C5CE7").opacity(0.1))
                    .clipShape(Capsule())
            }
            
            HStack {
                Text("表示遅延")
                    .font(.system(size: 13))
                Spacer()
                Stepper(value: $delay, in: 0.2...30, step: 0.2) {
                    Text(String(format: "%.1f秒", delay))
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color(hex: "#6C5CE7"))
                }
                .onChange(of: delay) { _, newVal in
                    store.updateOshi(id: oshi.id) { $0.displayDelay = newVal }
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear { delay = oshi.displayDelay }
    }
}


// ============================================================
// MARK: - Add Oshi Sheet
// ============================================================

@available(iOS 17.0, *)
struct DemoAddOshiSheet: View {
    @ObservedObject var store: DemoOshiListStore
    @StateObject private var accountStore = DemoSharedAccountStore.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedAccountId = ""
    @State private var isFollowingUser = true
    @State private var isFollowedByUser = false
    @State private var displayDelay: Double = 1.0
    
    // DemoAddOshiSheet のプロパティに追加
    @State private var newAccountName: String = ""
    @State private var newAccountPhotoItem: PhotosPickerItem?
    @State private var newAccountAvatarBase64: String?
    @State private var newAccountAvatarUIImage: UIImage?
    
    @State private var showCropper = false
    @State private var rawPickedUIImage: UIImage?
    
    var canSave: Bool {
        !selectedAccountId.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("アカウント", selection: $selectedAccountId) {
                        if accountStore.accounts.isEmpty {
                            Text("アカウントがありません").tag("")
                        } else {
                            ForEach(accountStore.accounts) { account in
                                HStack {
                                    DemoAvatarImage(account: account, size: 24, emojiSize: 12)
                                    Text(account.name)
                                }
                                .tag(account.id)
                            }
                        }
                    }
                } header: {
                    Text("アカウント選択")
                } footer: {
                    Text("タイムラインデモと共有しているアカウントから選択できます")
                }
                
                Section {
                    HStack(spacing: 12) {
                        PhotosPicker(selection: $newAccountPhotoItem, matching: .images) {
                            ZStack {
                                if let uiImage = newAccountAvatarUIImage {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .font(.system(size: 22))
                                        .foregroundColor(Color(hex: "#6C5CE7"))
                                }
                            }
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                        }

                        TextField("名前（例：ゆきの）", text: $newAccountName)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        Button("作成") {
                            let created = accountStore.addAccount(
                                name: newAccountName,
                                avatarImageBase64: newAccountAvatarBase64
                            )
                            // 作成したアカウントをそのまま Picker の選択にする
                            selectedAccountId = created.id

                            // 入力をリセット
                            newAccountName = ""
                            newAccountPhotoItem = nil
                            newAccountAvatarBase64 = nil
                            newAccountAvatarUIImage = nil
                        }
                        .disabled(newAccountName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                } header: {
                    Text("新規アカウント作成")
                } footer: {
                    Text("ここで作成したアカウントはタイムライン側とも共有されます。")
                }
                
                Section {
                    Toggle("フォロワー(相手→自分)", isOn: $isFollowingUser)
                        .tint(Color(hex: "#6C5CE7"))
                    Toggle("フォロー中(自分→相手)", isOn: $isFollowedByUser)
                        .tint(Color(hex: "#6C5CE7"))
                    
                    if isFollowingUser && isFollowedByUser {
                        HStack {
                            Image(systemName: "arrow.left.arrow.right")
                                .foregroundColor(Color(hex: "#6C5CE7"))
                            Text("相互フォローになります")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#6C5CE7"))
                        }
                    }
                } header: {
                    Text("フォロー関係")
                } footer: {
                    Text("フォロワータブとフォロー中タブのどちらに表示するかを制御します。")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("表示遅延")
                            Spacer()
                            Text(String(format: "%.1f 秒", displayDelay))
                                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                                .foregroundColor(Color(hex: "#6C5CE7"))
                        }
                        Slider(value: $displayDelay, in: 0.2...30, step: 0.2)
                            .tint(Color(hex: "#6C5CE7"))
                    }
                } header: {
                    Text("表示タイミング")
                } footer: {
                    Text("入場アニメーション時にこのアカウントが表示されるまでの遅延時間")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("アカウント追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        let oshi = DemoOshiCharacter(
                            accountId: selectedAccountId,
                            isFollowingUser: isFollowingUser,
                            isFollowedByUser: isFollowedByUser,
                            displayDelay: displayDelay
                        )
                        store.addOshi(oshi)
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .disabled(!canSave)
                }
            }
            .onAppear {
                if let first = accountStore.accounts.first {
                    selectedAccountId = first.id
                }
            }
            .onChange(of: newAccountPhotoItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        await MainActor.run {
                            rawPickedUIImage = uiImage
                            showCropper = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showCropper) {
                if let raw = rawPickedUIImage {
                    ImageCropperSheet1(image: raw) { cropped in
                        // プレビュー表示用
                        newAccountAvatarUIImage = cropped
                        // 保存用Base64
                        let jpeg = cropped.jpegData(compressionQuality: 0.85)
                        newAccountAvatarBase64 = jpeg?.base64EncodedString()
                    }
                }
            }
        }
    }
}

struct ImageCropperSheet1: View {
    let image: UIImage
    let onCropped: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let size = geo.size
                let cropSide = min(size.width, size.height) * 0.78
                let cropRect = CGRect(
                    x: (size.width - cropSide) / 2,
                    y: (size.height - cropSide) / 2,
                    width: cropSide,
                    height: cropSide
                )

                ZStack {
                    Color.black.ignoresSafeArea()

                    // 画像
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .frame(width: size.width, height: size.height)
                        .gesture(
                            DragGesture()
                                .onChanged { v in
                                    offset = CGSize(
                                        width: lastOffset.width + v.translation.width,
                                        height: lastOffset.height + v.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .gesture(
                            MagnificationGesture()
                                .onChanged { v in
                                    scale = max(1.0, min(4.0, lastScale * v))
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                }
                        )

                    // マスク（暗幕＋クロップ枠）
                    CropMaskView(cropRect: cropRect)
                        .allowsHitTesting(false)
                }
                .overlay(alignment: .center) {
                    // クロップ枠の線
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.9), lineWidth: 2)
                        .frame(width: cropSide, height: cropSide)
                        .allowsHitTesting(false)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("キャンセル") { dismiss() }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("完了") {
                            let cropped = crop(
                                image: image,
                                in: cropRect,
                                viewSize: size,
                                scale: scale,
                                offset: offset
                            )
                            onCropped(cropped)
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    // 画像を「画面座標 → 画像座標」に変換して正方形で切り抜く
    private func crop(
        image: UIImage,
        in cropRect: CGRect,
        viewSize: CGSize,
        scale: CGFloat,
        offset: CGSize
    ) -> UIImage {
        // まず「scaledToFit」の表示サイズを計算
        let imgSize = image.size
        let fitScale = min(viewSize.width / imgSize.width, viewSize.height / imgSize.height)
        let displayedSize = CGSize(width: imgSize.width * fitScale, height: imgSize.height * fitScale)

        // 画像が画面の中央に配置される前提の原点（画像の左上）
        let imageOrigin = CGPoint(
            x: (viewSize.width - displayedSize.width) / 2,
            y: (viewSize.height - displayedSize.height) / 2
        )

        // ユーザー操作後（scale + offset）を反映した「画面上の画像領域」
        // scale は表示に対する追加倍率なので、表示サイズも増える
        let scaledDisplayedSize = CGSize(width: displayedSize.width * scale, height: displayedSize.height * scale)
        let scaledOrigin = CGPoint(
            x: imageOrigin.x + offset.width - (scaledDisplayedSize.width - displayedSize.width) / 2,
            y: imageOrigin.y + offset.height - (scaledDisplayedSize.height - displayedSize.height) / 2
        )

        // cropRect を「画像ピクセル座標」に戻す
        let xInScaled = cropRect.minX - scaledOrigin.x
        let yInScaled = cropRect.minY - scaledOrigin.y

        let pxPerPoint = imgSize.width / (scaledDisplayedSize.width)
        var cropPx = CGRect(
            x: xInScaled * pxPerPoint,
            y: yInScaled * pxPerPoint,
            width: cropRect.width * pxPerPoint,
            height: cropRect.height * pxPerPoint
        )

        // はみ出し補正
        cropPx = cropPx.intersection(CGRect(origin: .zero, size: imgSize))
        guard let cg = image.cgImage?.cropping(to: cropPx) else { return image }
        return UIImage(cgImage: cg, scale: image.scale, orientation: image.imageOrientation)
    }
}

// 追加：暗幕マスク（クロップ部分だけ穴を開ける）
struct CropMaskView: View {
    let cropRect: CGRect
    var body: some View {
        GeometryReader { _ in
            Canvas { ctx, size in
                var path = Path()
                path.addRect(CGRect(origin: .zero, size: size))
                path.addRoundedRect(in: cropRect, cornerSize: CGSize(width: 14, height: 14))
                ctx.fill(path, with: .color(.black.opacity(0.55)), style: FillStyle(eoFill: true))
            }
        }
    }
}


// ============================================================
// MARK: - Edit Oshi Sheet
// ============================================================

@available(iOS 17.0, *)
struct DemoEditOshiSheet: View {
    @ObservedObject var store: DemoOshiListStore
    let oshi: DemoOshiCharacter
    @Environment(\.dismiss) private var dismiss
    
    @State private var isFollowingUser: Bool
    @State private var isFollowedByUser: Bool
    @State private var displayDelay: Double
    
    init(store: DemoOshiListStore, oshi: DemoOshiCharacter) {
        self.store = store
        self.oshi = oshi
        _isFollowingUser = State(initialValue: oshi.isFollowingUser)
        _isFollowedByUser = State(initialValue: oshi.isFollowedByUser)
        _displayDelay = State(initialValue: oshi.displayDelay)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if let account = store.account(for: oshi) {
                    Section {
                        HStack {
                            DemoAvatarImage(account: account, size: 50, emojiSize: 22)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(account.name)
                                    .font(.system(size: 16, weight: .semibold))
                                Text("@\(account.handle)")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(.secondaryLabel))
                            }
                        }
                    } header: {
                        Text("アカウント情報")
                    }
                }
                
                Section {
                    Toggle("フォロワー(相手→自分)", isOn: $isFollowingUser)
                        .tint(Color(hex: "#6C5CE7"))
                    Toggle("フォロー中(自分→相手)", isOn: $isFollowedByUser)
                        .tint(Color(hex: "#6C5CE7"))
                    
                    if isFollowingUser && isFollowedByUser {
                        HStack {
                            Image(systemName: "arrow.left.arrow.right")
                                .foregroundColor(Color(hex: "#6C5CE7"))
                            Text("相互フォローになります")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#6C5CE7"))
                        }
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("表示遅延")
                            Spacer()
                            Text(String(format: "%.1f 秒", displayDelay))
                                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                                .foregroundColor(Color(hex: "#6C5CE7"))
                        }
                        Slider(value: $displayDelay, in: 0.2...30, step: 0.2)
                            .tint(Color(hex: "#6C5CE7"))
                    }
                } header: {
                    Text("表示タイミング")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("アカウント編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        store.updateOshi(id: oshi.id) { o in
                            o.isFollowingUser = isFollowingUser
                            o.isFollowedByUser = isFollowedByUser
                            o.displayDelay = displayDelay
                        }
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                }
            }
        }
    }
}


// ============================================================
// MARK: - Previews
// ============================================================

#Preview("Demo Oshi List") {
    if #available(iOS 17.0, *) {
        DemoOshiListView()
    }
}

#Preview("Demo Oshi Settings") {
    if #available(iOS 17.0, *) {
        DemoOshiListSettingsView(store: DemoOshiListStore.shared)
    }
}

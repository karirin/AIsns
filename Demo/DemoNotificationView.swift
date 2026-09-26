//
//  DemoNotificationView.swift
//  AIsns
//
//  Created by Apple on 2026/02/08.
//

import SwiftUI

// ============================================================
// MARK: - Demo Notification Models
// ============================================================

struct DemoNotification: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var type: DemoNotificationType
    var senderAccountId: String
    var targetAccountId: String? // 通知対象のアカウント (作成したAI用)
    var relatedPostId: String?
    var message: String
    var timestamp: Date
    var isRead: Bool = false
    var displayDelay: Double = 1.0 // 前の通知からの表示遅延
    
    static let samples: [DemoNotification] = [
        // 自分への通知
        DemoNotification(type: .reaction, senderAccountId: "acc_1", message: "ゆきのさんがあなたの投稿をいいねしました", timestamp: Date().addingTimeInterval(-300), displayDelay: 0.5),
        DemoNotification(type: .reaction, senderAccountId: "acc_2", message: "そうたさんがあなたの投稿をいいねしました", timestamp: Date().addingTimeInterval(-250), displayDelay: 1.0),
        DemoNotification(type: .comment, senderAccountId: "acc_3", message: "あかりさんがあなたの投稿にコメントしました", timestamp: Date().addingTimeInterval(-600), displayDelay: 1.2),
        DemoNotification(type: .follow, senderAccountId: "acc_4", message: "れんさんがあなたをフォローしました", timestamp: Date().addingTimeInterval(-1800), displayDelay: 0.8),
        
        // 作成したAIへの通知 (例: ユーザーが "acc_5" というAIを作成した設定)
        DemoNotification(type: .reaction, senderAccountId: "acc_1", targetAccountId: "acc_5", message: "ゆきのさんがみおの投稿をいいねしました", timestamp: Date().addingTimeInterval(-400), displayDelay: 0.7),
        DemoNotification(type: .follow, senderAccountId: "acc_2", targetAccountId: "acc_5", message: "そうたさんがみおをフォローしました", timestamp: Date().addingTimeInterval(-900), displayDelay: 1.5),
    ]
}

enum DemoNotificationType: String, Codable, CaseIterable, Hashable {
    case reaction = "いいね"
    case comment = "コメント"
    case follow = "フォロー"
    
    var canGroup: Bool {
        switch self {
        case .reaction, .comment, .follow:
            return true
        }
    }
    
    var icon: String {
        switch self {
        case .reaction: return "heart.fill"
        case .comment: return "bubble.left.fill"
        case .follow: return "person.fill.badge.plus"
        }
    }
    
    var color: Color {
        switch self {
        case .reaction: return Color(hex: "#FF3B6E")
        case .comment: return Color(hex: "#6C5CE7")
        case .follow: return Color(hex: "#2ECC71")
        }
    }
}

enum DemoNotificationCategory: String, CaseIterable {
    case me = "あなたへの通知"
    case createdAI = "作成したAI"
}

// ============================================================
// MARK: - Demo Grouped Notification
// ============================================================

struct DemoGroupedNotification: Identifiable {
    var id: String {
        notifications.first?.id ?? UUID().uuidString
    }
    
    let type: DemoNotificationType
    let category: DemoNotificationCategory
    let relatedPostId: String?
    let targetAccountId: String? // グループ化のキー
    let notifications: [DemoNotification]
    let timestamp: Date
    
    var isRead: Bool {
        notifications.allSatisfy { $0.isRead }
    }
    
    var displayMessage: String {
        let count = notifications.count
        guard let first = notifications.first else { return "" }
        
        let firstSenderName = DemoSharedAccountStore.shared.account(for: first.senderAccountId)?.name ?? "誰か"
        
        if count == 1 {
            return first.message
        }
        
        // グループ化メッセージ
        let secondSenderName = notifications.count > 1
            ? (DemoSharedAccountStore.shared.account(for: notifications[1].senderAccountId)?.name ?? "誰か")
            : ""
        
        switch type {
        case .reaction:
            if count == 2 {
                return "\(firstSenderName)と\(secondSenderName)があなたの投稿をいいねしました"
            } else {
                return "\(firstSenderName)と他\(count - 1)人があなたの投稿をいいねしました"
            }
        case .comment:
            if count == 2 {
                return "\(firstSenderName)と\(secondSenderName)があなたの投稿にコメントしました"
            } else {
                return "\(firstSenderName)と他\(count - 1)人があなたの投稿にコメントしました"
            }
        case .follow:
            if let targetId = targetAccountId,
               let targetName = DemoSharedAccountStore.shared.account(for: targetId)?.name {
                // 作成したAIへのフォロー
                if count == 2 {
                    return "\(firstSenderName)と\(secondSenderName)が\(targetName)をフォローしました"
                } else {
                    return "\(firstSenderName)と他\(count - 1)人が\(targetName)をフォローしました"
                }
            } else {
                // 自分へのフォロー
                if count == 2 {
                    return "\(firstSenderName)と\(secondSenderName)があなたをフォローしました"
                } else {
                    return "\(firstSenderName)と他\(count - 1)人があなたをフォローしました"
                }
            }
        }
    }
}

// ============================================================
// MARK: - Demo Notification Data Store
// ============================================================

class DemoNotificationStore: ObservableObject {
    static let shared = DemoNotificationStore()
    
    @Published var notifications: [DemoNotification] = []
    @Published var defaultNotificationInterval: Double = 1.0
    
    private let notificationsKey = "demo_notifications_v1"
    private let intervalKey = "demo_notification_interval"
    
    init() {
        loadData()
    }
    
    // MARK: - Load & Save
    
    func loadData() {
        if let data = UserDefaults.standard.data(forKey: notificationsKey),
           let decoded = try? JSONDecoder().decode([DemoNotification].self, from: data) {
            notifications = decoded
        } else {
            notifications = DemoNotification.samples
        }
        
        let saved = UserDefaults.standard.double(forKey: intervalKey)
        defaultNotificationInterval = saved > 0 ? saved : 1.0
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(notifications) {
            UserDefaults.standard.set(data, forKey: notificationsKey)
        }
        UserDefaults.standard.set(defaultNotificationInterval, forKey: intervalKey)
    }
    
    // MARK: - CRUD
    
    func addNotification(_ notification: DemoNotification) {
        notifications.insert(notification, at: 0)
        save()
    }
    
    func removeNotification(id: String) {
        notifications.removeAll { $0.id == id }
        save()
    }
    
    func markAsRead(id: String) {
        if let index = notifications.firstIndex(where: { $0.id == id }) {
            notifications[index].isRead = true
            save()
        }
    }
    
    func markAllAsRead() {
        for i in notifications.indices {
            notifications[i].isRead = true
        }
        save()
    }
    
    func clearAll() {
        notifications.removeAll()
        save()
    }
    
    func resetToDefaults() {
        notifications = DemoNotification.samples
        defaultNotificationInterval = 1.0
        save()
    }
    
    // MARK: - Grouping Logic
    
    func groupedNotifications(for category: DemoNotificationCategory) -> [DemoGroupedNotification] {
        var groups: [DemoGroupedNotification] = []
        var processed: Set<String> = []
        
        // カテゴリでフィルタリング
        let filtered = notifications.filter { notification in
            if category == .me {
                return notification.targetAccountId == nil
            } else {
                return notification.targetAccountId != nil
            }
        }
        
        let sorted = filtered.sorted { $0.timestamp > $1.timestamp }
        
        for notification in sorted {
            guard !processed.contains(notification.id) else { continue }
            
            if notification.type.canGroup {
                let related = sorted.filter { item in
                    let isSameType = item.type == notification.type
                    let isSamePost = item.relatedPostId == notification.relatedPostId
                    let isSameTarget = item.targetAccountId == notification.targetAccountId
                    let isNotProcessed = !processed.contains(item.id)
                    
                    if notification.type == .follow {
                        return isSameType && isSameTarget && isNotProcessed
                    } else if notification.relatedPostId != nil {
                        return isSameType && isSamePost && isNotProcessed
                    } else {
                        return false
                    }
                }
                
                if !related.isEmpty {
                    let group = DemoGroupedNotification(
                        type: notification.type,
                        category: category,
                        relatedPostId: notification.relatedPostId,
                        targetAccountId: notification.targetAccountId,
                        notifications: related,
                        timestamp: related.map { $0.timestamp }.max() ?? notification.timestamp
                    )
                    groups.append(group)
                    related.forEach { processed.insert($0.id) }
                } else {
                    let group = DemoGroupedNotification(
                        type: notification.type,
                        category: category,
                        relatedPostId: notification.relatedPostId,
                        targetAccountId: notification.targetAccountId,
                        notifications: [notification],
                        timestamp: notification.timestamp
                    )
                    groups.append(group)
                    processed.insert(notification.id)
                }
            } else {
                let group = DemoGroupedNotification(
                    type: notification.type,
                    category: category,
                    relatedPostId: notification.relatedPostId,
                    targetAccountId: notification.targetAccountId,
                    notifications: [notification],
                    timestamp: notification.timestamp
                )
                groups.append(group)
                processed.insert(notification.id)
            }
        }
        
        return groups.sorted { $0.timestamp > $1.timestamp }
    }
}

// ============================================================
// MARK: - Demo Notification View
// ============================================================

@available(iOS 17.0, *)
struct DemoNotificationView: View {
    @StateObject private var store = DemoNotificationStore.shared
    @State private var selectedCategory: DemoNotificationCategory = .me
    @State private var showingSettings = false
    @Namespace private var tabNamespace
    
    @State private var visibleNotificationIds: Set<String> = []
    @State private var feedTask: Task<Void, Never>?
    
    var groupedNotifications: [DemoGroupedNotification] {
        store.groupedNotifications(for: selectedCategory)
    }
    
    var visibleGroups: [DemoGroupedNotification] {
        groupedNotifications.filter { group in
            group.notifications.contains { visibleNotificationIds.contains($0.id) }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                tabBarView
                
                if groupedNotifications.isEmpty {
                    emptyView
                } else if visibleGroups.isEmpty {
                    loadingView
                } else {
                    notificationList
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("通知")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingSettings = true
                        } label: {
                            Label("設定", systemImage: "gear")
                        }
                        
                        Button {
                            withAnimation {
                                store.markAllAsRead()
                            }
                        } label: {
                            Label("すべて既読にする", systemImage: "checkmark.circle")
                        }
                        
                        Button(role: .destructive) {
                            withAnimation {
                                store.clearAll()
                            }
                        } label: {
                            Label("すべて削除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(Color(.label))
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                DemoNotificationSettingsView(store: store)
            }
            .onAppear { startFeed() }
            .onDisappear { stopFeed() }
            .onChange(of: selectedCategory) { _, _ in restartFeed() }
            .onChange(of: store.notifications) { _, _ in restartFeed() }
        }
    }
    
    // MARK: - Tab Bar
    
    private var tabBarView: some View {
        HStack(spacing: 0) {
            ForEach(DemoNotificationCategory.allCases, id: \.self) { category in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedCategory = category
                    }
                } label: {
                    VStack(spacing: 8) {
                        Text(category.rawValue)
                            .font(.system(size: 14, weight: selectedCategory == category ? .semibold : .regular))
                            .foregroundColor(selectedCategory == category ? Color(.label) : Color(.secondaryLabel))
                        
                        ZStack {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 3)
                            
                            if selectedCategory == category {
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "#6C5CE7"), Color(hex: "#a29bfe")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: 48, height: 3)
                                    .matchedGeometryEffect(id: "demoNotificationTab", in: tabNamespace)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .background(Color(.systemBackground))
        .overlay(Divider(), alignment: .bottom)
    }
    
    // MARK: - Notification List
    
    private var notificationList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(visibleGroups) { group in
                    DemoGroupedNotificationRow(group: group, store: store)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .opacity
                            )
                        )
                    
                    Divider()
                        .padding(.leading, 68)
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Empty States
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("通知を読み込み中...")
                .font(.system(size: 15))
                .foregroundColor(Color(.secondaryLabel))
            Spacer()
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bell.slash")
                .font(.system(size: 48))
                .foregroundColor(Color(.tertiaryLabel))
            Text("通知はありません")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(.label))
            Text(selectedCategory == .me ? "フォロワーからの通知が\nここに表示されます" : "作成したAIへの反応が\nここに表示されます")
                .font(.system(size: 14))
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
    
    // MARK: - Feed Control
    
    private func startFeed() {
        visibleNotificationIds = []
        
        feedTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            let notifications = groupedNotifications.flatMap { $0.notifications }
            
            for notification in notifications {
                guard !Task.isCancelled else { return }
                
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    visibleNotificationIds.insert(notification.id)
                }
                
                let delay = notification.displayDelay
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
}

// ============================================================
// MARK: - Demo Grouped Notification Row
// ============================================================

struct DemoGroupedNotificationRow: View {
    let group: DemoGroupedNotification
    @ObservedObject var store: DemoNotificationStore
    
    private let maxAvatarsToShow = 5
    
    var senderAccounts: [DemoAccount] {
        group.notifications.compactMap { notification in
            DemoSharedAccountStore.shared.account(for: notification.senderAccountId)
        }
    }
    
    // ✅ 通知タイプのバッジ（アバターに重ねる）
    private var typeBadgeView: some View {
        ZStack {
            Circle()
                .fill(group.type.color)
                .frame(width: 16, height: 16)
            
            Image(systemName: group.type.icon)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
        }
        .overlay(
            Circle().stroke(Color(.systemBackground), lineWidth: 1.5)
        )
    }
    
    var body: some View {
        Button {
            markAsRead()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                // アイコン
                Image(systemName: group.type.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(group.type.color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 8) {
                    // 複数アバター表示
                    if group.notifications.count > 1 {
                        multipleAvatarsView
                    }
                    
                    // 単一アバター + メッセージ
                    if group.notifications.count == 1 {
                        HStack(spacing: 12) {
                            if let account = senderAccounts.first {
                                DemoAvatarImage(account: account, size: 40, emojiSize: 18)
                                    .overlay(alignment: .bottomTrailing) {
                                        typeBadgeView
                                            .offset(x: 2, y: 2)
                                    }
                            }
                            Text(group.displayMessage)
                                .font(.system(size: 14))
                                .foregroundColor(Color(.label))
                                .lineLimit(2)
                        }
                    } else {
                        Text(group.displayMessage)
                            .font(.system(size: 14))
                            .foregroundColor(Color(.label))
                            .lineLimit(2)
                    }
                    
                    // 投稿プレビュー（もしあれば）
                    if let postId = group.relatedPostId {
                        postPreview(postId: postId)
                    }
                    
                    // タイムスタンプ
                    Text(relativeTime(from: group.timestamp))
                        .font(.system(size: 12))
                        .foregroundColor(Color(.tertiaryLabel))
                }
                
                Spacer()
                
                // 未読バッジ
                if !group.isRead {
                    Circle()
                        .fill(Color(hex: "#6C5CE7"))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(group.isRead ? Color(.systemBackground) : Color(hex: "#6C5CE7").opacity(0.03))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Multiple Avatars
    
    private var multipleAvatarsView: some View {
        HStack(spacing: -8) {
            let displayAccounts = Array(senderAccounts.prefix(maxAvatarsToShow))
            let totalCount = senderAccounts.count
            
            ForEach(Array(displayAccounts.enumerated()), id: \.element.id) { index, account in
                DemoAvatarImage(account: account, size: 36, emojiSize: 16)
                    .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
                    .overlay(alignment: .bottomTrailing) {
                        typeBadgeView
                            .offset(x: 2, y: 2)
                    }
                    .zIndex(Double(displayAccounts.count - index))
            }
            
            if totalCount > maxAvatarsToShow {
                Text("+\(totalCount - maxAvatarsToShow)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(.secondaryLabel))
                    .padding(.leading, 8)
            }
        }
        .padding(.bottom, 4)
    }
    
    // MARK: - Post Preview
    
    private func postPreview(postId: String) -> some View {
        Text("投稿のプレビュー（postId: \(postId)）")
            .font(.system(size: 13))
            .foregroundColor(Color(.secondaryLabel))
            .lineLimit(2)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.tertiarySystemFill))
            .cornerRadius(8)
    }
    
    // MARK: - Helpers
    
    private func markAsRead() {
        for notification in group.notifications {
            store.markAsRead(id: notification.id)
        }
    }
    
    private func relativeTime(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "たった今"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)分前"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)時間前"
        } else {
            let days = Int(interval / 86400)
            return "\(days)日前"
        }
    }
}

// ============================================================
// MARK: - Demo Notification Settings View
// ============================================================

@available(iOS 17.0, *)
struct DemoNotificationSettingsView: View {
    @ObservedObject var store: DemoNotificationStore
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddNotification = false
    @State private var showResetAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("通知表示間隔")
                                .font(.system(size: 15))
                            Spacer()
                            Text(String(format: "%.1f 秒", store.defaultNotificationInterval))
                                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                                .foregroundColor(Color(hex: "#6C5CE7"))
                        }
                        Slider(value: $store.defaultNotificationInterval, in: 0.5...5, step: 0.5)
                            .tint(Color(hex: "#6C5CE7"))
                            .onChange(of: store.defaultNotificationInterval) { _, _ in
                                store.save()
                            }
                    }
                } header: {
                    Text("タイミング設定")
                } footer: {
                    Text("各通知が順番に表示される間隔を設定します")
                }
                
                Section {
                    ForEach(store.notifications) { notification in
                        DemoNotificationSettingRow(notification: notification, store: store)
                    }
                    .onDelete { offsets in
                        let ids = offsets.map { store.notifications[$0].id }
                        ids.forEach { store.removeNotification(id: $0) }
                    }
                } header: {
                    HStack {
                        Text("登録済み通知")
                        Spacer()
                        EditButton()
                            .font(.system(size: 13))
                    }
                } footer: {
                    Text("左スワイプで削除できます")
                }
                
                Section {
                    Button {
                        showingAddNotification = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: "#6C5CE7"))
                            Text("通知を追加")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(hex: "#6C5CE7"))
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("通知デモ設定")
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
            .alert("初期データに戻しますか?", isPresented: $showResetAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("リセット", role: .destructive) {
                    withAnimation { store.resetToDefaults() }
                }
            }
            .sheet(isPresented: $showingAddNotification) {
                AddDemoNotificationSheet(store: store)
            }
        }
    }
}

// MARK: - Notification Setting Row

@available(iOS 17.0, *)
struct DemoNotificationSettingRow: View {
    let notification: DemoNotification
    @ObservedObject var store: DemoNotificationStore
    @State private var delay: Double = 1.0
    
    var senderAccount: DemoAccount? {
        DemoSharedAccountStore.shared.account(for: notification.senderAccountId)
    }
    
    // ✅ 設定画面用の小さめバッジ
    private var settingBadgeView: some View {
        ZStack {
            Circle()
                .fill(notification.type.color)
                .frame(width: 14, height: 14)
            
            Image(systemName: notification.type.icon)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
        }
        .overlay(
            Circle().stroke(Color(.systemBackground), lineWidth: 1.5)
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                // ✅ 共通アカウントのアバター（DemoSharedAccountStore）
                if let account = senderAccount {
                    DemoAvatarImage(account: account, size: 28, emojiSize: 12)
                        .overlay(alignment: .bottomTrailing) {
                            settingBadgeView
                                .offset(x: 2, y: 2)
                        }
                }
                
                Image(systemName: notification.type.icon)
                    .font(.system(size: 12))
                    .foregroundColor(notification.type.color)
                
                if let account = senderAccount {
                    Text(account.name)
                        .font(.system(size: 13, weight: .semibold))
                }
                
                Text(notification.message)
                    .font(.system(size: 12))
                    .foregroundColor(Color(.secondaryLabel))
                    .lineLimit(1)
            }
            
            HStack {
                Text("表示遅延")
                    .font(.system(size: 13))
                    .foregroundColor(Color(.secondaryLabel))
                
                Spacer()
                
                Stepper(value: $delay, in: 0.5...10, step: 0.5) {
                    Text(String(format: "%.1f秒", delay))
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color(hex: "#6C5CE7"))
                }
                .onChange(of: delay) { _, newVal in
                    if let index = store.notifications.firstIndex(where: { $0.id == notification.id }) {
                        store.notifications[index].displayDelay = newVal
                        store.save()
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            delay = notification.displayDelay
        }
    }
}

// ============================================================
// MARK: - Add Notification Sheet
// ============================================================

struct AddDemoNotificationSheet: View {
    @ObservedObject var store: DemoNotificationStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedType: DemoNotificationType = .reaction
    @State private var selectedSenderId = ""
    @State private var selectedCategory: DemoNotificationCategory = .me
    @State private var selectedTargetId = ""
    @State private var customDelay: Double = 1.0
    
    var canSave: Bool {
        !selectedSenderId.isEmpty && (selectedCategory == .me || !selectedTargetId.isEmpty)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("通知タイプ", selection: $selectedType) {
                        ForEach(DemoNotificationType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("通知の種類")
                }
                
                Section {
                    Picker("カテゴリ", selection: $selectedCategory) {
                        ForEach(DemoNotificationCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                } header: {
                    Text("通知先")
                }
                
                Section {
                    Picker("送信者", selection: $selectedSenderId) {
                        ForEach(DemoSharedAccountStore.shared.accounts.filter { !$0.isHidden }) { account in
                            Text(account.name).tag(account.id)
                        }
                    }
                } header: {
                    Text("誰から")
                }
                
                if selectedCategory == .createdAI {
                    Section {
                        Picker("対象AI", selection: $selectedTargetId) {
                            ForEach(DemoSharedAccountStore.shared.accounts.filter { !$0.isHidden }) { account in
                                Text(account.name).tag(account.id)
                            }
                        }
                    } header: {
                        Text("どのAIへ")
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("表示遅延")
                            Spacer()
                            Text(String(format: "%.1f 秒", customDelay))
                                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                                .foregroundColor(Color(hex: "#6C5CE7"))
                        }
                        Slider(value: $customDelay, in: 0.5...10, step: 0.5)
                            .tint(Color(hex: "#6C5CE7"))
                    }
                } header: {
                    Text("タイミング")
                }
            }
            .navigationTitle("通知を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        let message = generateMessage()
                        let notification = DemoNotification(
                            type: selectedType,
                            senderAccountId: selectedSenderId,
                            targetAccountId: selectedCategory == .createdAI ? selectedTargetId : nil,
                            message: message,
                            timestamp: Date(),
                            displayDelay: customDelay
                        )
                        store.addNotification(notification)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                if let first = DemoSharedAccountStore.shared.accounts.first(where: { !$0.isHidden }) {
                    selectedSenderId = first.id
                    selectedTargetId = first.id
                }
            }
        }
    }
    
    private func generateMessage() -> String {
        let senderName = DemoSharedAccountStore.shared.account(for: selectedSenderId)?.name ?? "誰か"
        
        if selectedCategory == .createdAI {
            let targetName = DemoSharedAccountStore.shared.account(for: selectedTargetId)?.name ?? "AI"
            switch selectedType {
            case .reaction:
                return "\(senderName)さんが\(targetName)の投稿をいいねしました"
            case .comment:
                return "\(senderName)さんが\(targetName)の投稿にコメントしました"
            case .follow:
                return "\(senderName)さんが\(targetName)をフォローしました"
            }
        } else {
            switch selectedType {
            case .reaction:
                return "\(senderName)さんがあなたの投稿をいいねしました"
            case .comment:
                return "\(senderName)さんがあなたの投稿にコメントしました"
            case .follow:
                return "\(senderName)さんがあなたをフォローしました"
            }
        }
    }
}

// ============================================================
// MARK: - Previews
// ============================================================

#Preview("Notification View") {
    if #available(iOS 17.0, *) {
        DemoNotificationView()
    }
}

#Preview("Settings") {
    if #available(iOS 17.0, *) {
        DemoNotificationSettingsView(store: DemoNotificationStore.shared)
    }
}

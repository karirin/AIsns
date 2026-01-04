//
//  NotificationView.swift
//  AIsns
//
//  Updated: 2026/01/02 - Complete UI/UX Redesign
//

import SwiftUI

// MARK: - Grouped Notification Model

struct GroupedNotification: Identifiable {
    var id: UUID {
        notifications.first?.id ?? UUID()
    }

    let type: NotificationType
    let category: NotificationCategory
    let relatedPostId: UUID?
    let notifications: [AppNotification]
    let timestamp: Date
    
    var isRead: Bool {
        notifications.allSatisfy { $0.isRead }
    }
    
    var senderNames: [String] {
        notifications.map { $0.senderName }
    }
    
    var senderIds: [UUID] {
        notifications.map { $0.senderId }
    }
    
    var displayMessage: String {
        let count = notifications.count
        let firstSender = notifications.first?.senderName ?? ""
        let targetOshiName = notifications.first?.targetOshiName ?? "あなたのAI"
        
        // メッセージ生成ロジック
        if category == .createdOshi {
             // 作成したAI宛ての通知
             if count == 1 {
                 return notifications.first?.message ?? ""
             }
             
             switch type {
             case .reaction:
                 if count == 2 {
                     let secondSender = notifications[1].senderName
                     return "\(firstSender)と\(secondSender)が\(targetOshiName)の投稿をいいねしました"
                 } else {
                     return "\(firstSender)と他\(count - 1)人が\(targetOshiName)の投稿をいいねしました"
                 }
             case .comment:
                 if count == 2 {
                     let secondSender = notifications[1].senderName
                     return "\(firstSender)と\(secondSender)が\(targetOshiName)の投稿にコメントしました"
                 } else {
                     return "\(firstSender)と他\(count - 1)人が\(targetOshiName)の投稿にコメントしました"
                 }
             case .follow:
                 if count == 2 {
                     let secondSender = notifications[1].senderName
                     return "\(firstSender)と\(secondSender)が\(targetOshiName)をフォローしました"
                 } else {
                     return "\(firstSender)と他\(count - 1)人が\(targetOshiName)をフォローしました"
                 }
             default:
                 return notifications.first?.message ?? ""
             }
             
        } else {
            // 自分宛ての通知
            if count == 1 {
                return notifications.first?.message ?? ""
            }
            
            switch type {
            case .reaction:
                if count == 2 {
                    let secondSender = notifications[1].senderName
                    return "\(firstSender)と\(secondSender)があなたの投稿をいいねしました"
                } else {
                    return "\(firstSender)と他\(count - 1)人があなたの投稿をいいねしました"
                }
            case .comment:
                if count == 2 {
                    let secondSender = notifications[1].senderName
                    return "\(firstSender)と\(secondSender)があなたの投稿にコメントしました"
                } else {
                    return "\(firstSender)と他\(count - 1)人があなたの投稿にコメントしました"
                }
            case .follow:
                if count == 2 {
                    let secondSender = notifications[1].senderName
                    return "\(firstSender)と\(secondSender)があなたをフォローしました"
                } else {
                    return "\(firstSender)と他\(count - 1)人があなたをフォローしました"
                }
            default:
                return notifications.first?.message ?? ""
            }
        }
    }
}

// MARK: - Notification View

struct NotificationView: View {
    @ObservedObject var viewModel: OshiViewModel
    @Binding var isPresented: Bool
    @Environment(\.dismiss) var dismiss
    @Namespace private var tabNamespace
    
    // タブ選択用
    @State private var selectedCategory: NotificationCategory = .me
    
    var groupedNotifications: [GroupedNotification] {
        var groups: [GroupedNotification] = []
        var processed: Set<UUID> = []
        
        // 1. カテゴリでフィルタリング
        // (.chat の除外フィルタは NotificationType から削除されたため不要になり削除しました)
        let notifications = viewModel.notifications.filter {
            $0.category == selectedCategory
        }
        
        // 2. 日付順にソート (処理用)
        let sortedNotifications = notifications.sorted(by: { $0.timestamp > $1.timestamp })
        
        for notification in sortedNotifications {
            // すでに処理済みの通知はスキップ
            guard !processed.contains(notification.id) else { continue }
            
            if notification.type.canGroup {
                if notification.type == .follow {
                    // フォローの場合: 同じターゲット（自分 or 同じ推し）へのフォローをまとめる
                    let targetName = notification.targetOshiName
                    
                    // コンパイラのエラー回避のため、条件を明示的に分割
                    let relatedNotifications = sortedNotifications.filter { item in
                        let isSameType = (item.type == .follow)
                        let isSameTarget = (item.targetOshiName == targetName)
                        let isNotProcessed = !processed.contains(item.id)
                        return isSameType && isSameTarget && isNotProcessed
                    }
                    
                    let group = GroupedNotification(
                        type: .follow,
                        category: notification.category,
                        relatedPostId: nil,
                        notifications: relatedNotifications,
                        timestamp: relatedNotifications.map { $0.timestamp }.max() ?? notification.timestamp
                    )
                    
                    groups.append(group)
                    relatedNotifications.forEach { processed.insert($0.id) }
                    
                } else if let postId = notification.relatedPostId {
                    // 投稿関連（いいね、コメント）: 同じPostIDでまとめる
                    let currentType = notification.type
                    
                    // コンパイラのエラー回避のため、条件を明示的に分割
                    let relatedNotifications = sortedNotifications.filter { item in
                        let isSameType = (item.type == currentType)
                        let isSamePost = (item.relatedPostId == postId)
                        let isNotProcessed = !processed.contains(item.id)
                        return isSameType && isSamePost && isNotProcessed
                    }
                    
                    let group = GroupedNotification(
                        type: notification.type,
                        category: notification.category,
                        relatedPostId: postId,
                        notifications: relatedNotifications,
                        timestamp: relatedNotifications.map { $0.timestamp }.max() ?? notification.timestamp
                    )
                    
                    groups.append(group)
                    relatedNotifications.forEach { processed.insert($0.id) }
                    
                } else {
                    let group = GroupedNotification(
                        type: notification.type,
                        category: notification.category,
                        relatedPostId: notification.relatedPostId,
                        notifications: [notification],
                        timestamp: notification.timestamp
                    )
                    groups.append(group)
                    processed.insert(notification.id)
                }
                
            } else {
                let group = GroupedNotification(
                    type: notification.type,
                    category: notification.category,
                    relatedPostId: notification.relatedPostId,
                    notifications: [notification],
                    timestamp: notification.timestamp
                )
                
                groups.append(group)
                processed.insert(notification.id)
            }
        }
        
        return groups.sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // タブ切り替え
            notificationTabBarView
            
            if groupedNotifications.isEmpty {
                EmptyStateView(
                    icon: "bell.slash",
                    title: "通知はありません",
                    subtitle: selectedCategory == .me ? "フォロワーの投稿やメッセージが\nここに表示されます" : "あなたが作成したAIへの反応が\nここに表示されます"
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(groupedNotifications) { group in
                            GroupedNotificationRow(
                                group: group,
                                viewModel: viewModel
                            )
                            
                            AppDivider(leadingPadding: 68)
                        }
                    }
                    .padding(.bottom, DesignTokens.Spacing.lg)
                }
            }
        }
        .navigationTitle("通知")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 80 {
                        dismiss()
                    }
                }
        )
        .task {
            // 1. まず最新の通知を取得してリストを表示
            await viewModel.fetchNotifications()
            
            // 2. ほんの少しだけ待ってから既読にする (UX向上: ユーザーに一瞬「未読がある」と認識させてから消す)
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒待機
            
            // 3. 全て既読にする (ローカルの表示を更新 + サーバー同期)
            viewModel.markAllNotificationsAsRead()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if isPresented {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        viewModel.clearAllNotifications()
                    } label: {
                        Label("すべて削除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
        .background(AppColors.backgroundPrimary)
    }
    
    private var notificationTabBarView: some View {
        HStack(spacing: 0) {
            notificationTabItem(
                title: "あなたへの通知",
                category: .me
            )
            
            notificationTabItem(
                title: "作成したAI",
                category: .createdOshi
            )
        }
        .padding(.top, DesignTokens.Spacing.xxs)
        .background(AppColors.backgroundPrimary)
        .overlay(
            AppDivider(),
            alignment: .bottom
        )
    }

    private func notificationTabItem(title: String, category: NotificationCategory) -> some View {
        Button {
            generateHapticFeedback()
            withAnimation(DesignTokens.Animation.spring) {
                selectedCategory = category
            }
        } label: {
            VStack(spacing: DesignTokens.Spacing.xs) {
                Text(title)
                    .font(selectedCategory == category ? AppTypography.bodyMedium : AppTypography.body)
                    .foregroundColor(selectedCategory == category ? AppColors.textPrimary : AppColors.textSecondary)
                
                ZStack {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 3)
                    
                    if selectedCategory == category {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(AppColors.primaryGradientH)
                            .frame(width: 48, height: 3)
                            .matchedGeometryEffect(id: "notificationTabIndicator", in: tabNamespace)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

}

// MARK: - Grouped Notification Row
// (既存の構造体を使用、一部ロジックがプロパティ変更に追従)
struct GroupedNotificationRow: View {
    let group: GroupedNotification
    @ObservedObject var viewModel: OshiViewModel
    @State private var avatarImages: [UUID: UIImage] = [:]
    
    // ✅ 既存の投稿遷移用
    @State private var dynamicPost: Post?
    @State private var isNavigatingToDynamicPost = false
    
    // ✅ プロフィール遷移用
    @State private var dynamicOshi: OshiCharacter?
    @State private var isNavigatingToOshiProfile = false
    
    var oshiList: [OshiCharacter] {
        group.senderIds.compactMap { senderId in
            viewModel.oshiList.first { $0.id == senderId }
        }
    }
    
    var relatedPost: Post? {
        guard let postId = group.relatedPostId else { return nil }
        return viewModel.posts.first { $0.id == postId } ?? viewModel.publicTimelinePosts.first { $0.id == postId }
    }
    
    private let maxAvatarsToShow = 5
    
    private var notificationIconInfo: (icon: String, color: Color, gradient: LinearGradient) {
        switch group.type {
        case .reaction:
            return ("heart.fill", AppColors.pink, AppColors.pinkGradient)
        case .comment:
            return ("bubble.left.fill", AppColors.primary, AppColors.primaryGradientH)
        case .mention:
            return ("at", Color.purple, LinearGradient(colors: [.purple], startPoint: .top, endPoint: .bottom))
        case .follow:
            return ("person.fill.badge.plus", AppColors.success, AppColors.successGradient)
        }
    }
    
    var body: some View {
        ZStack {
            // メインコンテンツ
            if let post = relatedPost {
                NavigationLink {
                    PostDetailView(post: post, viewModel: viewModel)
                        .onAppear { markAsRead() }
                } label: {
                    contentView
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    handleTap()
                } label: {
                    contentView
                }
                .buttonStyle(.plain)
            }
            
            // 隠しNavigationLink（投稿詳細へ）
            NavigationLink(
                isActive: $isNavigatingToDynamicPost,
                destination: {
                    if let post = dynamicPost {
                        PostDetailView(post: post, viewModel: viewModel)
                            .onAppear { markAsRead() }
                    }
                },
                label: { EmptyView() }
            )
            .hidden()
            
            // ✅ 修正: プロフィール詳細への遷移（.idを追加）
            NavigationLink(
                isActive: $isNavigatingToOshiProfile,
                destination: {
                    if let oshi = dynamicOshi {
                        OshiProfileDetailView(oshi: oshi, viewModel: viewModel, isPreset: false)
                            .id(oshi.id) // 👈 【重要】IDごとのViewであることを明示してStateを強制リセット
                    }
                },
                label: { EmptyView() }
            )
            .hidden()
        }
    }
    
    // MARK: - Tap Handlers
    
    private func handleTap() {
        if let postId = group.relatedPostId {
            Task {
                if let post = await viewModel.fetchPost(postId: postId) {
                    await MainActor.run {
                        self.dynamicPost = post
                        self.isNavigatingToDynamicPost = true
                    }
                } else {
                    await MainActor.run { markAsRead() }
                }
            }
        } else {
            markAsRead()
        }
    }
    
    private func handleAvatarTap(oshiId: UUID) {
        Task {
            if let oshi = await viewModel.fetchOshi(oshiId: oshiId) {
                await MainActor.run {
                    self.dynamicOshi = oshi
                    self.isNavigatingToOshiProfile = true
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var contentView: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
            notificationTypeIcon
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                if group.notifications.count > 1 {
                    multipleAvatarsView.padding(.bottom, DesignTokens.Spacing.xs)
                }
                if group.notifications.count == 1 {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        singleAvatarView
                        Text(group.displayMessage)
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.textPrimary)
                            .lineLimit(2)
                    }
                } else {
                    Text(group.displayMessage)
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(2)
                }
                
                if let post = relatedPost {
                    Text(post.content)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                        .padding(.vertical, DesignTokens.Spacing.xs)
                        .padding(.horizontal, DesignTokens.Spacing.sm)
                        .background(AppColors.backgroundSecondary)
                        .cornerRadius(DesignTokens.Radius.sm)
                }
                
                RelativeTimeText(date: group.timestamp)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            Spacer()
            if !group.isRead {
                Circle().fill(AppColors.primary).frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(group.isRead ? AppColors.backgroundPrimary : AppColors.primary.opacity(0.03))
        .task { await loadAvatars() }
    }

    private var notificationTypeIcon: some View {
        Image(systemName: notificationIconInfo.icon)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(notificationIconInfo.color)
            .frame(width: 24)
    }

    private func markAsRead() {
        group.notifications.forEach { viewModel.markNotificationAsRead($0.id) }
    }
    
    // MARK: - Avatar Views (Buttonized)
    
    @ViewBuilder
    private var singleAvatarView: some View {
        if let oshi = oshiList.first {
            avatarButton(for: oshi.id) {
                avatarContent(for: oshi, size: DesignTokens.AvatarSize.md)
            }
        } else {
            if let senderId = group.senderIds.first {
                avatarButton(for: senderId) {
                    AvatarView(
                        image: nil,
                        name: group.senderNames.first ?? "",
                        size: DesignTokens.AvatarSize.md,
                        placeholderGradient: AppColors.pinkGradient
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private func avatarContent(for oshi: OshiCharacter, size: CGFloat) -> some View {
        AvatarView(
            image: avatarImages[oshi.id],
            name: oshi.name,
            size: size,
            placeholderGradient: AppColors.pinkGradient
        )
    }
    
    private var multipleAvatarsView: some View {
        HStack(spacing: 3) {
            let displayIds = Array(group.senderIds.prefix(maxAvatarsToShow))
            let totalCount = group.senderIds.count
            
            ForEach(Array(displayIds.enumerated()), id: \.element) { index, senderId in
                avatarButton(for: senderId) {
                    if let oshi = viewModel.oshiList.first(where: { $0.id == senderId }) {
                        stackedAvatar(for: oshi)
                            .zIndex(Double(displayIds.count - index))
                    } else {
                        AvatarView(image: nil, name: "?", size: 46, placeholderGradient: AppColors.pinkGradient)
                            .overlay(Circle().stroke(AppColors.backgroundPrimary, lineWidth: 2))
                            .zIndex(Double(displayIds.count - index))
                    }
                }
            }
            if totalCount > maxAvatarsToShow {
                Text("+\(totalCount - maxAvatarsToShow)")
                    .font(AppTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.leading, DesignTokens.Spacing.xs)
            }
        }
    }
    
    private func stackedAvatar(for oshi: OshiCharacter) -> some View {
        AvatarView(
            image: avatarImages[oshi.id],
            name: oshi.name,
            size: 46,
            placeholderGradient: AppColors.pinkGradient
        )
        .overlay(Circle().stroke(AppColors.backgroundPrimary, lineWidth: 2))
    }
    
    private func avatarButton<Content: View>(for oshiId: UUID, @ViewBuilder content: () -> Content) -> some View {
        Button {
            handleAvatarTap(oshiId: oshiId)
        } label: {
            content()
        }
        .buttonStyle(.plain)
    }
    
    private func loadAvatars() async {
        for notification in group.notifications {
            if let urlString = notification.senderAvatarURL {
                do {
                    let image = try await FirebaseStorageManager.shared.downloadImage(from: urlString)
                    await MainActor.run {
                        avatarImages[notification.senderId] = image
                    }
                } catch {
                    print("❌ アバター読み込みエラー: \(error)")
                }
            }
        }
    }
}

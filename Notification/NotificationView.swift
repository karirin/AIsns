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
            Picker("表示", selection: $selectedCategory) {
                Text("あなたへの通知").tag(NotificationCategory.me)
                Text("作成したAI").tag(NotificationCategory.createdOshi)
            }
            .pickerStyle(.segmented)
            .padding()
            .background(AppColors.backgroundPrimary)
            
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
        .task {
            await viewModel.fetchNotifications()
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
}

// MARK: - Grouped Notification Row
// (既存の構造体を使用、一部ロジックがプロパティ変更に追従)
struct GroupedNotificationRow: View {
    let group: GroupedNotification
    @ObservedObject var viewModel: OshiViewModel
    @State private var avatarImages: [UUID: UIImage] = [:]
    
    var oshiList: [OshiCharacter] {
        group.senderIds.compactMap { senderId in
            // 通知のsenderIdに一致するOshiを探す
            // ローカルの推しか、おすすめリストなどから探す必要があるが、
            // ここでは簡易的にviewModel.oshiListから探す
            // ※ 注意: 他のユーザーからの通知の場合、ここに含まれない可能性があるため
            // 本来はIDからアバターURLを取得するロジックが別途必要だが、
            // 現状の実装に合わせて viewModel.oshiList から検索する。
            // 必要に応じて `viewModel.resolveSender(id: UUID)` のようなものを実装推奨
            viewModel.oshiList.first { $0.id == senderId }
        }
    }
    
    var relatedPost: Post? {
        guard let postId = group.relatedPostId else { return nil }
        // 自分の投稿または公開タイムラインの投稿から検索
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
        if let post = relatedPost {
            NavigationLink {
                PostDetailView(post: post, viewModel: viewModel)
                    .onAppear { markAsRead() }
            } label: {
                contentView
            }
            .buttonStyle(.plain)
        } else {
            contentView
                .contentShape(Rectangle())
                .onTapGesture {
                    markAsRead()
                }
        }
    }
    
    private var contentView: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
            // 左側: 通知タイプアイコン
            notificationTypeIcon
            
            // 中央: コンテンツ
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                // 複数人の場合はアバター一覧を表示
                if group.notifications.count > 1 {
                    multipleAvatarsView
                        .padding(.bottom, DesignTokens.Spacing.xs)
                }
                
                // 単一の場合はアバター + メッセージを横並び
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
                
                // 投稿プレビュー
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
                
                // 時刻
                RelativeTimeText(date: group.timestamp)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
            
            // 未読インジケーター
            if !group.isRead {
                Circle()
                    .fill(AppColors.primary)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(group.isRead ? AppColors.backgroundPrimary : AppColors.primary.opacity(0.03))
        .task {
            await loadAvatars()
        }
    }
    
    // MARK: - Notification Type Icon
    
    private var notificationTypeIcon: some View {
        Image(systemName: notificationIconInfo.icon)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(notificationIconInfo.color)
            .frame(width: 24)
    }
    
    private func markAsRead() {
        group.notifications.forEach { notification in
            viewModel.markNotificationAsRead(notification.id)
        }
    }
    
    // MARK: - Single Avatar View
    
    @ViewBuilder
    private var singleAvatarView: some View {
        if let oshi = oshiList.first {
            // 他ユーザーからのフォロー等の場合、OshiProfileDetailViewへ飛ばすかは仕様次第だが
            // ここではアバター表示のみ考慮
            avatarContent(for: oshi, size: DesignTokens.AvatarSize.md)
        } else {
            // oshiListで見つからない場合（他ユーザーなど）は名前とプレースホルダー
            AvatarView(
                image: nil,
                name: group.senderNames.first ?? "",
                size: DesignTokens.AvatarSize.md,
                placeholderGradient: AppColors.pinkGradient
            )
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
    
    // MARK: - Multiple Avatars View
    
    private var multipleAvatarsView: some View {
        HStack(spacing: 3) {
            let displayIds = Array(group.senderIds.prefix(maxAvatarsToShow))
            let totalCount = group.senderIds.count
            
            ForEach(Array(displayIds.enumerated()), id: \.element) { index, senderId in
                if let oshi = viewModel.oshiList.first(where: { $0.id == senderId }) {
                    stackedAvatar(for: oshi)
                        .zIndex(Double(displayIds.count - index))
                } else {
                    // 情報がない場合はプレースホルダー
                    AvatarView(image: nil, name: "?", size: 46, placeholderGradient: AppColors.pinkGradient)
                        .overlay(Circle().stroke(AppColors.backgroundPrimary, lineWidth: 2))
                        .zIndex(Double(displayIds.count - index))
                }
            }
            
            // +N 表示
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
        .overlay(
            Circle()
                .stroke(AppColors.backgroundPrimary, lineWidth: 2)
        )
    }
    
    // MARK: - Load Avatars
    private func loadAvatars() async {
        print("🖼️ アバター読み込み開始")
        print("  - 通知数: \(group.notifications.count)")
        
        for notification in group.notifications {
            print("📋 通知: \(notification.senderName)")
            print("  - senderAvatarURL: \(notification.senderAvatarURL ?? "nil")")
            
            // ✅ 通知に含まれているアバターURLを使用
            if let urlString = notification.senderAvatarURL {
                do {
                    let image = try await FirebaseStorageManager.shared.downloadImage(from: urlString)
                    await MainActor.run {
                        avatarImages[notification.senderId] = image
                        print("✅ アバター読み込み成功: \(notification.senderName)")
                    }
                } catch {
                    print("❌ アバター読み込みエラー: \(error)")
                }
            } else {
                print("⚠️ アバターURLがnilです")
            }
        }
    }
}

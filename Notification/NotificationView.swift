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

// MARK: - Notification View

struct NotificationView: View {
    @ObservedObject var viewModel: OshiViewModel
    @Binding var isPresented: Bool
    @Environment(\.dismiss) var dismiss
    
    var groupedNotifications: [GroupedNotification] {
        var groups: [GroupedNotification] = []
        var processed: Set<UUID> = []
        
        let notifications = viewModel.notifications.filter {
            $0.type != .chat && $0.type != .oshiPost
        }
        
        for notification in notifications.sorted(by: { $0.timestamp > $1.timestamp }) {
            guard !processed.contains(notification.id) else { continue }
            
            if notification.type.canGroup {
                if notification.type == .follow {
                    let relatedNotifications = notifications.filter {
                        $0.type == .follow && !processed.contains($0.id)
                    }
                    
                    let group = GroupedNotification(
                        type: .follow,
                        relatedPostId: nil,
                        notifications: relatedNotifications,
                        timestamp: relatedNotifications.map { $0.timestamp }.max() ?? notification.timestamp
                    )
                    
                    groups.append(group)
                    relatedNotifications.forEach { processed.insert($0.id) }
                    
                } else if let postId = notification.relatedPostId {
                    let relatedNotifications = notifications.filter {
                        $0.type == notification.type &&
                        $0.relatedPostId == postId &&
                        !processed.contains($0.id)
                    }
                    
                    let group = GroupedNotification(
                        type: notification.type,
                        relatedPostId: postId,
                        notifications: relatedNotifications,
                        timestamp: relatedNotifications.map { $0.timestamp }.max() ?? notification.timestamp
                    )
                    
                    groups.append(group)
                    relatedNotifications.forEach { processed.insert($0.id) }
                    
                } else {
                    let group = GroupedNotification(
                        type: notification.type,
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
            if groupedNotifications.isEmpty {
                EmptyStateView(
                    icon: "bell.slash",
                    title: "通知はありません",
                    subtitle: "フォロワーの投稿やメッセージが\nここに表示されます"
                )
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
    }
}

// MARK: - Grouped Notification Row

struct GroupedNotificationRow: View {
    let group: GroupedNotification
    @ObservedObject var viewModel: OshiViewModel
    @State private var avatarImages: [UUID: UIImage] = [:]
    
    var oshiList: [OshiCharacter] {
        group.senderIds.compactMap { senderId in
            viewModel.oshiList.first { $0.id == senderId }
        }
    }
    
    var relatedPost: Post? {
        guard let postId = group.relatedPostId else { return nil }
        return viewModel.posts.first { $0.id == postId }
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
        case .chat:
            return ("message.fill", AppColors.warning, AppColors.warningGradient)
        case .oshiPost:
            return ("star.fill", Color.yellow, AppColors.goldGradient)
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
            if group.type == .follow {
                NavigationLink {
                    OshiProfileDetailView(oshi: oshi, viewModel: viewModel, isPreset: false)
                        .onAppear { markAsRead() }
                } label: {
                    avatarContent(for: oshi, size: DesignTokens.AvatarSize.md)
                }
                .buttonStyle(.plain)
            } else {
                avatarContent(for: oshi, size: DesignTokens.AvatarSize.md)
            }
        } else {
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
    
    // MARK: - Multiple Avatars View (Xスタイルの横並び)
    
    private var multipleAvatarsView: some View {
        HStack(spacing: 3) {
            let displayOshi = Array(oshiList.prefix(maxAvatarsToShow))
            let totalCount = oshiList.count
            
            ForEach(Array(displayOshi.enumerated()), id: \.element.id) { index, oshi in
                Group {
                    if group.type == .follow {
                        NavigationLink {
                            OshiProfileDetailView(oshi: oshi, viewModel: viewModel, isPreset: false)
                                .onAppear { markAsRead() }
                        } label: {
                            stackedAvatar(for: oshi)
                        }
                        .buttonStyle(.plain)
                    } else {
                        stackedAvatar(for: oshi)
                    }
                }
                .zIndex(Double(displayOshi.count - index))
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
        for oshi in oshiList {
            guard let urlString = oshi.avatarImageURL else { continue }
            if let image = try? await FirebaseStorageManager.shared.downloadImage(from: urlString) {
                await MainActor.run {
                    avatarImages[oshi.id] = image
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        NotificationView(viewModel: OshiViewModel(mock: true), isPresented: .constant(false))
    }
}

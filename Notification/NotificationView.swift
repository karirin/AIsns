import SwiftUI

// MARK: - Grouped Notification Model

/// グループ化された通知
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
    
    /// 表示用メッセージ
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
    
    /// 通知をグループ化
    var groupedNotifications: [GroupedNotification] {
        var groups: [GroupedNotification] = []
        var processed: Set<UUID> = []
        
        // ✅ 修正: 「チャット」と「推しの投稿」を画面表示から除外
        let notifications = viewModel.notifications.filter {
            $0.type != .chat && $0.type != .oshiPost
        }
        
        for notification in notifications.sorted(by: { $0.timestamp > $1.timestamp }) {
            guard !processed.contains(notification.id) else { continue }
            
            // グループ化可能な場合
            if notification.type.canGroup {
                
                // ケース1: フォロー通知
                if notification.type == .follow {
                    let relatedNotifications = notifications.filter {
                        $0.type == .follow &&
                        !processed.contains($0.id)
                    }
                    
                    let group = GroupedNotification(
                        type: .follow,
                        relatedPostId: nil,
                        notifications: relatedNotifications,
                        timestamp: relatedNotifications.map { $0.timestamp }.max() ?? notification.timestamp
                    )
                    
                    groups.append(group)
                    relatedNotifications.forEach { processed.insert($0.id) }
                    
                }
                // ケース2: 投稿関連の通知
                else if let postId = notification.relatedPostId {
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
                // グループ化しない通知
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
            // 通知一覧
            if groupedNotifications.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(groupedNotifications) { group in
                            GroupedNotificationRow(
                                group: group,
                                viewModel: viewModel
                            )
                            
                            Divider()
                                .padding(.leading, 68)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("通知")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .task {
            await viewModel.fetchNotifications()
            // 画面を開いたタイミングで既読にする
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
                            .foregroundColor(.primary)
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        viewModel.markAllNotificationsAsRead()
                    } label: {
                        Label("すべて既読にする", systemImage: "checkmark.circle")
                    }
                    
                    Button(role: .destructive) {
                        viewModel.clearAllNotifications()
                    } label: {
                        Label("すべて削除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.primary)
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "bell.slash")
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                Text("通知はありません")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("フォロワーの投稿やメッセージが\nここに表示されます")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
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
    
    // 表示するアバター数の制限
    private let maxAvatarsToShow = 6
    
    var body: some View {
        // ✅ 投稿がある場合（いいね、コメント、推しの投稿）は投稿詳細へ
        if let post = relatedPost {
            NavigationLink {
                PostDetailView(post: post, viewModel: viewModel)
                    .onAppear { markAsRead() }
            } label: {
                contentView
            }
            .buttonStyle(.plain)
        } else {
            // ✅ 投稿がない場合（フォローなど）は行自体は遷移せず、既読のみ
            contentView
                .contentShape(Rectangle())
                .onTapGesture {
                    markAsRead()
                }
        }
    }
    
    // ✅ 共通の行コンテンツ
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // 左側: アバター + 通知タイプアイコン
                ZStack(alignment: .bottomTrailing) {
                    // 複数アバターの重なり表示
                    if group.notifications.count > 1 {
                        multipleAvatarsView
                    } else {
                        // 単一アバター
                        singleAvatarView
                    }
                    
                    // 通知タイプアイコン
                    Circle()
                        .fill(notificationColor)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: group.type.icon)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color(.systemBackground), lineWidth: 2)
                        )
                        .offset(x: group.notifications.count > 1 ? 8 : 4, y: 4)
                }
                .frame(height: 48)
                
                Spacer()
                
                // 未読インジケーター
                if !group.isRead {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // 通知内容（アバターの下）
            VStack(alignment: .leading, spacing: 6) {
                Text(group.displayMessage)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                // 投稿の内容プレビュー
                if let post = relatedPost {
                    Text(post.content)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                // 時刻
                XStyleRelativeTimeText(date: group.timestamp)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom)
        }
        .background(group.isRead ? Color(.systemBackground) : Color(.systemGray6).opacity(0.3))
        .task {
            await loadAvatars()
        }
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
            // ✅ フォロー通知の場合はアバタータップでプロフィール詳細へ遷移
            if group.type == .follow {
                NavigationLink {
                    OshiProfileDetailView(oshi: oshi, viewModel: viewModel, isPreset: false)
                        .onAppear { markAsRead() }
                } label: {
                    avatarImageContent(oshi: oshi)
                }
                .buttonStyle(.plain)
            } else {
                avatarImageContent(oshi: oshi)
            }
        } else {
            // 削除されたユーザーなどのフォールバック
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.red, .red.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 48)
                .overlay(
                    Text(String(group.senderNames.first?.prefix(1) ?? ""))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
        }
    }
    
    // MARK: - Multiple Avatars View
    
    private var multipleAvatarsView: some View {
        ZStack {
            // 表示するアバターのリスト
            let displayOshi = Array(oshiList.prefix(maxAvatarsToShow))
            let totalCount = oshiList.count
            
            ForEach(Array(displayOshi.enumerated()), id: \.element.id) { index, oshi in
                Group {
                    // ✅ フォロー通知の場合は個別のアバターがリンクになる
                    if group.type == .follow {
                        NavigationLink {
                            OshiProfileDetailView(oshi: oshi, viewModel: viewModel, isPreset: false)
                                .onAppear { markAsRead() }
                        } label: {
                            avatarImageContent(oshi: oshi)
                                .overlay(
                                    Circle()
                                        .stroke(Color(.systemBackground), lineWidth: 2)
                                )
                        }
                    } else {
                        avatarImageContent(oshi: oshi)
                            .overlay(
                                Circle()
                                    .stroke(Color(.systemBackground), lineWidth: 2)
                            )
                    }
                }
                .offset(x: CGFloat(index) * 50, y: 0)
            }
            
            // 4人以上の場合は「+N」を表示
            if totalCount > maxAvatarsToShow {
                Circle()
                    .fill(Color(.systemGray4))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text("+\(totalCount - maxAvatarsToShow)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color(.systemBackground), lineWidth: 2)
                    )
                    .offset(x: CGFloat(maxAvatarsToShow) * 50, y: 0)
            }
        }
        .frame(width: 100, height: 48, alignment: .leading)
    }
    
    // MARK: - Avatar Image Content Helper
    
    @ViewBuilder
    private func avatarImageContent(oshi: OshiCharacter) -> some View {
        if let image = avatarImages[oshi.id] {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 48, height: 48)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.red, .red.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 48)
                .overlay(
                    Text(String(oshi.name.prefix(1)))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
        }
    }
    
    // MARK: - Helper Methods
    
    private var notificationColor: Color {
        switch group.type {
        case .reaction: return .pink
        case .comment: return .blue
        case .mention: return .purple
        case .follow: return .green
        case .chat: return .orange
        case .oshiPost: return .yellow
        }
    }
    
    private func loadAvatars() async {
        for oshi in oshiList {
            guard let urlString = oshi.avatarImageURL else { continue }
            if let image = try? await FirebaseStorageManager.shared.downloadImage(from: urlString) {
                avatarImages[oshi.id] = image
            }
        }
    }
}

#Preview {
//    NotificationView(viewModel: OshiViewModel(mock: true))
    MainTabView()
}

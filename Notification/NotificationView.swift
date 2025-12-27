import SwiftUI

// MARK: - Grouped Notification Model

/// グループ化された通知
struct GroupedNotification: Identifiable {
    let id = UUID()
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
        default:
            return notifications.first?.message ?? ""
        }
    }
}

// MARK: - Notification View

struct NotificationView: View {
    @ObservedObject var viewModel: OshiViewModel
    @State private var selectedFilter: NotificationFilter = .all
    @Binding var isPresented: Bool
    @Environment(\.dismiss) var dismiss
    
    enum NotificationFilter: String, CaseIterable {
        case all = "すべて"
        case mentions = "メンション"
        
        var icon: String {
            switch self {
            case .all: return "bell.fill"
            case .mentions: return "at"
            }
        }
    }
    
    var filteredNotifications: [AppNotification] {
        switch selectedFilter {
        case .all:
            return viewModel.notifications
        case .mentions:
            return viewModel.notifications.filter { $0.type == .mention }
        }
    }
    
    /// 通知をグループ化
    var groupedNotifications: [GroupedNotification] {
        var groups: [GroupedNotification] = []
        var processed: Set<UUID> = []
        
        for notification in filteredNotifications.sorted(by: { $0.timestamp > $1.timestamp }) {
            guard !processed.contains(notification.id) else { continue }
            
            // グループ化可能かつ関連投稿IDがある場合
            if notification.type.canGroup,
               let postId = notification.relatedPostId {
                
                // 同じ投稿・同じタイプの通知を探す
                let relatedNotifications = filteredNotifications.filter {
                    $0.type == notification.type &&
                    $0.relatedPostId == postId &&
                    !processed.contains($0.id)
                }
                
                // グループ化
                let group = GroupedNotification(
                    type: notification.type,
                    relatedPostId: postId,
                    notifications: relatedNotifications,
                    timestamp: relatedNotifications.map { $0.timestamp }.max() ?? notification.timestamp
                )
                
                groups.append(group)
                relatedNotifications.forEach { processed.insert($0.id) }
                
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
                // フィルタータブ
                filterBar
                
                Divider()
                
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
                    }
                }
        }
            .navigationTitle("通知")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
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
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        HStack(spacing: 0) {
            ForEach(NotificationFilter.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedFilter = filter
                    }
                } label: {
                    VStack(spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: filter.icon)
                                .font(.caption)
                            Text(filter.rawValue)
                                .font(.subheadline)
                        }
                        .fontWeight(selectedFilter == filter ? .bold : .medium)
                        .foregroundColor(selectedFilter == filter ? .primary : .secondary)
                        
                        // アンダーラインインジケーター
                        Capsule()
                            .fill(selectedFilter == filter ? Color.blue : Color.clear)
                            .frame(width: 60, height: 3)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 8)
        .background(Color(.systemBackground))
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
                
                Text("推しの投稿やメッセージが\nここに表示されます")
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
    private let maxAvatarsToShow = 8
    
    var body: some View {
        Button {
            // 全ての通知を既読にする
            group.notifications.forEach { notification in
                viewModel.markNotificationAsRead(notification.id)
            }
        } label: {
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
        }
        .buttonStyle(.plain)
        .task {
            await loadAvatars()
        }
    }
    
    // MARK: - Single Avatar View
    
    @ViewBuilder
    private var singleAvatarView: some View {
        if let oshi = oshiList.first,
           let avatarImage = avatarImages[oshi.id] {
            Image(uiImage: avatarImage)
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
                if let avatarImage = avatarImages[oshi.id] {
                    Image(uiImage: avatarImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color(.systemBackground), lineWidth: 2)
                        )
                        .offset(x: CGFloat(index) * 40, y: 0)
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
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color(.systemBackground), lineWidth: 2)
                        )
                        .offset(x: CGFloat(index) * 40, y: 0)
                }
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
                    .offset(x: CGFloat(maxAvatarsToShow) * 40, y: 0)
            }
        }
        .frame(width: 100, height: 48, alignment: .leading)
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


import SwiftUI

struct NotificationView: View {
    @ObservedObject var viewModel: OshiViewModel
    @State private var selectedFilter: NotificationFilter = .all
    
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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // フィルタータブ
                filterBar
                
                Divider()
                
                // 通知一覧
                if filteredNotifications.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredNotifications) { notification in
                                NotificationRow(
                                    notification: notification,
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
            .toolbar {
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

// MARK: - Notification Row

struct NotificationRow: View {
    let notification: AppNotification
    @ObservedObject var viewModel: OshiViewModel
    @State private var avatarImage: UIImage?
    
    var oshi: OshiCharacter? {
        viewModel.oshiList.first { $0.id == notification.senderId }
    }
    
    var relatedPost: Post? {
        guard let postId = notification.relatedPostId else { return nil }
        return viewModel.posts.first { $0.id == postId }
    }
    
    var body: some View {
        Button {
            viewModel.markNotificationAsRead(notification.id)
            
            // 関連する投稿がある場合は投稿詳細へ遷移
            // （実装は NavigationLink でラップする必要があります）
        } label: {
            HStack(alignment: .top, spacing: 12) {
                // アバター + 通知タイプアイコン
                ZStack(alignment: .bottomTrailing) {
                    // アバター
                    if let avatarImage = avatarImage {
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
                                Text(String(notification.senderName.prefix(1)))
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                    }
                    
                    // 通知タイプアイコン
                    Circle()
                        .fill(notificationColor)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: notification.type.icon)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .offset(x: 2, y: 2)
                }
                
                // 通知内容
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text(notification.message)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        // 未読インジケーター
                        if !notification.isRead {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    // 投稿の内容プレビュー
                    if let post = relatedPost, notification.type == .comment || notification.type == .reaction {
                        Text(post.content)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    // コメント内容プレビュー
                    if notification.type == .comment, !notification.content.isEmpty {
                        Text(notification.content)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    // 時刻
                    XStyleRelativeTimeText(date: notification.timestamp)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(notification.isRead ? Color(.systemBackground) : Color(.systemGray6).opacity(0.3))
        }
        .buttonStyle(.plain)
        .task {
            if let oshi = oshi, let urlString = oshi.avatarImageURL {
                avatarImage = try? await FirebaseStorageManager.shared.downloadImage(from: urlString)
            }
        }
    }
    
    private var notificationColor: Color {
        switch notification.type {
        case .reaction: return .pink
        case .comment: return .blue
        case .mention: return .purple
        case .follow: return .green
        case .chat: return .orange
        case .oshiPost: return .yellow
        }
    }
}

#Preview {
    NotificationView(viewModel: OshiViewModel(mock: true))
}

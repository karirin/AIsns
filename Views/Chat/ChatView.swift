//
//  ChatView.swift
//  AIsns
//
//  Updated: 2026/01/02 - Complete UI/UX Redesign
//

import SwiftUI

// MARK: - Chat List View

struct ChatListView: View {
    @ObservedObject var viewModel: OshiViewModel
    @Binding var isPresented: Bool
    @Environment(\.dismiss) var dismiss
    @State private var helpFlag: Bool = false
    @State private var customerFlag: Bool = false
    private let dbManager = FirebaseDatabaseManager.shared
    
    @State private var isLoading = true
    
    var sortedChatRooms: [ChatRoom] {
        viewModel.chatRooms.sorted { room1, room2 in
            (room1.lastMessageDate ?? Date.distantPast) > (room2.lastMessageDate ?? Date.distantPast)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    LoadingView(
                        message: "チャットを読み込み中",
                        subtitle: "フォロワーとの会話を取得しています..."
                    )
                } else if sortedChatRooms.isEmpty {
                    chatEmptyView
                } else {
                    chatListContent
                }

                if helpFlag {
                    HelpModalView(isPresented: $helpFlag)
                }
                
                if customerFlag {
                    ReviewView(isPresented: $customerFlag, helpFlag: $helpFlag)
                }
            }
            .navigationTitle("チャット")
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
            }
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadChatRooms()
            }
            .refreshable {
                await loadChatRooms()
            }
            .onAppear{
                dbManager.fetchUserFlag { userFlag, error in
                    if let error = error {
                        print(error.localizedDescription)
                    } else if let userFlag = userFlag {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            if userFlag == 0 {
                                executeProcessEveryfifTimes()
                                executeProcessEveryThreeTimes()
                            }
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    func executeProcessEveryfifTimes() {
        // UserDefaultsからカウンターを取得
        let count = UserDefaults.standard.integer(forKey: "launchHelpCount") + 1
        
        // カウンターを更新
        UserDefaults.standard.set(count, forKey: "launchHelpCount")

        if count % 15 == 0 {
            helpFlag = true
        }
    }

    func executeProcessEveryThreeTimes() {
        // UserDefaultsからカウンターを取得
        let count = UserDefaults.standard.integer(forKey: "launchCount") + 1
        
        // カウンターを更新
        UserDefaults.standard.set(count, forKey: "launchCount")
        
        // 3回に1回の割合で処理を実行
        if count % 10 == 0 {
            customerFlag = true
        }
    }
    
    // MARK: - Empty State
    
    private var chatEmptyView: some View {
        ScrollView {
            EmptyStateView(
                icon: "message.badge",
                title: "チャットがまだありません",
                subtitle: "アカウントをフォローして、\n会話を始めましょう!",
                actionTitle: "フォロワーを見る",
                action: {
                    // Navigate to followers
                }
            )
            .padding(.top, DesignTokens.Spacing.xxxxl)
        }
    }
    
    // MARK: - Chat List Content
    
    private var chatListContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(sortedChatRooms) { room in
                    if let oshi = viewModel.oshiList.first(where: { $0.id == room.oshiId }) {
                        NavigationLink(destination: ChatDetailView(oshi: oshi, viewModel: viewModel)) {
                            ChatRoomRow(oshi: oshi, room: room)
                        }
                        .buttonStyle(.plain)
                        
                        if room.id != sortedChatRooms.last?.id {
                            AppDivider(leadingPadding: 80)
                        }
                    }
                }
            }
        }
        .background(AppColors.backgroundPrimary)
    }
    
    // MARK: - Data Loading
    
    private func loadChatRooms() async {
        isLoading = true
        
        if !viewModel.chatRooms.isEmpty {
            isLoading = false
            return
        }
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        await MainActor.run {
            isLoading = false
        }
    }
}

// MARK: - Chat Room Row

struct ChatRoomRow: View {
    let oshi: OshiCharacter
    let room: ChatRoom
    @State private var avatarImage: UIImage?
    
    var lastMessage: Message? {
        room.messages.last
    }
    
    var timeDisplay: String {
        guard let date = lastMessage?.timestamp else { return "" }
        
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "昨日"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.dateFormat = "E"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            return formatter.string(from: date)
        }
    }
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            // アバター
            ZStack(alignment: .topTrailing) {
                AvatarView(
                    image: avatarImage,
                    name: oshi.name,
                    size: DesignTokens.AvatarSize.xl,
                    placeholderGradient: AppColors.pinkGradient
                )
                
                // 未読バッジ
                if room.unreadCount > 0 {
                    BadgeView(count: room.unreadCount, size: 20, gradient: AppColors.pinkGradient)
                        .offset(x: 4, y: -4)
                }
            }
            .task {
                if let urlString = oshi.avatarImageURL {
                    avatarImage = try? await FirebaseStorageManager.shared.downloadImage(from: urlString)
                }
            }
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                HStack(alignment: .center) {
                    Text(oshi.name)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(timeDisplay)
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                if let lastMessage = lastMessage {
                    HStack(spacing: 4) {
                        if lastMessage.isFromUser {
                            Text("あなた:")
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        Text(lastMessage.content)
                            .font(AppTypography.subheadline)
                            .foregroundColor(room.unreadCount > 0 ? AppColors.textPrimary : AppColors.textSecondary)
                            .lineLimit(2)
                    }
                } else {
                    Text("まだメッセージがありません")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(AppColors.backgroundPrimary)
        .contentShape(Rectangle())
    }
}

// MARK: - Chat Detail View

struct ChatDetailView: View {
    let oshi: OshiCharacter
    @ObservedObject var viewModel: OshiViewModel
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var chatRoom: ChatRoom? {
        viewModel.chatRooms.first { $0.oshiId == oshi.id }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // メッセージエリア
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: DesignTokens.Spacing.sm) {
                        ForEach(chatRoom?.messages ?? []) { message in
                            MessageBubble(message: message, oshi: oshi)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.sm)
                    .padding(.vertical, DesignTokens.Spacing.md)
                }
                .background(AppColors.backgroundSecondary)
                .onChange(of: chatRoom?.messages.count) { _ in
                    if let lastMessage = chatRoom?.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // 入力エリア
            chatInputBar
        }
        .onTapGesture {
            UIApplication.shared.endEditing()
        }
        .navigationTitle(oshi.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.markChatAsRead(oshiId: oshi.id)
        }
    }
    
    // MARK: - Chat Input Bar
    
    private var chatInputBar: some View {
        VStack(spacing: 0) {
            AppDivider()
            
            HStack(spacing: DesignTokens.Spacing.sm) {
                
                // メッセージ入力欄
                HStack(spacing: DesignTokens.Spacing.xs) {
                    TextField("メッセージを入力", text: $messageText, axis: .vertical)
                        .focused($isTextFieldFocused)
                        .font(AppTypography.body)
                        .lineLimit(1...5)
                }
                .padding(.horizontal, DesignTokens.Spacing.sm)
                .padding(.vertical, DesignTokens.Spacing.xs)
                .background(AppColors.backgroundSecondary)
                .cornerRadius(DesignTokens.Radius.xl)
                
                // 送信ボタン
                Button(action: {
                    sendMessage()
                    generateHapticFeedback()
                }) {
                    Image(systemName: messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                          ? "arrow.up.circle.fill"
                          : "paperplane.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(
                            messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? LinearGradient(colors: [.gray], startPoint: .top, endPoint: .bottom)
                            : AppColors.primaryGradient
                        )
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
        .background(AppColors.backgroundPrimary)
    }
    
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        viewModel.sendMessage(to: oshi.id, content: text)
        messageText = ""
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: Message
    let oshi: OshiCharacter
    @State private var avatarImage: UIImage?
    
    var body: some View {
        HStack(alignment: .bottom, spacing: DesignTokens.Spacing.xs) {
            if message.isFromUser {
                Spacer(minLength: 60)
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(alignment: .bottom, spacing: 6) {
                        // 既読表示
                        if message.isRead {
                            Text("既読")
                                .font(AppTypography.caption2)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        // メッセージバブル
                        Text(message.content)
                            .font(AppTypography.body)
                            .padding(.horizontal, DesignTokens.Spacing.sm)
                            .padding(.vertical, DesignTokens.Spacing.sm)
                            .background(AppColors.primaryGradient)
                            .foregroundColor(.white)
                            .cornerRadius(DesignTokens.Radius.lg)
//                            .cornerRadius(DesignTokens.Radius.xxs, corners: [.bottomRight])
                    }
                }
            } else {
                HStack(alignment: .bottom, spacing: DesignTokens.Spacing.xs) {
                    // アバター
                    AvatarView(
                        image: avatarImage,
                        name: oshi.name,
                        size: DesignTokens.AvatarSize.sm + 4,
                        placeholderGradient: AppColors.pinkGradient
                    )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // 名前
                        Text(oshi.name)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                        
                        // メッセージバブル
                        Text(message.content)
                            .font(AppTypography.body)
                            .padding(.horizontal, DesignTokens.Spacing.sm)
                            .padding(.vertical, DesignTokens.Spacing.sm)
                            .background(AppColors.backgroundTertiary)
                            .foregroundColor(AppColors.textPrimary)
                            .cornerRadius(DesignTokens.Radius.lg)
//                            .cornerRadius(DesignTokens.Radius.xxs, corners: [.bottomLeft])
                    }
                }
                .task {
                    if let urlString = oshi.avatarImageURL {
                        avatarImage = try? await FirebaseStorageManager.shared.downloadImage(from: urlString)
                    }
                }
                
                Spacer(minLength: 60)
            }
        }
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    ChatListView(viewModel: OshiViewModel(mock: true), isPresented: .constant(false))
}

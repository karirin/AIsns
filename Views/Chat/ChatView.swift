//
//  ChatView.swift
//  AIsns
//
//  Updated: 2026/01/19 - Added Message Counter & Reward Ad Modal
//

import SwiftUI

// MARK: - Chat List View

struct ChatListView: View {
    @ObservedObject var viewModel: OshiViewModel
    @Binding var isPresented: Bool
    @Environment(\.dismiss) var dismiss
    private let dbManager = FirebaseDatabaseManager.shared
    @ObservedObject var adViewModel: AdViewModel
    
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var isEditingChats = false
    @State private var chatRoomPendingDeletion: ChatRoom?
    @State private var showingDeleteChatAlert = false
    
    var sortedChatRooms: [ChatRoom] {
        let rooms = viewModel.chatRooms.sorted { room1, room2 in
            (room1.lastMessageDate ?? Date.distantPast) > (room2.lastMessageDate ?? Date.distantPast)
        }
        
        if searchText.isEmpty {
            return rooms
        }
        
        return rooms.filter { room in
            if let oshi = viewModel.oshiList.first(where: { $0.id == room.oshiId }) {
                return oshi.name.localizedCaseInsensitiveContains(searchText)
            }
            return false
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景グラデーション
                chatListBackground
                
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

            }
            .navigationTitle("メッセージ")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isPresented {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        guard !sortedChatRooms.isEmpty else { return }
                        generateHapticFeedback()
                        isEditingChats.toggle()
                    } label: {
                        Text(isEditingChats ? "完了" : "編集")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(width: 44, height: 44, alignment: .trailing)
                    }
                    .foregroundColor(AppColors.textPrimary)
                    .opacity(sortedChatRooms.isEmpty ? 0 : 1)
                    .disabled(sortedChatRooms.isEmpty)
                    .accessibilityHidden(sortedChatRooms.isEmpty)
                    .animation(nil, value: isEditingChats)
                }
            }
            .searchable(text: $searchText, prompt: "検索")
            .task {
                await loadChatRooms()
            }
            .refreshable {
                await loadChatRooms()
            }
            .alert("DMを削除しますか?", isPresented: $showingDeleteChatAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("削除", role: .destructive) {
                    if let chatRoomPendingDeletion {
                        viewModel.deleteChatRoom(chatRoomPendingDeletion)
                    }
                    chatRoomPendingDeletion = nil
                }
            } message: {
                Text("この会話履歴は端末とサーバーから削除されます。")
            }
        }
    }
    
    // MARK: - Background
    
    private var chatListBackground: some View {
        AuroraBackground()
    }
    
    // MARK: - Empty State
    
    private var chatEmptyView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // イラスト風アイコン
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.pink.opacity(0.1),
                                    Color.purple.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.pink, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .padding(.top, 60)
                
                VStack(spacing: 8) {
                    Text("まだメッセージがありません")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("アカウントをフォローして\n会話を始めましょう")
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Chat List Content
    
    private var chatListContent: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(sortedChatRooms) { room in
                    if let oshi = viewModel.oshiList.first(where: { $0.id == room.oshiId }) {
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            NavigationLink(destination: ChatDetailView(oshi: oshi, viewModel: viewModel, adViewModel: adViewModel)) {
                                ChatRoomRow(oshi: oshi, room: room)
                                    .floatingCardStyle()
                            }
                            .buttonStyle(ChatRowButtonStyle())

                            if isEditingChats {
                                Button(role: .destructive) {
                                    chatRoomPendingDeletion = room
                                    showingDeleteChatAlert = true
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(Circle().fill(AppColors.error))
                                }
                                .buttonStyle(.plain)
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, DesignTokens.Spacing.sm)
                        .animation(DesignTokens.Animation.spring, value: isEditingChats)
                    }
                }
            }
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
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

// MARK: - Chat Row Button Style

struct ChatRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
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
            formatter.dateFormat = "E曜日"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            return formatter.string(from: date)
        }
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // アバター with オンラインインジケーター風デザイン
            ZStack(alignment: .bottomTrailing) {
                AvatarView(
                    image: avatarImage,
                    name: oshi.name,
                    size: 60,
                    placeholderGradient: AppColors.pinkGradient
                )
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                // 未読バッジ
                if room.unreadCount > 0 {
                    ZStack {
                        Circle()
                            .fill(AppColors.pinkGradient)
                            .frame(width: 22, height: 22)
                        
                        Text(room.unreadCount > 99 ? "99+" : "\(room.unreadCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 4, y: 4)
                }
            }
            .task {
                if let urlString = oshi.avatarImageURL {
                    avatarImage = try? await FirebaseStorageManager.shared.downloadImage(from: urlString)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center) {
                    Text(oshi.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(timeDisplay)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textTertiary)
                }
                
                HStack(spacing: 4) {
                    if let lastMessage = lastMessage {
                        if lastMessage.isFromUser {
                            // 送信済みチェックマーク
                            Image(systemName: lastMessage.isRead ? "checkmark.circle.fill" : "checkmark.circle")
                                .font(.system(size: 12))
                                .foregroundColor(lastMessage.isRead ? AppColors.primary : AppColors.textTertiary)
                        }
                        
                        Text(lastMessage.content)
                            .font(.system(size: 14))
                            .foregroundColor(room.unreadCount > 0 ? AppColors.textPrimary : AppColors.textSecondary)
                            .fontWeight(room.unreadCount > 0 ? .medium : .regular)
                            .lineLimit(2)
                    } else {
                        Text("タップして会話を始める")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(AppColors.textTertiary)
                            .italic()
                    }
                    
                    Spacer()
                }
            }
            
            // 右矢印
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

// MARK: - Chat Detail View

struct ChatDetailView: View {
    let oshi: OshiCharacter
    @ObservedObject var viewModel: OshiViewModel
    @ObservedObject var adViewModel: AdViewModel
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.dismiss) var dismiss
    @State private var showingRewardModal = false
    @State private var avatarImage: UIImage?
    
    // ✅ 新機能: タイピングインジケーター
    @State private var isOshiTyping = false
    @State private var showReadReceipt = false
    @State private var pendingReadMessageId: UUID?
    
    // メッセージ制限の設定
    private let messageLimit = 10
    
    var remainingMessages: Int {
        max(0, messageLimit - viewModel.messageCount)
    }
    
    var chatRoom: ChatRoom? {
        viewModel.chatRooms.first { $0.oshiId == oshi.id }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // メッセージエリア
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            // 日付ヘッダー（オプション）
                            chatDateHeader
                            
                            ForEach(chatRoom?.messages ?? []) { message in
                                MessageBubble(
                                    message: message,
                                    oshi: oshi,
                                    avatarImage: avatarImage,
                                    showReadReceipt: pendingReadMessageId == message.id && showReadReceipt
                                )
                                .id(message.id)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                                    removal: .opacity
                                ))
                            }
                            
                            // タイピングインジケーター
                            if isOshiTyping {
                                TypingIndicator(oshi: oshi, avatarImage: avatarImage)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .bottom).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                                    .id("typing-indicator")
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                    }
                    .background(chatBackground)
                    .onChange(of: chatRoom?.messages.count) { _ in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if let lastMessage = chatRoom?.messages.last {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: isOshiTyping) { typing in
                        if typing {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                proxy.scrollTo("typing-indicator", anchor: .bottom)
                            }
                        }
                    }
                }
                
                // 入力エリア
                chatInputBar
            }
            
            // ✅ リワード広告モーダル
            if showingRewardModal {
                RewardAdModal(
                    isPresented: $showingRewardModal,
                    oshi: oshi,
                    avatarImage: avatarImage,
                    adViewModel: adViewModel,
                    onRewardEarned: {
                        viewModel.resetMessageLimit()
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .zIndex(100)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showingRewardModal)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                chatHeaderView
            }
            
            // ✅ 右上にカウントダウン表示
            if viewModel.shouldShowAds {
                ToolbarItem(placement: .navigationBarTrailing) {
                    messageCounterBadge
                }
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 80 {
                        dismiss()
                    }
                }
        )
        .onTapGesture {
            UIApplication.shared.endEditing()
        }
        .onAppear {
            viewModel.markChatAsRead(oshiId: oshi.id)
        }
        .task {
            await viewModel.loadChatRoomDetailsIfNeeded(oshiId: oshi.id)
            if let urlString = oshi.avatarImageURL {
                avatarImage = try? await FirebaseStorageManager.shared.downloadImage(from: urlString)
            }
            if viewModel.shouldShowAds {
                await adViewModel.loadRewardedAd()
            }
        }
    }
    
    // MARK: - Chat Background
    
    private var chatBackground: some View {
        ZStack {
            AuroraBackground()
            
            // 微妙なパターン（オプション）
            GeometryReader { geo in
                Path { path in
                    let spacing: CGFloat = 30
                    for x in stride(from: 0, through: geo.size.width, by: spacing) {
                        for y in stride(from: 0, through: geo.size.height, by: spacing) {
                            path.addEllipse(in: CGRect(x: x, y: y, width: 2, height: 2))
                        }
                    }
                }
                .fill(AppColors.textTertiary.opacity(0.03))
            }
        }
    }
    
    // MARK: - Chat Header
    
    private var chatHeaderView: some View {
        HStack(spacing: 10) {
            AvatarView(
                image: avatarImage,
                name: oshi.name,
                size: 36,
                placeholderGradient: AppColors.pinkGradient
            )
            
            VStack(alignment: .leading, spacing: 1) {
                Text(oshi.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
            }
        }
    }
    
    // MARK: - Date Header
    
    private var chatDateHeader: some View {
        Group {
            if let firstMessage = chatRoom?.messages.first {
                Text(formatDateHeader(firstMessage.timestamp))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textTertiary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(AppColors.backgroundTertiary.opacity(0.8))
                    )
                    .padding(.vertical, 8)
            }
        }
    }
    
    private func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "今日"
        } else if calendar.isDateInYesterday(date) {
            return "昨日"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.dateFormat = "M月d日 (E)"
            return formatter.string(from: date)
        }
    }
    
    // MARK: - ✅ Message Counter Badge (右上カウントダウン)
    
    private var messageCounterBadge: some View {
        Button(action: {
            if viewModel.isMessageLimitReached {
                generateHapticFeedback()
                viewModel.requestPlusPaywall(.messageLimitReached, force: true)
            }
        }) {
            HStack(spacing: 6) {
                // メッセージアイコン
                Image(systemName: remainingMessages <= 3 ? "bubble.left.fill" : "bubble.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(remainingMessages <= 3 ? .white : AppColors.primary)

                // 残り回数
                Text("\(remainingMessages)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(remainingMessages <= 3 ? .white : AppColors.primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(
                        remainingMessages <= 3
                        ? LinearGradient(
                            colors: remainingMessages == 0
                            ? [Color.orange, Color(hex: "E85D04")]
                            : [Color(hex: "EC4899"), Color(hex: "DB2777")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [AppColors.brandWash, AppColors.brandWash],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                Capsule()
                    .stroke(
                        remainingMessages <= 3
                        ? Color.clear
                        : AppColors.primary.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: remainingMessages <= 3
                ? AppColors.pink.opacity(0.3)
                : Color.clear,
                radius: 4, x: 0, y: 2
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: remainingMessages)
    }
    
    // MARK: - Chat Input Bar
    
    private var chatInputBar: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 10) {
                // メッセージ入力欄
                HStack(alignment: .bottom, spacing: 8) {
                    TextField("メッセージ", text: $messageText, axis: .vertical)
                        .focused($isTextFieldFocused)
                        .font(.system(size: 16))
                        .lineLimit(1...6)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .disabled(viewModel.isMessageLimitReached && viewModel.shouldShowAds)
                }
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(viewModel.isMessageLimitReached && viewModel.shouldShowAds
                              ? AppColors.surfaceSecondary.opacity(0.5)
                              : AppColors.surfaceSecondary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(isTextFieldFocused ? AppColors.primary.opacity(0.5) : Color.clear, lineWidth: 1.5)
                )
                
                // 送信ボタン
                Button(action: {
                    generateHapticFeedback()
                    if viewModel.isMessageLimitReached && viewModel.shouldShowAds {
                        showingRewardModal = true
                        Task {
                            await adViewModel.loadRewardedAd()
                        }
                    } else {
                        sendMessageWithRealisticFlow()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                viewModel.isMessageLimitReached && viewModel.shouldShowAds
                                ? LinearGradient(
                                    colors: [Color.orange, Color(hex: "E85D04")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                                : AppColors.primaryGradient
                            )
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: viewModel.isMessageLimitReached && viewModel.shouldShowAds
                              ? "play.rectangle.fill"
                              : "arrow.up")
                            .font(.system(size: viewModel.isMessageLimitReached ? 16 : 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .disabled(
                    !viewModel.isMessageLimitReached &&
                    messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
                .scaleEffect(
                    viewModel.isMessageLimitReached
                    ? 1.0
                    : messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.9 : 1.0
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: messageText.isEmpty)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.isMessageLimitReached)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .padding(.bottom, 4)
        }
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            AppDivider(color: AppColors.borderLight.opacity(0.5))
        }
    }
    
    // MARK: - ✅ リアルなメッセージフロー
    
    private func sendMessageWithRealisticFlow() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        // 1. メッセージをローカルに追加
        let userMessage = Message(content: text, isFromUser: true)
        
        // ViewModelにメッセージを追加（この時点ではisRead = false）
        if let roomIndex = viewModel.chatRooms.firstIndex(where: { $0.oshiId == oshi.id }) {
            viewModel.chatRooms[roomIndex].addMessage(userMessage)
        }
        
        messageText = ""
        pendingReadMessageId = userMessage.id
        
        // 2. 数秒後に「既読」を付ける
        let readDelay = Double.random(in: 1.5...3.0)
        
        Task {
            try? await Task.sleep(nanoseconds: UInt64(readDelay * 1_000_000_000))
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showReadReceipt = true
                }
                
                // メッセージを既読に更新
                if let roomIndex = viewModel.chatRooms.firstIndex(where: { $0.oshiId == oshi.id }),
                   let msgIndex = viewModel.chatRooms[roomIndex].messages.firstIndex(where: { $0.id == userMessage.id }) {
                    viewModel.chatRooms[roomIndex].messages[msgIndex].isRead = true
                }
            }
            
            // 3. さらに数秒後にタイピングインジケーター表示
            let typingDelay = Double.random(in: 1.0...2.5)
            try? await Task.sleep(nanoseconds: UInt64(typingDelay * 1_000_000_000))
            
            await MainActor.run {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isOshiTyping = true
                }
            }
            
            // 4. AI返答を生成（TimingConfigの値を使用）
            do {
                // TimingConfigのreplyDelayRangeを使用
                let replyDelayNanos = UInt64.random(in: TimingConfig.nanoseconds(TimingConfig.Chat.replyDelayRange))
                try await Task.sleep(nanoseconds: replyDelayNanos)
                
                let reply: String
                do {
                    reply = try await AIService.shared.generateChatReply(
                        for: text,
                        by: oshi,
                        conversationHistory: viewModel.chatRooms.first(where: { $0.oshiId == oshi.id })?.messages ?? [],
                        userName: viewModel.userProfileName
                    )
                } catch {
                    print("⚠️ メッセージ生成フォールバック: \(error)")
                    reply = AIService.shared.fallbackReply(seed: text)
                }
                
                // タイピング終了 & メッセージ追加
                await MainActor.run {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isOshiTyping = false
                    }
                    
                    // 少し間を置いてからメッセージを表示
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        let aiMessage = Message(content: reply, isFromUser: false, oshiId: oshi.id)
                        
                        if let roomIndex = viewModel.chatRooms.firstIndex(where: { $0.oshiId == oshi.id }) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                viewModel.chatRooms[roomIndex].addMessage(aiMessage)
                            }
                        }
                        viewModel.notifyDeliveredChatReply(from: oshi, message: aiMessage)
                        
                        // Firebaseに保存
                        Task {
                            do {
                                try await FirebaseDatabaseManager.shared.addMessage(to: oshi.id, message: aiMessage)
                                ReviewRequestManager.shared.recordMeaningfulCompletion()
                            } catch {
                                print("❌ AIメッセージ保存エラー: \(error.localizedDescription)")
                            }
                        }
                        
                        // 親密度更新
                        if let oshiIndex = viewModel.oshiList.firstIndex(where: { $0.id == oshi.id }) {
                            viewModel.oshiList[oshiIndex].increaseIntimacy(by: 3)
                            Task {
                                try? await FirebaseDatabaseManager.shared.saveOshi(viewModel.oshiList[oshiIndex])
                            }
                        }
                    }
                }
                
            } catch {
                await MainActor.run {
                    isOshiTyping = false
                }
                print("❌ メッセージ生成エラー: \(error)")
            }
        }
        
        // Firebase保存（ユーザーメッセージ）
        Task {
            try? await FirebaseDatabaseManager.shared.addMessage(to: oshi.id, message: userMessage)
        }
        
        viewModel.recordMessageSentForPlusPaywall()
    }
}

// MARK: - ✅ Reward Ad Modal (リワード広告モーダル)

struct RewardAdModal: View {
    @Binding var isPresented: Bool
    let oshi: OshiCharacter
    let avatarImage: UIImage?
    @ObservedObject var adViewModel: AdViewModel
    var onRewardEarned: () -> Void
    
    @State private var isWatchingAd = false
    @State private var adNotice: String?
    @State private var showSuccess = false
    @State private var pulseAnimation = false
    @State private var floatAnimation = false
    
    var body: some View {
        ZStack(alignment: .center) {
            // 背景オーバーレイ
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    if !isWatchingAd {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                    }
                }
            
            // メインモーダル（中央配置）
            VStack(spacing: 0) {
                // ヘッダー部分（グラデーション背景）
                ZStack {
                    // グラデーション背景
                    AppColors.primaryGradient
//                    .frame(height: 180)
                    
                    // 装飾的な円（背景）
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 200, height: 200)
                        .offset(x: -80, y: -60)
                    
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 150, height: 150)
                        .offset(x: 100, y: 40)
                    
                    // コンテンツ
                    VStack(spacing: 16) {
                        // アバターとメッセージアイコン
                        ZStack {
                            // 外側の光彩
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 100, height: 100)
                                .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                                .opacity(pulseAnimation ? 0 : 0.5)
                            
                            // アバター
                            AvatarView(
                                image: avatarImage,
                                name: oshi.name,
                                size: 80,
                                placeholderGradient: LinearGradient(
                                    colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                            )
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                            
                            // メッセージバッジ
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: "bubble.left.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppColors.primary)
                            }
                            .offset(x: 30, y: 30)
                            .offset(y: floatAnimation ? -3 : 3)
                        }
                        
                        Text("\(oshi.name)ともっと話そう")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                    .offset(y: -10)
                }
                .clipShape(
                    RoundedCorner(radius: 24, corners: [.topLeft, .topRight])
                )
                
                // ボディ部分
                VStack(spacing: 24) {
                    // 説明文
                    VStack(spacing: 8) {
                        Text("メッセージの送信回数が上限に達しました")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("短い動画を見ると追加で10回話せます。\n無料回数は毎日リセットされます")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.top, 24)
                    
                    // 報酬表示
                    HStack(spacing: 16) {
                        // 動画アイコン
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.brandWash)
                                .frame(width: 50, height: 50)

                            Image(systemName: "play.rectangle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(AppColors.primary)
                        }
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppColors.textTertiary)
                        
                        // 報酬
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "E8F5E9"), Color(hex: "F1F8E9")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)
                            
                            VStack(spacing: 2) {
                                Text("+10")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "4CAF50"))
                                
                                Image(systemName: "bubble.left.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color(hex: "4CAF50"))
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // ボタン群
                    VStack(spacing: 12) {
                        if let adNotice {
                            Text(adNotice)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .transition(.opacity)
                        }

                        // 広告視聴ボタン
                        Button(action: {
                            generateHapticFeedback(style: .success)
                            watchAd()
                        }) {
                            HStack(spacing: 10) {
                                if isWatchingAd {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.9)
                                } else {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                
                                Text(isWatchingAd ? "読み込み中..." : "動画を見て続ける")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                isWatchingAd
                                ? LinearGradient(colors: [Color.gray], startPoint: .top, endPoint: .bottom)
                                : AppColors.primaryGradientH
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: AppColors.primary.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isWatchingAd)
                        
                        // キャンセルボタン
                        Button(action: {
                            generateHapticFeedback(style: .error)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isPresented = false
                            }
                        }) {
                            Text("あとで")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        }
                        .disabled(isWatchingAd)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .background(AppColors.backgroundPrimary)
            }
            .frame(maxWidth: 340)
            .fixedSize(horizontal: false, vertical: true)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.25), radius: 30, x: 0, y: 15)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                floatAnimation = true
            }
        }
    }
    
    private func watchAd() {
        guard !isWatchingAd else { return }
        isWatchingAd = true
        withAnimation { adNotice = nil }

        Task { @MainActor in
            let outcome = await adViewModel.presentRewardedAd()
            isWatchingAd = false

            switch outcome {
            case .rewarded:
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    onRewardEarned()
                    isPresented = false
                }
            case .dismissedEarly:
                withAnimation { adNotice = "動画を最後まで見ると、メッセージを続けられます。" }
            case .unavailable:
                // 広告の在庫切れ・通信エラーはユーザーのせいではないため、行き止まりにせず続けてもらう
                withAnimation { adNotice = "今は動画を用意できなかったので、このまま続けられます。" }
                onRewardEarned()
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isPresented = false
                }
            }
        }
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    let oshi: OshiCharacter
    let avatarImage: UIImage?
    
    @State private var dotAnimation = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // アバター
            AvatarView(
                image: avatarImage,
                name: oshi.name,
                size: 32,
                placeholderGradient: AppColors.pinkGradient
            )
            
            // タイピングバブル
            HStack(spacing: 5) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(AppColors.textSecondary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(dotAnimation ? 1.0 : 0.5)
                        .opacity(dotAnimation ? 1.0 : 0.4)
                        .animation(
                            .easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.15),
                            value: dotAnimation
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppColors.surface)
                    .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
            )
            
            Spacer()
        }
        .padding(.top, 4)
        .onAppear {
            dotAnimation = true
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: Message
    let oshi: OshiCharacter
    let avatarImage: UIImage?
    var showReadReceipt: Bool = false
    
    @State private var isVisible = false
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: message.timestamp)
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isFromUser {
                Spacer(minLength: 50)
                userMessageBubble
            } else {
                oshiMessageBubble
                Spacer(minLength: 50)
            }
        }
        .padding(.vertical, 2)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 10)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
    }
    
    // MARK: - User Message Bubble
    
    private var userMessageBubble: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // メッセージ本体
            Text(message.content)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppColors.primaryGradient)
                .clipShape(ChatBubbleShape(isFromUser: true))
                .shadow(color: AppColors.primary.opacity(0.3), radius: 4, x: 0, y: 2)
            
            // 時刻 & 既読表示
            HStack(spacing: 4) {
                if message.isRead || showReadReceipt {
                    Text("既読")
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.primary)
                        .transition(.scale.combined(with: .opacity))
                }
                
                Text(timeString)
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.textTertiary)
            }
            .animation(.easeInOut(duration: 0.3), value: message.isRead)
            .animation(.easeInOut(duration: 0.3), value: showReadReceipt)
        }
    }
    
    // MARK: - Oshi Message Bubble
    
    private var oshiMessageBubble: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // アバター
            AvatarView(
                image: avatarImage,
                name: oshi.name,
                size: 32,
                placeholderGradient: AppColors.pinkGradient
            )
            
            VStack(alignment: .leading, spacing: 4) {
                // メッセージ本体
                Text(message.content)
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AppColors.surface)
                    .clipShape(ChatBubbleShape(isFromUser: false))
                    .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                
                // 時刻
                Text(timeString)
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.textTertiary)
                    .padding(.leading, 4)
            }
        }
    }
}

// MARK: - Chat Bubble Shape

struct ChatBubbleShape: Shape {
    let isFromUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        let tailSize: CGFloat = 6
        
        var path = Path()
        
        if isFromUser {
            // 右下に小さな尾
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY + radius),
                control: CGPoint(x: rect.maxX, y: rect.minY)
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius - tailSize))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - radius + tailSize, y: rect.maxY - tailSize),
                control: CGPoint(x: rect.maxX, y: rect.maxY - tailSize)
            )
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
                control: CGPoint(x: rect.maxX - tailSize, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX, y: rect.maxY - radius),
                control: CGPoint(x: rect.minX, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + radius, y: rect.minY),
                control: CGPoint(x: rect.minX, y: rect.minY)
            )
        } else {
            // 左下に小さな尾
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY + radius),
                control: CGPoint(x: rect.maxX, y: rect.minY)
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
                control: CGPoint(x: rect.maxX, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + radius - tailSize, y: rect.maxY - tailSize),
                control: CGPoint(x: rect.minX + tailSize, y: rect.maxY)
            )
            path.addQuadCurve(
                to: CGPoint(x: rect.minX, y: rect.maxY - radius - tailSize),
                control: CGPoint(x: rect.minX, y: rect.maxY - tailSize)
            )
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + radius, y: rect.minY),
                control: CGPoint(x: rect.minX, y: rect.minY)
            )
        }
        
        path.closeSubpath()
        return path
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

//#Preview {
//    ChatListView(viewModel: OshiViewModel(mock: true), isPresented: .constant(false), adViewModel: AdViewModel())
//}

#Preview("RewardAdModal") {
    RewardAdModal(
        isPresented: .constant(true),
        oshi: OshiCharacter(
            name: "ユイ",
            avatarImageURL: nil
            // ※ OshiCharacter の必須プロパティが他にもある場合はここに追加
        ),
        avatarImage: nil,
        adViewModel: AdViewModel(),
        onRewardEarned: {}
    )
}

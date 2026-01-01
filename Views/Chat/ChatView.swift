// Views/Chat/ChatView.swift
import SwiftUI

struct ChatListView: View {
    @ObservedObject var viewModel: OshiViewModel
    @Binding var isPresented: Bool
    @Environment(\.dismiss) var dismiss
    
    // ✅ ローディング状態を追加
    @State private var isLoading = true
    
    var sortedChatRooms: [ChatRoom] {
        viewModel.chatRooms.sorted { room1, room2 in
            (room1.lastMessageDate ?? Date.distantPast) > (room2.lastMessageDate ?? Date.distantPast)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // ✅ 状態に応じた表示
                if isLoading {
                    loadingView
                } else if sortedChatRooms.isEmpty {
                    emptyStateView
                } else {
                    chatListView
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
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .task {
                // ✅ データ読み込み
                await loadChatRooms()
            }
            .refreshable {
                await loadChatRooms()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // MARK: - ✅ Loading View
    
    private var loadingView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 24) {
                // アニメーション付きアイコン
                ZStack {
                    // 背景の円
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.2, green: 0.7, blue: 1.0).opacity(0.1),
                                    Color(red: 0.5, green: 0.4, blue: 1.0).opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    // 回転する外側のリング
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.2, green: 0.7, blue: 1.0),
                                    Color(red: 0.5, green: 0.4, blue: 1.0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .modifier(RotatingModifier())
                    
                    // 中央のアイコン
                    Image(systemName: "message.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.2, green: 0.7, blue: 1.0),
                                    Color(red: 0.5, green: 0.4, blue: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .modifier(PulseModifier())
                }
                
                VStack(spacing: 8) {
                    Text("チャットを読み込み中")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("フォロワーとの会話を取得しています...")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - ✅ Empty State View
    
    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 60)
                
                // アイコン
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.2, green: 0.7, blue: 1.0).opacity(0.1),
                                    Color(red: 0.5, green: 0.4, blue: 1.0).opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "message.badge")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.2, green: 0.7, blue: 1.0),
                                    Color(red: 0.5, green: 0.4, blue: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(spacing: 12) {
                    Text("チャットがまだありません")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("アカウントをフォローして、\n会話を始めましょう!")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                
                // フォロー画面へのボタン
                if !viewModel.oshiList.isEmpty || !viewModel.recommendedOshis.isEmpty {
                    VStack(spacing: 16) {
                        NavigationLink {
                            OshiListView(viewModel: viewModel, isPresented: .constant(true))
                        } label: {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("フォロワーを見る")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.2, green: 0.7, blue: 1.0),
                                        Color(red: 0.5, green: 0.4, blue: 1.0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - ✅ Chat List View
    
    private var chatListView: some View {
        List {
            ForEach(sortedChatRooms) { room in
                if let oshi = viewModel.oshiList.first(where: { $0.id == room.oshiId }) {
                    NavigationLink(destination: ChatDetailView(oshi: oshi, viewModel: viewModel)) {
                        ChatRoomRow(oshi: oshi, room: room)
                    }
                }
            }
        }
        .listStyle(.plain)
    }
    
    // MARK: - ✅ Data Loading
    
    private func loadChatRooms() async {
        isLoading = true
        
        // 既にViewModelでロード済みの場合はスキップ
        if !viewModel.chatRooms.isEmpty {
            isLoading = false
            return
        }
        
        // 少し待ってからローディングを解除（アニメーション表示のため）
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    // MARK: - Animation Modifiers
    
    struct RotatingModifier: ViewModifier {
        @State private var isRotating = false
        
        func body(content: Content) -> some View {
            content
                .rotationEffect(.degrees(isRotating ? 360 : 0))
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        isRotating = true
                    }
                }
        }
    }
    
    struct PulseModifier: ViewModifier {
        @State private var isPulsing = false
        
        func body(content: Content) -> some View {
            content
                .scaleEffect(isPulsing ? 1.1 : 1.0)
                .opacity(isPulsing ? 0.8 : 1.0)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                }
        }
    }
}

struct ChatRoomRow: View {
    let oshi: OshiCharacter
    let room: ChatRoom
    @State private var avatarImage: UIImage?
    
    var lastMessage: Message? {
        room.messages.last
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // アバター
            ZStack(alignment: .topTrailing) {
                if let avatarImage = avatarImage {
                    Image(uiImage: avatarImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color(.red).gradient)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Text(String(oshi.name.prefix(1)))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                }
                
                // 未読バッジ
                if room.unreadCount > 0 {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Text("\(room.unreadCount)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                        .offset(x: 4, y: -4)
                }
            }
            .task {
                if let urlString = oshi.avatarImageURL {
                    avatarImage = try? await FirebaseStorageManager.shared.downloadImage(from: urlString)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(oshi.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    if let lastMessage = lastMessage {
                        Text(lastMessage.timestamp, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let lastMessage = lastMessage {
                    Text(lastMessage.content)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

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
                    LazyVStack(spacing: 16) {
                        ForEach(chatRoom?.messages ?? []) { message in
                            MessageBubble(message: message, oshi: oshi)
                                .id(message.id)
                        }
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
                .onChange(of: chatRoom?.messages.count) { _ in
                    if let lastMessage = chatRoom?.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // 入力エリア
            HStack(spacing: 8) {
                // プラスボタン
                Button(action: {
                    generateHapticFeedback()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                // メッセージ入力欄
                HStack {
                    TextField("メッセージを入力", text: $messageText)
                        .focused($isTextFieldFocused)
                    
                    // スタンプボタン
                    Button(action: {
                        generateHapticFeedback()
                    }) {
                        Image(systemName: "face.smiling")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                
                // 送信ボタン
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(
                                    messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                                    Color.gray : Color.blue
                                )
                        )
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
        }
        .navigationTitle(oshi.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    generateHapticFeedback()
                }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.primary)
                }
            }
        }
        .onAppear {
            viewModel.markChatAsRead(oshiId: oshi.id)
        }
    }
    
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        viewModel.sendMessage(to: oshi.id, content: text)
        messageText = ""
    }
}

struct MessageBubble: View {
    let message: Message
    let oshi: OshiCharacter
    @State private var avatarImage: UIImage?
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isFromUser {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(alignment: .bottom, spacing: 8) {
                        // 既読表示
                        Text("既読")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        // メッセージバブル
                        Text(message.content)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Color.blue
                            )
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .frame(maxWidth: 260, alignment: .trailing)
                    }
                }
            } else {
                HStack(alignment: .bottom, spacing: 8) {
                    // アバター
                    if let avatarImage = avatarImage {
                        Image(uiImage: avatarImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color(.red).gradient)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(String(oshi.name.prefix(1)))
                                    .font(.callout)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // 名前
                        Text(oshi.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // メッセージバブル
                        Text(message.content)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .foregroundColor(.primary)
                            .cornerRadius(20)
                            .frame(maxWidth: 260, alignment: .leading)
                    }
                }
                .task {
                    if let urlString = oshi.avatarImageURL {
                        avatarImage = try? await FirebaseStorageManager.shared.downloadImage(from: urlString)
                    }
                }
                
                Spacer()
            }
        }
    }
}

#Preview {
    ChatListView(viewModel: OshiViewModel(mock: true), isPresented: .constant(false))
}

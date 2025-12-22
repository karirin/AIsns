import SwiftUI

struct ChatListView: View {
    @ObservedObject var viewModel: OshiViewModel
    
    var sortedChatRooms: [ChatRoom] {
        viewModel.chatRooms.sorted { room1, room2 in
            (room1.lastMessageDate ?? Date.distantPast) > (room2.lastMessageDate ?? Date.distantPast)
        }
    }
    
    var body: some View {
        NavigationView {
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
            .navigationTitle("チャット")
            .navigationBarTitleDisplayMode(.inline)
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
                Button(action: {}) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                // メッセージ入力欄
                HStack {
                    TextField("メッセージを入力", text: $messageText)
                        .focused($isTextFieldFocused)
                    
                    // スタンプボタン
                    Button(action: {}) {
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
                Button(action: {}) {
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
    ChatListView(viewModel: OshiViewModel(mock: true))
}

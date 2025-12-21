import SwiftUI
import UIKit

struct OshiListView: View {
    @ObservedObject var viewModel: OshiViewModel
    @State private var showingCreationSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.oshiList.isEmpty {
                    // 空の状態
                    VStack(spacing: 20) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.gray)
                        
                        Text("推しを作成しよう")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("あなた専用のAI推しを作成して\n自分だけのSNSを楽しもう")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Button(action: { showingCreationSheet = true }) {
                            Text("推しを作成")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(25)
                        }
                        .padding(.top)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(viewModel.oshiList) { oshi in
                            NavigationLink(destination: OshiProfileEditView(oshi: oshi, viewModel: viewModel)) {
                                OshiCard(oshi: oshi)
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.visible)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("フォロワー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreationSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .fullScreenCover(isPresented: $showingCreationSheet) {
                NavigationStack {
                    OshiCreationView(viewModel: viewModel)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("閉じる") { showingCreationSheet = false }
                            }
                        }
                }
            }
        }
    }
}

struct OshiCard: View {
    let oshi: OshiCharacter
    @State private var avatarImage: UIImage?
    
    var body: some View {
        HStack(spacing: 12) {
                // アバター（Groupを使わずに直接 if/else）
                if let avatarImage = avatarImage {
                    Image(uiImage: avatarImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color(.red).gradient)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(String(oshi.name.prefix(1)))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                }
            
            VStack(alignment: .leading, spacing: 4) {
                // 名前と性格アイコン
                HStack(spacing: 4) {
                    Text(oshi.name)
                        .font(.body)
                        .fontWeight(.semibold)
                    
                    Text(oshi.personality.emoji)
                        .font(.caption)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .task {
            // 画像を非同期で読み込み
            if let urlString = oshi.avatarImageURL {
                avatarImage = try? await FirebaseStorageManager.shared.downloadImage(from: urlString)
            }
        }
    }
}

#Preview {
    OshiListView(viewModel: OshiViewModel())
}

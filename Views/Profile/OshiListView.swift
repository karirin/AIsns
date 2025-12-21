import SwiftUI
import UIKit

enum OshiListTab: String, CaseIterable {
    case followers = "フォロワー"
    case recommended = "おすすめ"
}

struct OshiListView: View {
    @ObservedObject var viewModel: OshiViewModel
    @State private var showingCreationSheet = false
    @State private var selectedTab: OshiListTab = .followers
    @State private var isFollowing = false
    
    private let recommendedOshis: [OshiCharacter] = PresetOshiProvider.recommended
    
    var body: some View {
        NavigationView {
            ZStack {
                switch selectedTab {
                case .followers:
                    if viewModel.oshiList.isEmpty {
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
                                NavigationLink(
                                    destination: OshiProfileEditView(
                                        oshi: oshi,
                                        viewModel: viewModel
                                    )
                                ) {
                                    OshiCard(oshi: oshi)
                                }
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.visible)
                            }
                        }
                        .listStyle(.plain)
                    }
                    
                case .recommended:
                    List {
                        ForEach(recommendedOshis) { oshi in
                            HStack {
                                NavigationLink(
                                    destination: OshiProfileEditView(oshi: oshi, viewModel: viewModel)
                                ) {
                                    OshiCard(oshi: oshi)
                                }

                                Spacer()

                                if isAlreadyFollowed(oshi) {
                                    Text("追加済み")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Button {
                                        Task {
                                            isFollowing = true
                                            defer { isFollowing = false }
                                            await viewModel.followRecommended(oshi)
                                        }
                                    } label: {
                                        if isFollowing {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        } else {
                                            Text("フォロー")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                    .disabled(isFollowing)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(selectedTab.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // フォロワー / おすすめ 切り替え
                ToolbarItem(placement: .principal) {
                    Picker("", selection: $selectedTab) {
                        ForEach(OshiListTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                }
                
                // ＋ボタン（フォロワーのみ）
                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedTab == .followers {
                        Button(action: { showingCreationSheet = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showingCreationSheet) {
                NavigationStack {
                    OshiCreationView(viewModel: viewModel)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("閉じる") {
                                    showingCreationSheet = false
                                }
                            }
                        }
                }
            }
        }
    }
    
    private func isAlreadyFollowed(_ oshi: OshiCharacter) -> Bool {
        viewModel.oshiList.contains(where: { $0.id == oshi.id })
    }
}

struct OshiCard: View {
    let oshi: OshiCharacter
    @State private var avatarImage: UIImage?
    
    var body: some View {
        HStack(spacing: 12) {
            if let avatarImage = avatarImage {
                Image(uiImage: avatarImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.red.gradient)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(oshi.name.prefix(1)))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(oshi.name)
                        .font(.body)
                        .fontWeight(.semibold)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .task {
            if let urlString = oshi.avatarImageURL {
                avatarImage = try? await FirebaseStorageManager.shared.downloadImage(from: urlString)
            }
        }
    }
}

#Preview {
    OshiListView(viewModel: OshiViewModel())
}

import SwiftUI
import UIKit

enum OshiListTab: String, CaseIterable {
    case followers = "フォロー中"
    case recommended = "おすすめ"
}

struct OshiListView: View {
    @ObservedObject var viewModel: OshiViewModel
    @State private var showingCreationSheet = false
    @State private var selectedTab: OshiListTab = .followers
    private let adminUserId = "3248012D-3F48-4449-9F99-D3C0D777D0D0"
    private var canEditRecommended: Bool {
        FirebaseConfig.shared.userId == adminUserId
    }
    @State private var followingIds: Set<UUID> = []

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                Color(.systemBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    tabBar
                    
                    Divider()
                    
                    // コンテンツ
                    TabView(selection: $selectedTab) {
                        followersView
                            .tag(OshiListTab.followers)
                        
                        recommendedView
                            .tag(OshiListTab.recommended)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
                
                // フローティング作成ボタン（フォロー中タブのみ）
                if selectedTab == .followers {
                    createButton
                        .padding(.trailing, 20)
                        .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
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
    
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(OshiListTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 12) {
                        Text(tab.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedTab == tab ? .bold : .medium)
                            .foregroundColor(selectedTab == tab ? .primary : .secondary)
                        
                        // アンダーラインインジケーター
                        Capsule()
                            .fill(selectedTab == tab ? Color.blue : Color.clear)
                            .frame(width: 60, height: 3)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 8)
        .background(Color(.systemBackground))
    }
    
    // MARK: - フローティング作成ボタン
    
    private var createButton: some View {
        Button(action: { showingCreationSheet = true }) {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
    }

    // MARK: - Followers

    private var followersView: some View {
        Group {
            if viewModel.oshiList.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.oshiList) { oshi in
                            if canEditRecommended {
                                NavigationLink(
                                    destination: OshiProfileEditView(oshi: oshi, viewModel: viewModel)
                                ) {
                                    OshiCell(oshi: oshi)
                                }
                                .buttonStyle(.plain)
                            } else {
                                OshiCell(oshi: oshi)
                            }
                            
                            Divider()
                                .padding(.leading, 76)
                        }
                    }
                }
                .background(Color(.systemBackground))
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 56))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("推しを作成しよう")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("あなた専用のAI推しを作成して\n自分だけのSNSを楽しもう")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            Button(action: { showingCreationSheet = true }) {
                Text("推しを作成")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(22)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
    }

    // MARK: - Recommended

    private var recommendedView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.recommendedOshis) { oshi in
                    HStack(spacing: 12) {
                        NavigationLink(
                            destination: OshiProfileEditView(
                                oshi: oshi,
                                viewModel: viewModel,
                                isPreset: true
                            )
                        ) {
                            OshiCell(oshi: oshi, showChevron: false)
                        }
                        .buttonStyle(.plain)
                        
                        // フォローボタン
                        if isAlreadyFollowed(oshi) {
                            Text("フォロー中")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(Color.clear)
                                .overlay(
                                    Capsule()
                                        .stroke(Color(.systemGray3), lineWidth: 1)
                                )
                        } else {
                            Button {
                                Task {
                                    followingIds.insert(oshi.id)
                                    defer { followingIds.remove(oshi.id) }
                                    await viewModel.followRecommended(oshi)
                                }
                            } label: {
                                if followingIds.contains(oshi.id) {
                                    ProgressView()
                                        .tint(.white)
                                        .frame(width: 76, height: 32)
                                        .background(Color.black)
                                        .cornerRadius(16)
                                } else {
                                    Text("フォロー")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .background(Color.black)
                                        .cornerRadius(16)
                                }
                            }
                            .disabled(followingIds.contains(oshi.id))
                        }
                    }
                    .padding(.trailing, 16)
                    
                    Divider()
                        .padding(.leading, 76)
                }
            }
        }
        .background(Color(.systemBackground))
    }

    private func isAlreadyFollowed(_ oshi: OshiCharacter) -> Bool {
        viewModel.oshiList.contains(where: { $0.id == oshi.id })
    }
}

struct OshiCell: View {
    let oshi: OshiCharacter
    var showChevron: Bool = true
    @State private var avatarImage: UIImage?

    var body: some View {
        HStack(spacing: 12) {
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
                            colors: [.blue, .cyan],
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

            // 名前・ユーザーネーム
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(oshi.name)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }

            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
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
    OshiListView(viewModel: OshiViewModel(mock: true))
}

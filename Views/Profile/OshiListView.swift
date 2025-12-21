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
    private let adminUserId = "3248012D-3F48-4449-9F99-D3C0D777D0D0"
    private var canEditRecommended: Bool {
        FirebaseConfig.shared.userId == adminUserId
    }

    // ✅ 行ごとに「フォロー中」を管理（1つのBoolだと全行が同時にローディングになるため）
    @State private var followingIds: Set<UUID> = []

    var body: some View {
        NavigationView {
            ZStack {
                switch selectedTab {
                case .followers:
                    followersView

                case .recommended:
                    recommendedView
                }
            }
            .navigationTitle(selectedTab.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("", selection: $selectedTab) {
                        ForEach(OshiListTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                }

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
                                Button("閉じる") { showingCreationSheet = false }
                            }
                        }
                }
            }
        }
    }

    // MARK: - Followers

    private var followersView: some View {
        Group {
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
                        if canEditRecommended {
                            NavigationLink(
                                destination: OshiProfileEditView(oshi: oshi, viewModel: viewModel)
                            ) {
                                OshiCard(oshi: oshi)
                            }
                        } else {
                            OshiCard(oshi: oshi)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - Recommended

    private var recommendedView: some View {
        List {
            ForEach(viewModel.recommendedOshis) { oshi in
                HStack(spacing: 12) {
                    NavigationLink(
                        destination: OshiProfileEditView(
                            oshi: oshi,
                            viewModel: viewModel,
                            isPreset: true
                        )
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
                                followingIds.insert(oshi.id)
                                defer { followingIds.remove(oshi.id) }
                                await viewModel.followRecommended(oshi)
                            }
                        } label: {
                            if followingIds.contains(oshi.id) {
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
                        .disabled(followingIds.contains(oshi.id))
                    }
                }
            }
        }
        .listStyle(.plain)
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
    OshiListView(viewModel: OshiViewModel(mock: true))
}

//
//  FollowListView.swift
//  AIsns
//
//  Created by Assistant on 2026/01/05.
//

import SwiftUI

enum FollowListType {
    case following
    case followers(oshiId: UUID)
}

struct FollowListView: View {
    let title: String
    let type: FollowListType
    @ObservedObject var viewModel: OshiViewModel
    @State private var users: [OshiCharacter] = []
    @State private var isLoading = true
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Group {
            if isLoading {
                LoadingView(message: "読み込み中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if users.isEmpty {
                EmptyStateView(
                    icon: "person.slash",
                    title: typeLabel,
                    subtitle: ""
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: DesignTokens.Spacing.sm) {
                        ForEach(users) { user in
                            HStack(spacing: 12) {
                                AsyncAvatarView(
                                    imageURL: user.avatarImageURL,
                                    name: user.name,
                                    size: 44,
                                    placeholderGradient: AppColors.primaryGradient
                                )

                                Text(user.name)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)

                                Spacer()
                            }
                            .padding(DesignTokens.Spacing.md)
                            .floatingCardStyle()
                            .padding(.horizontal, DesignTokens.Spacing.sm)
                        }
                    }
                    .padding(.vertical, DesignTokens.Spacing.sm)
                }
            }
        }
        .background(AuroraBackground())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
        .task {
            await loadData()
        }
    }
    
    private var typeLabel: String {
        switch type {
        case .following: return "まだ誰もフォローしていません"
        case .followers: return "まだフォロワーがいません"
        }
    }
    
    private func loadData() async {
        isLoading = true
        do {
            switch type {
            case .following:
                try await viewModel.loadFollowingList()
                users = viewModel.followingOshis
                
            case .followers(let oshiId):
                users = try await FirebaseDatabaseManager.shared.fetchOshiFollowers(oshiId: oshiId)
            }
        } catch {
            print("Error loading list: \(error)")
        }
        isLoading = false
    }
}

#Preview {
    MainTabView()
}

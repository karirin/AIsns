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
        List {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            } else if users.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.slash")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text(typeLabel)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowSeparator(.hidden)
                .padding(.top, 40)
            } else {
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
                    .padding(.vertical, 6)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true)
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

//
//  BookmarkListView.swift
//  AIsns
//
//  Created by Apple on 2026/01/01.
//

import SwiftUI

struct BookmarkListView: View {
    @ObservedObject var viewModel: OshiViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Group {
            if viewModel.bookmarkedPosts.isEmpty {
                EmptyStateView(
                    icon: "bookmark",
                    title: "ブックマークした投稿はありません",
                    subtitle: "気に入った投稿を保存して、\nここであとから見返せます。"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: DesignTokens.Spacing.sm) {
                        ForEach(viewModel.bookmarkedPosts) { post in
                            PostCardView(post: post, viewModel: viewModel)
                                .padding(.horizontal, DesignTokens.Spacing.sm)
                        }
                    }
                    .padding(.top, DesignTokens.Spacing.sm)
                    .padding(.bottom, 20)
                }
                .refreshable {
                    await viewModel.fetchBookmarkedPosts()
                }
            }
        }
        .background(AuroraBackground())
        .navigationTitle("ブックマーク")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 80 {
                        dismiss()
                    }
                }
        )
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.primary)
                    }
            }
        }
        .task {
            // 画面表示時にデータをロード
            await viewModel.fetchBookmarkedPosts()
        }
    }
}

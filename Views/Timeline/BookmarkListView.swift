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
                VStack(spacing: 20) {
                    Image(systemName: "bookmark.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("ブックマークした投稿はありません")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("気に入った投稿を保存して、\nここであとから見返せます。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.bookmarkedPosts) { post in
                            PostCardView(post: post, viewModel: viewModel)
                            Divider()
                                .padding(.leading, 64)
                        }
                    }
                    .padding(.bottom, 20)
                }
                .refreshable {
                    await viewModel.fetchBookmarkedPosts()
                }
            }
        }
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

//
//  PostDetailView.swift
//  AIsns
//
//  Created by Apple on 2025/12/21.
//

import SwiftUI

// ✅ 投稿の詳細（Xっぽく別画面でコメント確認）
struct PostDetailView: View {
    let post: Post
    @ObservedObject var viewModel: OshiViewModel

    var postDetails: PostDetails? {
        viewModel.postDetails[post.id]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 投稿本文（見た目はカードを再利用）
                PostCardView(post: post, viewModel: viewModel)
                Divider()

                // コメント一覧
                VStack(alignment: .leading, spacing: 12) {
                    if let details = postDetails {
                        if details.comments.isEmpty {
                            Text("まだコメントはありません")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 12)
                        } else {
                            ForEach(details.comments) { comment in
                                CommentRow(comment: comment, viewModel: viewModel)
                                Divider()
                            }

                            if details.hasMoreComments {
                                Button {
                                    Task { await viewModel.loadMoreComments(for: post.id) }
                                } label: {
                                    Text("返信をさらに表示")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                .padding(.vertical, 12)
                            }
                        }
                    } else {
                        HStack(spacing: 8) {
                            ProgressView().scaleEffect(0.9)
                            Text("コメントを読み込み中...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 12)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
        .navigationTitle("投稿")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // 初回だけ詳細取得
            if viewModel.postDetails[post.id] == nil {
                await viewModel.loadPostDetails(for: post.id)
            }
        }
    }
}

//
//  PostDetailView.swift
//  AIsns
//
//  Created by Apple on 2025/12/21.
//

import SwiftUI

struct PostDetailView: View {
    let post: Post
    @ObservedObject var viewModel: OshiViewModel
    
    var focusOnAppear: Bool = false
    @Environment(\.dismiss) var dismiss

    // ✅ 入力用Stateを追加
    @State private var commentText = ""
    @FocusState private var isFocused: Bool

    var postDetails: PostDetails? {
        viewModel.postDetails[post.id]
    }

    var body: some View {
        // ✅ 全体をVStackにし、ScrollViewと入力エリアを縦に並べる
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    // 投稿本文
                    PostCardView(post: post, viewModel: viewModel, isNavigable: false)
                    
                    Divider()
                    
                    // いいね一覧
                    VStack(alignment: .leading, spacing: 8) {
                        Text("いいね")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let details = postDetails {
                            if details.reactions.isEmpty {
                                Text("まだいいねはありません")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(details.reactions) { reaction in
                                            HStack(spacing: 6) {
                                                Text(reaction.emoji)
                                                    .font(.system(size: 14))
                                                Text(reaction.oshiName)
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundColor(.primary)
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color(.secondarySystemBackground))
                                            .cornerRadius(16)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        } else {
                            HStack(spacing: 8) {
                                ProgressView().scaleEffect(0.9)
                                Text("いいねを読み込み中...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
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
                    .padding(.bottom, 20) // キーボードとの余白用
                }
            }
            
            // ✅ コメント入力バー (画面下部に固定)
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 12) {
                    TextField("コメントをポスト", text: $commentText)
                        .textFieldStyle(.roundedBorder)
                        .focused($isFocused)
                    
                    Button {
                        let text = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !text.isEmpty {
                            viewModel.addUserComment(to: post, content: text)
                            commentText = ""
                            isFocused = false
                        }
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 20))
                            .foregroundColor(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                    }
                    .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
            }
        }
        .navigationTitle("投稿")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
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
            if viewModel.postDetails[post.id] == nil {
                await viewModel.loadPostDetails(for: post.id)
            }
        }
        // ✅ 追加: 画面が表示されたらフォーカスを当てる
        .onAppear {
            if focusOnAppear {
                // 画面遷移のアニメーション完了を少し待ってからフォーカス
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isFocused = true
                }
            }
        }
    }
}

//
//  PostDetailView.swift
//  AIsns
//
//  Updated: 2026/01/02 - Complete UI/UX Redesign
//

import SwiftUI

struct PostDetailView: View {
    let post: Post
    @ObservedObject var viewModel: OshiViewModel
    
    var focusOnAppear: Bool = false
    @Environment(\.dismiss) var dismiss

    @State private var commentText = ""
    @FocusState private var isFocused: Bool
    @State private var isSubmitting = false

    var postDetails: PostDetails? {
        viewModel.postDetails[post.id]
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    // 投稿本文
                    PostCardView(post: post, viewModel: viewModel, isNavigable: false)
                    
                    AppDivider()
                    
                    // コメントセクション
                    commentsSection
                }
            }
            
            // コメント入力バー
            commentInputBar
        }
        .background(AppColors.backgroundPrimary)
        .onTapGesture {
            UIApplication.shared.endEditing()
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
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
        .task {
            if viewModel.postDetails[post.id] == nil {
                await viewModel.loadPostDetails(for: post.id)
            }
        }
        .onAppear {
            if focusOnAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isFocused = true
                }
            }
        }
    }
    
    // MARK: - Engagement Section
    
    private var engagementSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            // 統計バー
            HStack(spacing: DesignTokens.Spacing.xl) {
                engagementStat(count: post.reactionCount, label: "いいね")
                engagementStat(count: post.commentCount, label: "コメント")
                engagementStat(count: post.repostCount, label: "リポスト")
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.top, DesignTokens.Spacing.md)
            
            AppDivider()
            
            // アクションボタン
            HStack(spacing: 0) {
                engagementButton(
                    icon: "bubble.left",
                    isActive: false,
                    activeColor: AppColors.primary
                ) {
                    isFocused = true
                }
                
                Spacer()
                
                engagementButton(
                    icon: "arrow.2.squarepath",
                    isActive: viewModel.isReposted(post),
                    activeColor: AppColors.success
                ) {
                    generateHapticFeedback()
                    viewModel.toggleRepost(for: post)
                }
                
                Spacer()
                
                engagementButton(
                    icon: "heart",
                    isActive: viewModel.hasUserReacted(to: post),
                    activeColor: AppColors.pink
                ) {
                    generateHapticFeedback()
                    viewModel.toggleUserReaction(on: post)
                }
                
                Spacer()
                
                engagementButton(
                    icon: "bookmark",
                    isActive: viewModel.isBookmarked(post),
                    activeColor: AppColors.primary
                ) {
                    generateHapticFeedback()
                    viewModel.toggleBookmark(for: post)
                }
                
                Spacer()
                
                engagementButton(
                    icon: "square.and.arrow.up",
                    isActive: false,
                    activeColor: AppColors.primary
                ) {
                    // シェア
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .padding(.vertical, DesignTokens.Spacing.sm)
            
            AppDivider()
            
            // いいねした人のアバター
            if let details = postDetails, !details.reactions.isEmpty {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("いいねした人")
                        .font(AppTypography.captionMedium)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, DesignTokens.Spacing.md)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            ForEach(details.reactions) { reaction in
                                ReactionUserChip(reaction: reaction)
                            }
                        }
                        .padding(.horizontal, DesignTokens.Spacing.md)
                    }
                }
                .padding(.vertical, DesignTokens.Spacing.sm)
            }
        }
    }
    
    private func engagementStat(count: Int, label: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.xxs) {
            Text("\(count)")
                .font(AppTypography.subheadlineMedium)
                .foregroundColor(AppColors.textPrimary)
            Text(label)
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textSecondary)
        }
    }
    
    private func engagementButton(
        icon: String,
        isActive: Bool,
        activeColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: isActive ? "\(icon).fill" : icon)
                .font(.system(size: DesignTokens.IconSize.lg))
                .foregroundColor(isActive ? activeColor : AppColors.textSecondary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Comments Section
    
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            // セクションヘッダー
            HStack {
                Text("コメント")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                if let details = postDetails, !details.comments.isEmpty {
                    Text("\(details.comments.count)")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.top, DesignTokens.Spacing.md)
            
            // コメント一覧
            if let details = postDetails {
                if details.comments.isEmpty {
                    emptyCommentsView
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(details.comments) { comment in
                            CommentRowView(comment: comment, viewModel: viewModel)
                            
                            if comment.id != details.comments.last?.id {
                                AppDivider(leadingPadding: 60)
                            }
                        }
                        
                        // さらに読み込むボタン
                        if details.hasMoreComments {
                            Button {
                                Task {
                                    await viewModel.loadMoreComments(for: post.id)
                                }
                            } label: {
                                HStack(spacing: DesignTokens.Spacing.xs) {
                                    Image(systemName: "arrow.down.circle")
                                        .font(.system(size: 14))
                                    Text("さらに表示")
                                        .font(AppTypography.subheadlineMedium)
                                }
                                .foregroundColor(AppColors.primary)
                                .padding(.vertical, DesignTokens.Spacing.md)
                            }
                        }
                    }
                }
            } else {
                // ローディング
                VStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(0..<3, id: \.self) { _ in
                        commentSkeletonView
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
            }
        }
        .padding(.bottom, DesignTokens.Spacing.xl)
    }
    
    private var emptyCommentsView: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 36, weight: .light))
                .foregroundColor(AppColors.textTertiary)
            
            Text("まだコメントはありません")
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textSecondary)
            
            Text("最初のコメントを投稿してみましょう")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Spacing.xxxl)
    }
    
    private var commentSkeletonView: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
            SkeletonView(width: 36, height: 36, cornerRadius: 18)
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                SkeletonView(width: 100, height: 14)
                SkeletonView(width: 200, height: 12)
                SkeletonView(width: 150, height: 12)
            }
            
            Spacer()
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
    }
    
    // MARK: - Comment Input Bar
    
    private var commentInputBar: some View {
        VStack(spacing: 0) {
            AppDivider()
            
            HStack(spacing: DesignTokens.Spacing.sm) {
                // 入力フィールド
                HStack(spacing: DesignTokens.Spacing.xs) {
                    TextField("コメントを追加...", text: $commentText, axis: .vertical)
                        .font(AppTypography.body)
                        .focused($isFocused)
                        .lineLimit(1...4)
                    
                    // 絵文字ボタン
                    Button {
                        // 絵文字選択
                    } label: {
                        Image(systemName: "face.smiling")
                            .font(.system(size: 18))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.sm)
                .padding(.vertical, DesignTokens.Spacing.xs + 2)
                .background(AppColors.backgroundSecondary)
                .cornerRadius(DesignTokens.Radius.xl)
                
                // 送信ボタン
                Button {
                    submitComment()
                } label: {
                    Group {
                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .frame(width: 36, height: 36)
                    .background(
                        canSubmit
                        ? AppColors.primaryGradient
                        : LinearGradient(colors: [AppColors.textTertiary], startPoint: .top, endPoint: .bottom)
                    )
                    .clipShape(Circle())
                    .foregroundColor(.white)
                }
                .disabled(!canSubmit || isSubmitting)
                .pressableStyle()
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(AppColors.backgroundPrimary)
        }
    }
    
    private var canSubmit: Bool {
        !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func submitComment() {
        let text = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        isSubmitting = true
        generateHapticFeedback()
        
        viewModel.addUserComment(to: post, content: text)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            commentText = ""
            isFocused = false
            isSubmitting = false
        }
    }
}

// MARK: - Reaction User Chip

struct ReactionUserChip: View {
    let reaction: Reaction
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Text(reaction.emoji)
                .font(.system(size: 14))
            
            Text(reaction.oshiName)
                .font(AppTypography.captionMedium)
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(DesignTokens.Radius.full)
    }
}

// MARK: - Comment Row View

struct CommentRowView: View {
    let comment: Comment
    @ObservedObject var viewModel: OshiViewModel
    @State private var avatarImage: UIImage?
    @State private var isLiked = false
    
    var isUser: Bool {
        comment.oshiId == UUID(uuidString: "00000000-0000-0000-0000-000000000001")
    }
    
    var oshi: OshiCharacter? {
        viewModel.oshiList.first { $0.id == comment.oshiId }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
            // アバター
            avatarView
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                // ヘッダー
                HStack(spacing: DesignTokens.Spacing.xxs) {
                    Text(comment.oshiName)
                        .font(AppTypography.subheadlineMedium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("·")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                    
                    RelativeTimeText(date: comment.timestamp)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                // コメント本文
                Text(comment.content)
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textPrimary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                // アクションボタン
                HStack(spacing: DesignTokens.Spacing.lg) {
                    Button {
                        generateHapticFeedback()
                        withAnimation(DesignTokens.Animation.bouncy) {
                            isLiked.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 12))
                                .foregroundColor(isLiked ? AppColors.pink : AppColors.textTertiary)
                            
                            if isLiked {
                                Text("1")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textTertiary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        // 返信
                    } label: {
                        Text("返信")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, DesignTokens.Spacing.xxs)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .task {
            await loadAvatar()
        }
    }
    
    @ViewBuilder
    private var avatarView: some View {
        if isUser {
            AvatarView(
                image: avatarImage,
                name: comment.oshiName,
                size: DesignTokens.AvatarSize.sm + 4,
                placeholderGradient: AppColors.primaryGradient
            )
        } else if let oshi = oshi {
            AvatarView(
                image: avatarImage,
                name: oshi.name,
                size: DesignTokens.AvatarSize.sm + 4,
                placeholderGradient: AppColors.pinkGradient
            )
        } else {
            AvatarView(
                image: nil,
                name: comment.oshiName,
                size: DesignTokens.AvatarSize.sm + 4,
                placeholderGradient: AppColors.primaryGradient
            )
        }
    }
    
    private func loadAvatar() async {
        if isUser {
            if let url = viewModel.userProfileAvatarURL {
                avatarImage = try? await FirebaseStorageManager.shared.downloadImage(from: url)
            }
        } else if let oshi = oshi, let urlString = oshi.avatarImageURL {
            avatarImage = try? await FirebaseStorageManager.shared.downloadImage(from: urlString)
        }
    }
}

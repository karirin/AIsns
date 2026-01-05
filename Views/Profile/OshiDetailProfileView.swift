//
//  OshiProfileDetailView.swift
//  AIsns
//
//  Updated: 2026/01/02 - Complete UI/UX Redesign
//

import SwiftUI

struct OshiProfileDetailView: View {
    let oshi: OshiCharacter
    @ObservedObject var viewModel: OshiViewModel
    @Environment(\.dismiss) var dismiss
    
    let isPreset: Bool
    
    @State private var avatarImage: UIImage?
    @State private var isLoadingImage = false
    @State private var showingEditSheet = false
    @State private var showingUnfollowAlert = false
    @State private var isFollowing = false
    
    private let avatarSize: CGFloat = 100
    
    var oshiPosts: [Post] {
        viewModel.posts.filter { $0.authorId == oshi.id }
    }
    
    var isAlreadyFollowed: Bool {
        if let existingOshi = viewModel.oshiList.first(where: { $0.id == oshi.id }) {
            return existingOshi.isFollowedByUser
        }
        return false
    }
    
    init(oshi: OshiCharacter, viewModel: OshiViewModel, isPreset: Bool = false) {
        self.oshi = oshi
        self.viewModel = viewModel
        self.isPreset = isPreset
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: DesignTokens.Spacing.xl) {
                // ヘッダーエリア（アバター + 統計）
                profileHeader
                
                // プロフィール情報
                profileInfoSection
                
                // フォローボタン
                followButtonSection
                
                AppDivider()
                    .padding(.horizontal, DesignTokens.Spacing.xl)
                
                // 投稿セクション
                postsSection
            }
            .padding(.bottom, DesignTokens.Spacing.xxl)
        }
        .background(AppColors.backgroundPrimary)
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
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("プロフィールを編集", systemImage: "pencil")
                    }
                    
                    if !isPreset {
                        Button(role: .destructive) {
                            showingUnfollowAlert = true
                        } label: {
                            Label("フォロー解除", systemImage: "person.badge.minus")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                OshiProfileEditView(
                    oshi: oshi,
                    viewModel: viewModel,
                    isPreset: isPreset
                )
            }
        }
        .alert("フォロー解除", isPresented: $showingUnfollowAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("解除", role: .destructive) {
                viewModel.deleteOshi(oshi)
                dismiss()
            }
        } message: {
            Text("\(oshi.name)のフォローを解除しますか?")
        }
        .task {
            await loadAvatar()
        }
    }
    
    // MARK: - Load Avatar
    
    private func loadAvatar() async {
        avatarImage = nil
        
        if let urlString = oshi.avatarImageURL, !urlString.isEmpty {
            isLoadingImage = true
            avatarImage = try? await FirebaseStorageManager.shared.downloadImage(from: urlString)
            isLoadingImage = false
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // アバター
            ZStack {
                // グラデーションリング
                Circle()
                    .stroke(AppColors.primaryGradient, lineWidth: 3)
                    .frame(width: avatarSize + 12, height: avatarSize + 12)
                
                if isLoadingImage {
                    SkeletonView(width: avatarSize, height: avatarSize, cornerRadius: avatarSize / 2)
                } else {
                    AvatarView(
                        image: avatarImage,
                        name: oshi.name,
                        size: avatarSize,
                        placeholderGradient: AppColors.pinkGradient
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                }
            }
            .padding(.top, DesignTokens.Spacing.md)
        }
    }
    
    // MARK: - Profile Info Section
    
    private var profileInfoSection: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            // 名前
            Text(oshi.name)
                .font(AppTypography.title2)
                .foregroundColor(AppColors.textPrimary)
            
            // 自己紹介
            if !oshi.speechCharacteristics.isEmpty {
                Text(oshi.speechCharacteristics)
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, DesignTokens.Spacing.xxl)
            }
            
            // 相互フォロー表示
            if oshi.isMutualFollow {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 12))
                    Text("相互フォロー")
                        .font(AppTypography.footnote)
                }
                .foregroundColor(AppColors.textSecondary)
                .padding(.top, DesignTokens.Spacing.xxs)
            } else if oshi.isFollowingUser {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12))
                    Text("フォローされています")
                        .font(AppTypography.footnote)
                }
                .foregroundColor(AppColors.textSecondary)
                .padding(.top, DesignTokens.Spacing.xxs)
            }
            
            NavigationLink {
                FollowListView(
                    title: "フォロワー",
                    type: .followers(oshiId: oshi.id),
                    viewModel: viewModel
                )
            } label: {
                HStack {
                    Text("フォロワー")
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(oshi.followerCount)人")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            Divider()
                .padding(.leading, 16)
            
            // キャラクタータグ
            characterTagsView
                .padding(.top, DesignTokens.Spacing.xs)
        }
    }
    
    // MARK: - Character Tags
    
    private var characterTagsView: some View {
        FlowLayout(spacing: DesignTokens.Spacing.xs) {
            if let gender = oshi.gender {
                AppTagView(text: gender.rawValue, icon: nil, style: .default)
            }
            
            if !oshi.personalityText.isEmpty {
                ForEach(splitTags(oshi.personalityText), id: \.self) { tag in
                    AppTagView(text: tag, icon: "heart.fill", style: .pink)
                }
            }
            
            if !oshi.speechStyleText.isEmpty {
                ForEach(splitTags(oshi.speechStyleText), id: \.self) { tag in
                    AppTagView(text: tag, icon: "text.bubble.fill", style: .primary)
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.xl)
    }
    
    private func splitTags(_ text: String) -> [String] {
        text.components(separatedBy: CharacterSet(charactersIn: "。、"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
    
    // MARK: - Follow Button Section
    
    private var followButtonSection: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            if isAlreadyFollowed {
                // フォロー中
                Button {
                    showingUnfollowAlert = true
                } label: {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                        Text("フォロー中")
                            .font(AppTypography.bodyMedium)
                    }
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                            .stroke(AppColors.border, lineWidth: 1.5)
                    )
                }
            } else {
                // フォローボタン
                Button {
                    Task {
                        isFollowing = true
                        defer { isFollowing = false }
                        
                        // 👇 修正: リストに存在するかどうかで処理を分岐
                        if viewModel.oshiList.contains(where: { $0.id == oshi.id }) {
                            // 既にリストにある（がフォローフラグが外れている）場合
                            await viewModel.followOshi(oshi)
                        } else {
                            // リストにない新規ユーザーの場合（プリセット、または公開投稿のユーザー）
                            // followRecommended は引数のキャラクターを新規保存してチャットルームを作成してくれるため、ここでも使用できます
                            await viewModel.followRecommended(oshi)
                        }
                    }
                } label: {
                    if isFollowing {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignTokens.Spacing.sm)
                            .background(AppColors.primary.opacity(0.7))
                            .cornerRadius(DesignTokens.Radius.xl)
                    } else {
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            Image(systemName: "person.fill.badge.plus")
                                .font(.system(size: 14, weight: .semibold))
                            Text("フォロー")
                                .font(AppTypography.bodyMedium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignTokens.Spacing.sm)
                        .background(AppColors.primaryGradientH)
                        .cornerRadius(DesignTokens.Radius.xl)
                    }
                }
                .disabled(isFollowing)
            }
            
            // メッセージボタン
            Button {
                // チャットへ遷移
            } label: {
                Image(systemName: "message.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(AppColors.backgroundSecondary)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.xl)
    }
    
    // MARK: - Posts Section
    
    private var postsSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // セクションヘッダー
            SectionHeader(
                title: "ポスト",
                icon: "square.text.square",
                iconColor: AppColors.primary
            )
            .padding(.horizontal, DesignTokens.Spacing.xl)
            
            if !oshiPosts.isEmpty {
                Text("\(oshiPosts.count)件")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, DesignTokens.Spacing.xl)
                    .padding(.top, -DesignTokens.Spacing.sm)
            }
            
            if oshiPosts.isEmpty {
                EmptyStateView(
                    icon: "bubble.left.and.bubble.right",
                    title: "まだポストがありません",
                    subtitle: "チャットを始めると、ここに表示されます"
                )
                .frame(height: 250)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(oshiPosts) { post in
                        PostCardView(post: post, viewModel: viewModel)
                        
                        if post.id != oshiPosts.last?.id {
                            AppDivider(leadingPadding: 68)
                        }
                    }
                }
                .background(AppColors.backgroundPrimary)
            }
        }
    }
}

// MARK: - Flow Layout (既存)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(x: bounds.minX + result.positions[index].x,
                           y: bounds.minY + result.positions[index].y),
                proposal: .unspecified
            )
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            var rowWidth: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                rowWidth = max(rowWidth, x - spacing)
            }
            
            size = CGSize(width: rowWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Tag View (既存互換)

struct TagView: View {
    let text: String
    let icon: String
    
    var body: some View {
        AppTagView(text: text, icon: icon.count <= 2 ? nil : icon, style: .default)
    }
}

#Preview {
    NavigationStack {
        OshiProfileDetailView(
            oshi: OshiCharacter(
                name: "さくら",
                gender: .female,
                personalityText: "優しくて明るい",
                speechCharacteristics: "アプリの個人開発してます 🌸 いつも応援ありがとう!",
                userCallingName: "あなた",
                speechStyleText: "敬語"
            ),
            viewModel: OshiViewModel(),
            isPreset: false
        )
    }
}

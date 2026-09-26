//
//  OshiListView.swift
//  AIsns
//
//  Updated: 2026/01/02 - Complete UI/UX Redesign
//

import SwiftUI

struct OshiListView: View {
    @ObservedObject var viewModel: OshiViewModel
    
    @State private var selectedTab: Int = 0
    @State private var showCreatedOnly = false
    @Namespace private var animation
    @Binding var isPresented: Bool
    @Environment(\.dismiss) var dismiss
    private let dbManager = FirebaseDatabaseManager.shared
    @ObservedObject var adViewModel: AdViewModel
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    // カスタムタブバー
                    PillSegmentedControl(
                        items: [(value: 0, label: "フォロワー"), (value: 1, label: "フォロー中")],
                        selection: $selectedTab,
                        onChange: { _ in generateHapticFeedback() }
                    )
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, DesignTokens.Spacing.xs)
                    .zIndex(1)

                    createdOnlyFilter
                    
                    if viewModel.shouldShowAds {
                        BannerAdView()
                            .frame(width: 320, height: 50)
                            .frame(maxWidth: .infinity) // 横幅いっぱいの領域の中で中央寄せ
                            .padding(.vertical, 4)
                            .background(Color(.systemBackground))
                    }
                    // コンテンツエリア
                    TabView(selection: $selectedTab) {
                        OshiListPage(
                            oshis: filteredOshis(viewModel.oshiList.filter { $0.isFollowingUser }),
                            emptyTitle: "フォロワーはいません",
                            emptySubtitle: "投稿してフォローしてもらいましょう",
                            iconName: "person.2.slash",
                            viewModel: viewModel
                        )
                        .tag(0)
                        
                        OshiListPage(
                            oshis: filteredOshis(viewModel.oshiList.filter { $0.isFollowedByUser }),
                            emptyTitle: "フォロー中のアカウントはいません",
                            emptySubtitle: "気になるアカウントを見つけてフォローしましょう",
                            iconName: "person.slash",
                            viewModel: viewModel
                        )
                        .tag(1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(DesignTokens.Animation.spring, value: selectedTab)
                }
                .background(AuroraBackground())
                
                // アカウント追加ボタン
                NavigationLink(destination: OshiCreationView(viewModel: viewModel, adViewModel: adViewModel)) {
                    ZStack {
                        Circle()
                            .fill(AppColors.primaryGradient)
                            .frame(width: 56, height: 56)
                            .shadow(color: AppColors.primary.opacity(0.4), radius: 12, x: 0, y: 6)
                        
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.trailing, DesignTokens.Spacing.lg)
                .padding(.bottom, DesignTokens.Spacing.lg)

            }
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
                    if isPresented {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .navigationBarBackButtonHidden(true)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 80 {
                        dismiss()
                    }
                }
        )
    }

    private var createdOnlyFilter: some View {
        HStack {
            Button {
                generateHapticFeedback()
                guard viewModel.isPlusActive else {
                    viewModel.requestPlusPaywall(.premiumFeature, force: true)
                    return
                }
                withAnimation(DesignTokens.Animation.spring) {
                    showCreatedOnly.toggle()
                }
            } label: {
                Label(
                    showCreatedOnly ? "自作だけ" : "すべて表示",
                    systemImage: viewModel.isPlusActive
                        ? (showCreatedOnly ? "checkmark.circle.fill" : "line.3.horizontal.decrease.circle")
                        : "lock.fill"
                )
                    .font(AppTypography.footnoteMedium)
                    .foregroundColor(showCreatedOnly ? .white : AppColors.textPrimary)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, 8)
                    .background {
                        Capsule().fill(showCreatedOnly ? AppColors.primary : AppColors.surfaceSecondary)
                    }
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.bottom, DesignTokens.Spacing.xs)
    }

    private func filteredOshis(_ oshis: [OshiCharacter]) -> [OshiCharacter] {
        guard showCreatedOnly else { return oshis }
        return oshis.filter { viewModel.isUserCreatedOshi($0) }
    }

}

// MARK: - Oshi List Page

struct OshiListPage: View {
    let oshis: [OshiCharacter]
    let emptyTitle: String
    let emptySubtitle: String
    let iconName: String
    @ObservedObject var viewModel: OshiViewModel
    
    var body: some View {
        if oshis.isEmpty {
            EmptyStateView(
                icon: iconName,
                title: emptyTitle,
                subtitle: emptySubtitle
            )
        } else {
            ScrollView {
                LazyVStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(oshis) { oshi in
                        NavigationLink(destination: OshiProfileDetailView(oshi: oshi, viewModel: viewModel, isPreset: false)) {
                            OshiListRowWithButton(oshi: oshi, viewModel: viewModel)
                                .floatingCardStyle()
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, DesignTokens.Spacing.sm)
                    }
                }
                .padding(.vertical, DesignTokens.Spacing.sm)
                .padding(.bottom, 90)
            }
        }
    }
}

// MARK: - Oshi List Row

struct OshiListRowWithButton: View {
    let oshi: OshiCharacter
    @ObservedObject var viewModel: OshiViewModel
    @State private var showingUnfollowAlert = false
    @State private var showingDeleteAlert = false
    @State private var avatarImage: UIImage?
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            // アイコン
            AvatarView(
                image: avatarImage,
                name: oshi.name,
                size: DesignTokens.AvatarSize.lg,
                placeholderGradient: AppColors.pinkGradient
            )
            .task {
                if let urlString = oshi.avatarImageURL {
                    avatarImage = try? await FirebaseStorageManager.shared.downloadImage(from: urlString)
                }
            }
            
            // 名前と自己紹介
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Text(oshi.name)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    // 相互フォローバッジ
                    if oshi.isMutualFollow {
                        Text("相互")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppColors.primaryGradientH)
                            .cornerRadius(DesignTokens.Radius.xs)
                    }
                }
                
                Text(oshi.personalityText.isEmpty ? "自己紹介文なし" : oshi.personalityText)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)

                IntimacyProgressView(oshi: oshi, compact: true)
            }
            
            Spacer()

            Menu {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("削除", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 36, height: 36)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            
            // フォローボタン
            Button {
                generateHapticFeedback()
                if oshi.isFollowedByUser {
                    showingUnfollowAlert = true
                } else {
                    Task {
                        await viewModel.followOshi(oshi)
                    }
                }
            } label: {
                Text(oshi.isFollowedByUser ? "フォロー中" : "フォロー")
                    .font(AppTypography.footnoteMedium)
                    .foregroundColor(oshi.isFollowedByUser ? AppColors.textSecondary : .white)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, 7)
                    .background {
                        if oshi.isFollowedByUser {
                            Capsule().fill(AppColors.surfaceSecondary)
                        } else {
                            Capsule().fill(AppColors.primaryGradientH)
                        }
                    }
            }
            .buttonStyle(PlainButtonStyle())
            .alert("フォロー解除", isPresented: $showingUnfollowAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("解除", role: .destructive) {
                    Task {
                        await viewModel.unfollowOshi(oshi)
                    }
                }
            } message: {
                Text("\(oshi.name)のフォローを解除しますか?")
            }
            .alert("アカウントを削除しますか?", isPresented: $showingDeleteAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("削除", role: .destructive) {
                    viewModel.deleteOshi(oshi)
                }
            } message: {
                Text("\(oshi.name)の投稿とDM履歴も削除されます。")
            }
        }
        .padding(DesignTokens.Spacing.md)
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let title: String
    let tag: Int
    @Binding var selectedTab: Int
    var namespace: Namespace.ID
    
    var body: some View {
        Button {
            generateHapticFeedback()
            withAnimation(DesignTokens.Animation.spring) {
                selectedTab = tag
            }
        } label: {
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text(title)
                    .font(selectedTab == tag ? AppTypography.bodyMedium : AppTypography.body)
                    .foregroundColor(selectedTab == tag ? AppColors.textPrimary : AppColors.textSecondary)
                
                ZStack {
                    Capsule()
                        .fill(AppColors.borderLight)
                        .frame(height: 2)
                    
                    if selectedTab == tag {
                        Capsule()
                            .fill(AppColors.primaryGradientH)
                            .frame(height: 3)
                            .matchedGeometryEffect(id: "TabIndicator", in: namespace)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    OshiListView(viewModel: OshiViewModel(mock: true), isPresented: .constant(false), adViewModel: AdViewModel())
}

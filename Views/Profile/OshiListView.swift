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
    @Namespace private var animation
    @Binding var isPresented: Bool
    @Environment(\.dismiss) var dismiss
    @State private var helpFlag: Bool = false
    @State private var customerFlag: Bool = false
    private let dbManager = FirebaseDatabaseManager.shared
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    // カスタムタブバー
                    HStack(spacing: 0) {
                        TabButton(title: "フォロワー", tag: 0, selectedTab: $selectedTab, namespace: animation)
                        TabButton(title: "フォロー中", tag: 1, selectedTab: $selectedTab, namespace: animation)
                    }
                    .padding(.top, DesignTokens.Spacing.xs)
                    .background(AppColors.backgroundPrimary)
                    .zIndex(1)
                    
                    // コンテンツエリア
                    TabView(selection: $selectedTab) {
                        OshiListPage(
                            oshis: viewModel.oshiList.filter { $0.isFollowingUser },
                            emptyTitle: "フォロワーはいません",
                            emptySubtitle: "投稿してフォローしてもらいましょう",
                            iconName: "person.2.slash",
                            viewModel: viewModel
                        )
                        .tag(0)
                        
                        OshiListPage(
                            oshis: viewModel.oshiList.filter { $0.isFollowedByUser },
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
                
                // アカウント追加ボタン
                NavigationLink(destination: OshiCreationView(viewModel: viewModel)) {
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
                
                if helpFlag {
                    HelpModalView(isPresented: $helpFlag)
                }
                
                if customerFlag {
                    ReviewView(isPresented: $customerFlag, helpFlag: $helpFlag)
                }
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
        .onAppear{
            dbManager.fetchUserFlag { userFlag, error in
                if let error = error {
                    print(error.localizedDescription)
                } else if let userFlag = userFlag {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        if userFlag == 0 {
                            executeProcessEveryfifTimes()
                            executeProcessEveryThreeTimes()
                        }
                    }
                }
            }
        }
    }
    
    func executeProcessEveryfifTimes() {
        // UserDefaultsからカウンターを取得
        let count = UserDefaults.standard.integer(forKey: "launchHelpCount") + 1
        
        // カウンターを更新
        UserDefaults.standard.set(count, forKey: "launchHelpCount")

        if count % 15 == 0 {
            helpFlag = true
        }
    }

    func executeProcessEveryThreeTimes() {
        // UserDefaultsからカウンターを取得
        let count = UserDefaults.standard.integer(forKey: "launchCount") + 1
        
        // カウンターを更新
        UserDefaults.standard.set(count, forKey: "launchCount")
        
        // 3回に1回の割合で処理を実行
        if count % 10 == 0 {
            customerFlag = true
        }
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
                LazyVStack(spacing: 0) {
                    ForEach(oshis) { oshi in
                        NavigationLink(destination: OshiProfileDetailView(oshi: oshi, viewModel: viewModel, isPreset: false)) {
                            OshiListRowWithButton(oshi: oshi, viewModel: viewModel)
                        }
                        .buttonStyle(.plain)
                        
                        if oshi.id != oshis.last?.id {
                            AppDivider(leadingPadding: 78)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Oshi List Row

struct OshiListRowWithButton: View {
    let oshi: OshiCharacter
    @ObservedObject var viewModel: OshiViewModel
    @State private var showingUnfollowAlert = false
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
            }
            
            Spacer()
            
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
                    .font(AppTypography.captionMedium)
                    .foregroundColor(oshi.isFollowedByUser ? AppColors.textPrimary : .white)
                    .padding(.horizontal, DesignTokens.Spacing.sm)
                    .padding(.vertical, DesignTokens.Spacing.xs)
                    .background(
                        Group {
                            if oshi.isFollowedByUser {
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.full)
                                    .stroke(AppColors.border, lineWidth: 1)
                            } else {
                                Capsule()
                                    .fill(AppColors.primaryGradientH)
                            }
                        }
                    )
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
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(AppColors.backgroundPrimary)
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
    OshiListView(viewModel: OshiViewModel(mock: true), isPresented: .constant(false))
}

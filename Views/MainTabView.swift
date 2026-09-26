//
//  MainTabView.swift
//  AIsns
//

import StoreKit
import SwiftUI

enum Tab {
    case timeline
    case notification
    case chat
    case oshi
}

struct MainTabView: View {
    @Environment(\.requestReview) private var requestReview
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = OshiViewModel()
    @StateObject private var adViewModel = AdViewModel()
    @StateObject private var subscriptionStore = SubscriptionStore()
    @StateObject private var reviewRequestManager = ReviewRequestManager.shared
    @ObservedObject private var localNotificationManager = LocalNotificationManager.shared
    @State private var selectedTab: Tab = .timeline
    @State private var didScheduleInitialAdLoad = false
    
    var totalUnreadCount: Int {
        viewModel.chatRooms.reduce(0) { $0 + $1.unreadCount }
    }
    
    var unreadNotificationCount: Int {
        viewModel.notifications.filter { !$0.isRead }.count
    }
    
    var body: some View {
        // TabView 自体を NavigationView で囲まず、中身の各画面で完結させます
        TabView(selection: $selectedTab) {
            
            // タイムライン
            TimelineScreenView(viewModel: viewModel, adViewModel: adViewModel)
                .tabItem {
                    Label {
                        Text("ホーム")
                    } icon: {
                        Image(systemName: selectedTab == .timeline ? "house.fill" : "house")
                            .environment(\.symbolVariants, .none)
                    }
                }
                .tag(Tab.timeline)

            // 推しリスト
            Group {
                if selectedTab == .oshi {
                    OshiListView(viewModel: viewModel, isPresented: .constant(false), adViewModel: adViewModel)
                } else {
                    Color.clear
                }
            }
                .tabItem {
                    Label {
                        Text("フォロワー")
                    } icon: {
                        Image(systemName: selectedTab == .oshi ? "person.2.fill" : "person.2")
                            .environment(\.symbolVariants, .none)
                    }
                }
                .tag(Tab.oshi)

            // 通知
            // iPadのバグを防ぐため、NavigationStackの外側でスタイルを固定
            Group {
                if selectedTab == .notification {
                    NavigationStack {
                        NotificationView(
                            viewModel: viewModel,
                            isPresented: .constant(false)
                        )
                    }
                } else {
                    Color.clear
                }
            }
            .tabItem {
                Label {
                    Text("通知")
                } icon: {
                    Image(systemName: selectedTab == .notification ? "bell.fill" : "bell")
                        .environment(\.symbolVariants, .none)
                }
            }
            .badge(unreadNotificationCount > 0 ? unreadNotificationCount : 0)
            .tag(Tab.notification)

            // チャット
            Group {
                if selectedTab == .chat {
                    ChatListView(viewModel: viewModel, isPresented: .constant(false), adViewModel: adViewModel)
                } else {
                    Color.clear
                }
            }
                .tabItem {
                    Label {
                        Text("メッセージ")
                    } icon: {
                        Image(systemName: selectedTab == .chat ? "envelope.fill" : "envelope")
                            .environment(\.symbolVariants, .none)
                    }
                }
                .badge(totalUnreadCount > 0 ? totalUnreadCount : 0)
                .tag(Tab.chat)
        }
        .tint(AppColors.primary)
        .onChange(of: selectedTab) { _ in
            generateHapticFeedback()
        }
        .onReceive(localNotificationManager.$pendingDestination) { destination in
            guard let destination else { return }
            switch destination {
            case .chat: selectedTab = .chat
            case .notifications: selectedTab = .notification
            }
            localNotificationManager.pendingDestination = nil
        }
        .environmentObject(subscriptionStore)
        .sheet(item: $viewModel.plusPaywallPresentation) { _ in
            PlusPaywallView()
                .environmentObject(subscriptionStore)
        }
        .alert("返事が来たら知らせますか？", isPresented: $viewModel.shouldPromptForNotificationPermission) {
            Button("今はしない", role: .cancel) { }
            Button("知らせる") {
                Task {
                    if await LocalNotificationManager.shared.requestAuthorization() {
                        viewModel.handleAppBecameActive()
                    }
                }
            }
        } message: {
            Text("推しからコメントやメッセージが届いたときに通知します。通知は設定からいつでも変更できます。")
        }
        .overlay(alignment: .top) {
            if let message = viewModel.errorMessage {
                ToastView(message: message, icon: "exclamationmark", style: .error)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    .padding(.top, DesignTokens.Spacing.sm)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onTapGesture {
                        withAnimation { viewModel.errorMessage = nil }
                    }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityHint("タップして閉じる")
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.errorMessage)
        .task(id: viewModel.errorMessage) {
            // 表示から数秒で自動的に閉じる（その間に別のエラーが来たら、そちらの表示時間を使う）
            guard let shownMessage = viewModel.errorMessage else { return }
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard !Task.isCancelled, viewModel.errorMessage == shownMessage else { return }
            viewModel.errorMessage = nil
        }
        // ここが重要：iPadで全体の挙動をスタックに固定する（互換性のためNavigationViewStyleも併記）
        .navigationViewStyle(.stack)
        .onAppear {
            setupTabBarAppearance()
            viewModel.setPlusActive(subscriptionStore.isPlusActive)
            viewModel.handleAppBecameActive()
            reviewRequestManager.recordAppSession()
            scheduleInitialAdLoadIfNeeded()
        }
        .task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            await subscriptionStore.refreshEntitlements()
            viewModel.setPlusActive(subscriptionStore.isPlusActive)
            try? await Task.sleep(nanoseconds: 700_000_000)
            viewModel.recordAppLaunchForPlusPaywall()
        }
        .onChange(of: subscriptionStore.isPlusActive) { isPlusActive in
            viewModel.setPlusActive(isPlusActive)
            if !isPlusActive {
                scheduleInitialAdLoadIfNeeded()
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                viewModel.handleAppBecameActive()
            }
        }
        .onChange(of: reviewRequestManager.requestRevision) { _ in
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                guard reviewRequestManager.consumePendingRequest() else { return }
                requestReview()
            }
        }
    }

    private func scheduleInitialAdLoadIfNeeded() {
        guard viewModel.shouldShowAds, !didScheduleInitialAdLoad else { return }
        didScheduleInitialAdLoad = true

        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard viewModel.shouldShowAds else { return }
            await MainActor.run {
                adViewModel.loadNativeAd()
            }
        }
    }
    
    private func setupTabBarAppearance() {
        // すりガラス（ブラー）背景でコンテンツの奥行きを見せる
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)

        let selectedColor = UIColor(AppColors.primary)
        let unselectedColor = UIColor.secondaryLabel
        let selectedFont = UIFont.systemFont(ofSize: 10, weight: .semibold)
        let normalFont = UIFont.systemFont(ofSize: 10, weight: .medium)

        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedColor,
            .font: selectedFont
        ]
        appearance.stackedLayoutAppearance.normal.iconColor = unselectedColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: unselectedColor,
            .font: normalFont
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    MainTabView()
}

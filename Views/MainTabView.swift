//
//  MainTabView.swift
//  AIsns
//

import SwiftUI

enum Tab {
    case timeline
    case notification
    case chat
    case oshi
}

struct MainTabView: View {
    @StateObject private var viewModel = OshiViewModel()
    @StateObject private var adViewModel = AdViewModel()
    @State private var selectedTab: Tab = .timeline
    
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
                    Image(systemName: selectedTab == .timeline ? "house.fill" : "house")
                        .environment(\.symbolVariants, .none)
                }
                .tag(Tab.timeline)
            
            // 推しリスト
            OshiListView(viewModel: viewModel, isPresented: .constant(false))
                .tabItem {
                    Image(systemName: selectedTab == .oshi ? "person.2.fill" : "person.2")
                        .environment(\.symbolVariants, .none)
                }
                .tag(Tab.oshi)
            
            // 通知
            // iPadのバグを防ぐため、NavigationStackの外側でスタイルを固定
            NavigationStack {
                NotificationView(
                    viewModel: viewModel,
                    isPresented: .constant(false)
                )
            }
            .tabItem {
                Image(systemName: selectedTab == .notification ? "bell.fill" : "bell")
                    .environment(\.symbolVariants, .none)
            }
            .badge(unreadNotificationCount > 0 ? unreadNotificationCount : 0)
            .tag(Tab.notification)
            
            // チャット
            ChatListView(viewModel: viewModel, isPresented: .constant(false), adViewModel: adViewModel)
                .tabItem {
                    Image(systemName: selectedTab == .chat ? "envelope.fill" : "envelope")
                        .environment(\.symbolVariants, .none)
                }
                .badge(totalUnreadCount > 0 ? totalUnreadCount : 0)
                .tag(Tab.chat)
        }
        .tint(AppColors.primary)
        // ここが重要：iPadで全体の挙動をスタックに固定する（互換性のためNavigationViewStyleも併記）
        .navigationViewStyle(.stack)
        .onAppear {
            setupTabBarAppearance()
            adViewModel.loadNativeAd()
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        let selectedColor = UIColor(AppColors.primary)
        let unselectedColor = UIColor.secondaryLabel
        
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        appearance.stackedLayoutAppearance.normal.iconColor = unselectedColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: unselectedColor]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

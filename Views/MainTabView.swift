//
//  MainTabView.swift
//  AIsns
//
//  Updated: 2026/01/02 - Complete UI/UX Redesign
//

import SwiftUI

// タブの識別用Enum
enum Tab {
    case timeline
    case notification
    case chat
    case oshi
}

struct MainTabView: View {
    @StateObject private var viewModel = OshiViewModel()
    @State private var selectedTab: Tab = .timeline
    
    var totalUnreadCount: Int {
        viewModel.chatRooms.reduce(0) { $0 + $1.unreadCount }
    }
    
    var unreadNotificationCount: Int {
        viewModel.notifications.filter { !$0.isRead }.count
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TimelineScreenView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: selectedTab == .timeline ? "house.fill" : "house")
                        .environment(\.symbolVariants, .none)
                }
                .tag(Tab.timeline)
            
            OshiListView(viewModel: viewModel, isPresented: .constant(false))
                .tabItem {
                    Image(systemName: selectedTab == .oshi ? "person.2.fill" : "person.2")
                        .environment(\.symbolVariants, .none)
                }
                .tag(Tab.oshi)
            
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
        
            ChatListView(viewModel: viewModel, isPresented: .constant(false))
                .tabItem {
                    Image(systemName: selectedTab == .chat ? "envelope.fill" : "envelope")
                        .environment(\.symbolVariants, .none)
                }
                .badge(totalUnreadCount > 0 ? totalUnreadCount : 0)
                .tag(Tab.chat)
        }
        .tint(AppColors.primary)
        .onAppear {
            setupTabBarAppearance()
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        // 選択時のカラー
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

// MARK: - Haptic Feedback

func generateHapticFeedback() {
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.impactOccurred()
}

// MARK: - Preview

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}

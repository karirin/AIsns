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
    // 選択中のタブを管理
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
                    // ✅ 文字を削除し、アイコンのみ指定
                    Image(systemName: "house.fill")
                }
                .tag(Tab.timeline)
            
            OshiListView(viewModel: viewModel, isPresented: .constant(false))
                .tabItem {
                    // ✅ 文字を削除し、アイコンのみ指定
                    Image(systemName: "person.2")
                }
                .tag(Tab.oshi)
            
            // 通知タブ
            NavigationStack {
                NotificationView(
                    viewModel: viewModel,
                    isPresented: .constant(false)
                )
            }
            .tabItem {
                // ✅ 文字を削除し、アイコンのみ指定
                Image(systemName: "bell.fill")
            }
            .badge(unreadNotificationCount > 0 ? unreadNotificationCount : 0)
            .tag(Tab.notification)
        
            ChatListView(viewModel: viewModel, isPresented: .constant(false))
                .tabItem {
                    // ✅ 文字を削除し、アイコンのみ指定
                    Image(systemName: "envelope")
                }
                .badge(totalUnreadCount > 0 ? totalUnreadCount : 0)
                .tag(Tab.chat)
        }
        .onAppear {
            setupTabBarAppearance()
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

func generateHapticFeedback() {
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.impactOccurred()
}

// プレビュー
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}

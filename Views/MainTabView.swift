import SwiftUI

struct MainTabView: View {
    @StateObject private var viewModel = OshiViewModel()
    
    var totalUnreadCount: Int {
        viewModel.chatRooms.reduce(0) { $0 + $1.unreadCount }
    }
    
    var body: some View {
        TabView {
            TimelineView(viewModel: viewModel)
                .tabItem {
                    Label("タイムライン", systemImage: "house.fill")
                }
            
            ChatListView(viewModel: viewModel)
                .tabItem {
                    Label("チャット", systemImage: "message.fill")
                }
                .badge(totalUnreadCount > 0 ? totalUnreadCount : 0)
            
            OshiListView(viewModel: viewModel)
                .tabItem {
                    Label("推し", systemImage: "star.fill")
                }
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

// プレビュー
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}

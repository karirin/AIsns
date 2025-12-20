import SwiftUI
//import FirebaseCore

@main
struct OshiSNSApp: App {
    
    init() {
        // Firebase初期化
//        FirebaseConfig.shared.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}

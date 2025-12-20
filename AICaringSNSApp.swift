import SwiftUI
import FirebaseCore

@main
struct OshiSNSApp: App {
    
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}

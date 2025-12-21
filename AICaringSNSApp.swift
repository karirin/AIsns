// OshiSNSApp.swift

import SwiftUI
import FirebaseCore
import FirebaseDatabase
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        Database.database().isPersistenceEnabled = true
        return true
    }
}

@main
struct OshiSNSApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}

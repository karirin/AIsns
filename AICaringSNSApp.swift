// OshiSNSApp.swift

import SwiftUI
import FirebaseAppCheck
import FirebaseCore
import FirebaseDatabase
import GoogleMobileAds
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        #if targetEnvironment(simulator)
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        #else
        AppCheck.setAppCheckProviderFactory(AIsnsAppCheckProviderFactory())
        #endif
        FirebaseApp.configure()
        Database.database().isPersistenceEnabled = true
        _ = LocalNotificationManager.shared
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            MobileAds.shared.start()
        }
        return true
    }
}

private final class AIsnsAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        AppAttestProvider(app: app)
    }
}

@available(iOS 17.0, *)
@main
struct OshiSNSApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
//            BuzzingSNSView()
//            LonelyPostsView()
//            PromoDemoView()
            LaunchScreenView()
//            DemoPostReactionView()
//            FlamePostView()
//            SNSCommentDemoView()
//            SNSProfileView()
//            NegativeSNSView()
//            FlameWarView()
//            KiraKiraSNSView()
//            DemoTimelineView()
//            DemoProfileView()
//            DemoOshiListView()
//            DemoNotificationView()
        }
    }
}

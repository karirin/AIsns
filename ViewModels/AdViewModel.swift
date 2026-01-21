import Foundation
import GoogleMobileAds
import UIKit // UIApplication を使用するために必要

@MainActor
class AdViewModel: NSObject, ObservableObject {
    @Published var nativeAd: NativeAd? = nil
    private var adLoader: AdLoader?
    private let interstitialCountKey = "interstitial_create_count"
    // ✅ 追加: リワード広告を保持するプロパティ
    private var rewardedAd: RewardedAd?
    private var interstitialAd: InterstitialAd?
    
    func shouldShowInterstitialEvery3rd() -> Bool {
        let next = UserDefaults.standard.integer(forKey: interstitialCountKey) + 1
        UserDefaults.standard.set(next, forKey: interstitialCountKey)
        return next % 3 == 0
    }

    func loadInterstitialAd() async {
        do {
            // テスト用ID: ca-app-pub-3940256099942544/4411468910
            interstitialAd = try await InterstitialAd.load(with: "ca-app-pub-4898800212808837/3380377117", request: Request())
            print("✅ インタースティシャル広告のロード成功")
        } catch {
            print("❌ インタースティシャル広告のロード失敗: \(error.localizedDescription)")
        }
    }

    // ✅ インタースティシャル広告を表示
    func showInterstitialAd() {
        guard let interstitialAd = interstitialAd else {
            print("⚠️ インタースティシャル広告の準備ができていません（今からロードします）")
            Task { await loadInterstitialAd() }   // ✅ 追加
            return
        }

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.windows.first?.rootViewController {
            interstitialAd.present(from: root)

            self.interstitialAd = nil
            Task { await loadInterstitialAd() }
        }
    }

    // 広告をロードするメソッド
    func loadNativeAd() {
        let adUnitID = "ca-app-pub-4898800212808837/4913451643"
        adLoader = AdLoader(
            adUnitID: adUnitID,
            rootViewController: nil,
            adTypes: [.native],
            options: nil
        )
        adLoader?.delegate = self
        adLoader?.load(Request())
    }
    
    // リワード広告のロード
    func loadRewardedAd() async {
        do {
            // ここで宣言済みの rewardedAd に代入されます
            rewardedAd = try await RewardedAd.load(with: "ca-app-pub-4898800212808837/8635561465", request: Request())
            print("✅ リワード広告のロード成功")
        } catch {
            print("❌ リワード広告のロード失敗: \(error.localizedDescription)")
        }
    }

    // 広告を表示し、完了したらクロージャを実行
    func showRewardedAd(completion: @escaping () -> Void) {
        guard let rewardedAd = rewardedAd else {
            print("⚠️ 広告が準備できていません")
            return
        }

        // 最前面のViewControllerを取得して表示
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.windows.first?.rootViewController {
            rewardedAd.present(from: root) {
                print("💎 ユーザーが報酬を獲得しました")
                completion()
            }
        }
    }
}

// 広告読み込みの結果を受け取るデリゲート
extension AdViewModel: NativeAdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        self.nativeAd = nativeAd
    }
    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        print("❌ ネイティブ広告失敗: \(error.localizedDescription)")
    }
}

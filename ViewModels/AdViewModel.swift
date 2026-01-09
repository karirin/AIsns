import Foundation
import GoogleMobileAds
import UIKit // UIApplication を使用するために必要

@MainActor
class AdViewModel: NSObject, ObservableObject {
    @Published var nativeAd: NativeAd? = nil
    private var adLoader: AdLoader?
    
    // ✅ 追加: リワード広告を保持するプロパティ
    private var rewardedAd: RewardedAd?

    // 広告をロードするメソッド
    func loadNativeAd() {
        let adUnitID = "ca-app-pub-3940256099942544/3986624511"
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
            rewardedAd = try await RewardedAd.load(with: "ca-app-pub-3940256099942544/1712485313", request: Request())
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

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
    private var rewardedAdLoadTask: Task<Void, Never>?
    private var rewardedAdContinuation: CheckedContinuation<RewardedAdOutcome, Never>?
    private var didEarnReward = false
    private var interstitialAd: InterstitialAd?

    enum RewardedAdOutcome {
        /// 最後まで視聴して報酬を獲得した
        case rewarded
        /// 報酬獲得前に閉じた
        case dismissedEarly
        /// 在庫なし・通信エラーなどで広告を表示できなかった
        case unavailable
    }
    
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

        if let presenter = Self.topViewController() {
            interstitialAd.present(from: presenter)

            self.interstitialAd = nil
            Task { await loadInterstitialAd() }
        }
    }

    /// シートなどが表示中でも広告を出せるよう、最前面のViewControllerを返す。
    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? scenes.first?.windows.first
        var top = window?.rootViewController
        while let presented = top?.presentedViewController, !presented.isBeingDismissed {
            top = presented
        }
        return top
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
    
    // リワード広告のロード（読み込み済み・読み込み中なら重複して読み込まない）
    func loadRewardedAd() async {
        guard rewardedAd == nil else { return }
        if let rewardedAdLoadTask {
            await rewardedAdLoadTask.value
            return
        }

        let task = Task { [weak self] in
            do {
                let ad = try await RewardedAd.load(with: "ca-app-pub-4898800212808837/8635561465", request: Request())
                self?.rewardedAd = ad
                print("✅ リワード広告のロード成功")
            } catch {
                print("❌ リワード広告のロード失敗: \(error.localizedDescription)")
            }
        }
        rewardedAdLoadTask = task
        await task.value
        rewardedAdLoadTask = nil
    }

    /// リワード広告を表示し、結果を返す。未ロードなら最大 `loadTimeout` 秒だけ読み込みを待つ。
    func presentRewardedAd(loadTimeout: TimeInterval = 8) async -> RewardedAdOutcome {
        guard rewardedAdContinuation == nil else { return .unavailable }

        if rewardedAd == nil {
            Task { await loadRewardedAd() }
            let deadline = Date().addingTimeInterval(loadTimeout)
            while rewardedAd == nil, Date() < deadline {
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
        }

        guard let ad = rewardedAd, let presenter = Self.topViewController() else {
            print("⚠️ リワード広告を表示できません（未ロードまたは表示先なし）")
            return .unavailable
        }

        rewardedAd = nil // 1つの広告は1回しか表示できない
        didEarnReward = false
        ad.fullScreenContentDelegate = self

        let outcome = await withCheckedContinuation { continuation in
            rewardedAdContinuation = continuation
            ad.present(from: presenter) { [weak self] in
                print("💎 ユーザーが報酬を獲得しました")
                self?.didEarnReward = true
            }
        }

        Task { await loadRewardedAd() } // 次回分を先読み
        return outcome
    }

    private func finishRewardedAd(_ outcome: RewardedAdOutcome) {
        rewardedAdContinuation?.resume(returning: outcome)
        rewardedAdContinuation = nil
    }
}

// リワード広告の表示結果を受け取るデリゲート
extension AdViewModel: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        guard ad is RewardedAd else { return }
        finishRewardedAd(didEarnReward ? .rewarded : .dismissedEarly)
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        guard ad is RewardedAd else { return }
        print("❌ リワード広告の表示失敗: \(error.localizedDescription)")
        finishRewardedAd(didEarnReward ? .rewarded : .unavailable)
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

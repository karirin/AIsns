//
//  Untitled.swift
//  AIsns
//
//  Created by Apple on 2026/01/18.
//

import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner) // 標準バナーサイズ (320x50)
        // テスト用ユニットID（本番リリース時に自分のものに変更）
        banner.adUnitID = "ca-app-pub-4898800212808837/2513840399"
        
        // 最も近いViewControllerをルートとして設定
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            banner.rootViewController = rootVC
        }
        
        banner.load(Request())
        return banner
    }
    
    func updateUIView(_ uiView: BannerView, context: Context) {}
}

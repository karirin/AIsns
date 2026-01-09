//
//  NativeAdView.swift
//  AIsns
//

import SwiftUI
import GoogleMobileAds

// SwiftUI 側の名前を「AdNativeView」に変更して、衝突を避ける
struct NativeAdView: UIViewRepresentable {
    let nativeAd: NativeAd

    // SDK の型であることを明確に指定
    func makeUIView(context: Context) -> GoogleMobileAds.NativeAdView {
        let adView = GoogleMobileAds.NativeAdView()
        
        let mediaView = MediaView()
        adView.addSubview(mediaView)
        adView.mediaView = mediaView
        
        let headlineLabel = UILabel()
        headlineLabel.font = .systemFont(ofSize: 16, weight: .bold)
        headlineLabel.textColor = .label
        adView.addSubview(headlineLabel)
        adView.headlineView = headlineLabel
        
        let bodyLabel = UILabel()
        bodyLabel.font = .systemFont(ofSize: 14)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 2
        adView.addSubview(bodyLabel)
        adView.bodyView = bodyLabel
        
        let callToActionButton = UIButton()
        // AppColors.primary は DesignSystem.swift の定義を使用
        callToActionButton.backgroundColor = UIColor(AppColors.primary)
        callToActionButton.setTitleColor(.white, for: .normal)
        callToActionButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        callToActionButton.layer.cornerRadius = 8
        adView.addSubview(callToActionButton)
        adView.callToActionView = callToActionButton

        mediaView.translatesAutoresizingMaskIntoConstraints = false
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        callToActionButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mediaView.topAnchor.constraint(equalTo: adView.topAnchor),
            mediaView.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
            mediaView.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
            mediaView.heightAnchor.constraint(equalToConstant: 180),
            
            headlineLabel.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 12),
            headlineLabel.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),
            headlineLabel.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -12),
            
            bodyLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 4),
            bodyLabel.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),
            bodyLabel.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -12),
            
            callToActionButton.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 12),
            callToActionButton.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -12),
            callToActionButton.widthAnchor.constraint(equalToConstant: 100),
            callToActionButton.heightAnchor.constraint(equalToConstant: 36),
            callToActionButton.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -12)
        ])
        
        return adView
    }

    func updateUIView(_ uiView: GoogleMobileAds.NativeAdView, context: Context) {
        (uiView.headlineView as? UILabel)?.text = nativeAd.headline
        (uiView.bodyView as? UILabel)?.text = nativeAd.body
        (uiView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        uiView.mediaView?.mediaContent = nativeAd.mediaContent
        
        uiView.nativeAd = nativeAd
    }
}

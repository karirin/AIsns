//
//  SwipeBackGesture.swift
//  AIsns
//
//  Created: 2026/01/03 - Enable swipe back gesture with custom back button
//

import SwiftUI

// MARK: - Swipe Back Gesture Extension

extension View {
    /// カスタム戻るボタンを使用しながらスワイプバックジェスチャーを有効にする
    func enableSwipeBack() -> some View {
        self.background(SwipeBackGestureEnabler())
    }
}

// MARK: - Swipe Back Gesture Enabler

struct SwipeBackGestureEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        SwipeBackViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

class SwipeBackViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // NavigationControllerのinteractivePopGestureRecognizerを有効にする
        if let navigationController = self.navigationController {
            navigationController.interactivePopGestureRecognizer?.isEnabled = true
            navigationController.interactivePopGestureRecognizer?.delegate = nil
        }
    }
}

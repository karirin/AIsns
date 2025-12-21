//
//  imagePicker.swift
//  AIsns
//
//  Created by Apple on 2025/12/21.
//  Updated: ズームスライダー下部配置版
//

import SwiftUI
import PhotosUI

// MARK: - Main Image Picker Coordinator
struct ImagePickerWithCrop: View {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    @State private var pickedImage: UIImage?
    @State private var showCropper = false
    
    var body: some View {
        ZStack {
            if showCropper, let image = pickedImage {
                CircleCropView(
                    image: image,
                    onCrop: { croppedImage in
                        selectedImage = croppedImage
                        dismiss()
                    },
                    onCancel: {
                        dismiss()
                    }
                )
            } else {
                PhotoPickerView(selectedImage: $pickedImage)
                    .onChange(of: pickedImage) { newValue in
                        if newValue != nil {
                            showCropper = true
                        }
                    }
            }
        }
        .interactiveDismissDisabled(showCropper)
    }
}

// MARK: - Photo Picker View
struct PhotoPickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPickerView
        
        init(_ parent: PhotoPickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            if let provider = results.first?.itemProvider,
               provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    DispatchQueue.main.async {
                        if let uiImage = image as? UIImage {
                            self.parent.selectedImage = uiImage
                        }
                    }
                }
            } else {
                parent.dismiss()
            }
        }
    }
}

// MARK: - Circle Crop View
struct CircleCropView: View {
    let image: UIImage
    let onCrop: (UIImage) -> Void
    let onCancel: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero
    
    private let cropDiameter: CGFloat = 300
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                // メインコンテンツ
                GeometryReader { geometry in
                    ZStack {
                        // 画像レイヤー
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(scale)
                            .offset(offset)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .gesture(dragGesture)
                            .gesture(magnifyGesture)
                        
                        // オーバーレイ（暗い部分）
                        OverlayMask(diameter: cropDiameter)
                            .allowsHitTesting(false)
                        
                        // クロップ枠
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 2)
                            .frame(width: cropDiameter, height: cropDiameter)
                            .allowsHitTesting(false)
                    }
                }
                
                // ズームスライダー（画面下部）
                VStack {
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Image(systemName: "minus.magnifyingglass")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                        
                        Slider(value: $scale, in: 1...4)
                            .tint(.white)
                        
                        Image(systemName: "plus.magnifyingglass")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 50)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        onCancel()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("写真を編集")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        performCrop()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.9), for: .navigationBar)
        }
    }
    
    // MARK: - Gestures
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }
    
    private var magnifyGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value
                scale = min(max(scale * delta, 1), 4)
            }
            .onEnded { _ in
                lastScale = 1.0
            }
    }
    
    // MARK: - Crop Logic
    
    private func performCrop() {
        let imageSize = image.size
        let viewSize = UIScreen.main.bounds.size
        
        // 画像のスケール計算
        let widthRatio = viewSize.width / imageSize.width
        let heightRatio = viewSize.height / imageSize.height
        let imageScale = min(widthRatio, heightRatio)
        
        // 実際の画像上でのクロップサイズ
        let cropSizeInImage = cropDiameter / (imageScale * scale)
        
        // 実際の画像上でのオフセット計算
        let centerX = (imageSize.width - cropSizeInImage) / 2
        let centerY = (imageSize.height - cropSizeInImage) / 2
        
        let offsetXInImage = -offset.width / (imageScale * scale)
        let offsetYInImage = -offset.height / (imageScale * scale)
        
        let cropX = centerX + offsetXInImage
        let cropY = centerY + offsetYInImage
        
        let cropRect = CGRect(
            x: max(0, min(cropX, imageSize.width - cropSizeInImage)),
            y: max(0, min(cropY, imageSize.height - cropSizeInImage)),
            width: min(cropSizeInImage, imageSize.width),
            height: min(cropSizeInImage, imageSize.height)
        )
        
        // クロップ実行
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            onCrop(image)
            return
        }
        
        // 円形にマスク
        let croppedImage = UIImage(cgImage: cgImage)
        let circularImage = cropToCircle(croppedImage)
        
        onCrop(circularImage)
    }
    
    private func cropToCircle(_ image: UIImage) -> UIImage {
        let size = CGSize(width: cropDiameter, height: cropDiameter)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        let rect = CGRect(origin: .zero, size: size)
        UIBezierPath(ovalIn: rect).addClip()
        image.draw(in: rect)
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
}

// MARK: - Overlay Mask
struct OverlayMask: View {
    let diameter: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .fill(Color.black.opacity(0.6))
                
                Circle()
                    .frame(width: diameter, height: diameter)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
        }
    }
}

// MARK: - Preview
#Preview {
    CircleCropView(
        image: UIImage(systemName: "photo.fill")!,
        onCrop: { _ in },
        onCancel: {}
    )
}

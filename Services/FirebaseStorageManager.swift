//
//  FirebaseStorageManager.swift
//  AIsns
//
//  画像アップロード・ダウンロード機能
//

import Foundation
import UIKit
import FirebaseStorage

class FirebaseStorageManager {
    static let shared = FirebaseStorageManager()
    
    private let storage = Storage.storage()
    private init() {}
    
    // MARK: - 推しアバター画像
    
    /// 推しのアバター画像をアップロード
    func uploadOshiAvatar(_ image: UIImage, oshiId: UUID) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw StorageError.imageConversionFailed
        }
        
        let fileName = "\(oshiId.uuidString).jpg"
        let storageRef = storage.reference().child("oshi_avatars/\(fileName)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    // MARK: - ✅ 投稿画像
    
    /// 投稿画像をアップロード
    func uploadPostImage(_ image: UIImage, postId: UUID, index: Int) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw StorageError.imageConversionFailed
        }
        
        let fileName = "\(postId.uuidString)_\(index).jpg"
        let storageRef = storage.reference().child("post_images/\(fileName)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    // MARK: - 画像ダウンロード
    
    /// URLから画像をダウンロード
    func downloadImage(from urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw StorageError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let image = UIImage(data: data) else {
            throw StorageError.imageConversionFailed
        }
        
        return image
    }
    
    // MARK: - 画像削除
    
    /// 推しアバター画像を削除
    func deleteOshiAvatar(oshiId: UUID) async throws {
        let fileName = "\(oshiId.uuidString).jpg"
        let storageRef = storage.reference().child("oshi_avatars/\(fileName)")
        try await storageRef.delete()
    }
    
    /// 投稿画像を削除
    func deletePostImages(postId: UUID, imageCount: Int) async throws {
        for index in 0..<imageCount {
            let fileName = "\(postId.uuidString)_\(index).jpg"
            let storageRef = storage.reference().child("post_images/\(fileName)")
            try? await storageRef.delete() // エラーがあっても続行
        }
    }
}

// MARK: - エラー定義

enum StorageError: LocalizedError {
    case imageConversionFailed
    case invalidURL
    case uploadFailed
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "画像の変換に失敗しました"
        case .invalidURL:
            return "無効なURLです"
        case .uploadFailed:
            return "アップロードに失敗しました"
        case .downloadFailed:
            return "ダウンロードに失敗しました"
        }
    }
}

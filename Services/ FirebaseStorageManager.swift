//
//   FirebaseStorageManager.swift
//  AIsns
//
//  Created by Apple on 2025/12/21.
//

import Foundation
import FirebaseStorage
import UIKit

class FirebaseStorageManager {
    static let shared = FirebaseStorageManager()
    
    private let storage: Storage
    private let userId: String
    
    private init() {
        self.storage = Storage.storage()
        self.userId = FirebaseConfig.shared.userId
    }
    
    // MARK: - Avatar Image Upload
    
    /// 推しのアバター画像をアップロード
    func uploadOshiAvatar(_ image: UIImage, oshiId: UUID) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw StorageError.invalidImage
        }
        
        let path = "users/\(userId)/avatars/\(oshiId.uuidString).jpg"
        let storageRef = storage.reference().child(path)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    /// 推しのアバター画像を削除
    func deleteOshiAvatar(oshiId: UUID) async throws {
        let path = "users/\(userId)/avatars/\(oshiId.uuidString).jpg"
        let storageRef = storage.reference().child(path)
        
        try await storageRef.delete()
    }
    
    /// URLから画像をダウンロード
    func downloadImage(from urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw StorageError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let image = UIImage(data: data) else {
            throw StorageError.invalidImage
        }
        
        return image
    }
    
    // MARK: - Post Image Upload (将来の拡張用)
    
    /// 投稿画像をアップロード
    func uploadPostImage(_ image: UIImage, postId: UUID) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw StorageError.invalidImage
        }
        
        let path = "users/\(userId)/posts/\(postId.uuidString).jpg"
        let storageRef = storage.reference().child(path)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    /// 投稿画像を削除
    func deletePostImage(postId: UUID) async throws {
        let path = "users/\(userId)/posts/\(postId.uuidString).jpg"
        let storageRef = storage.reference().child(path)
        
        try await storageRef.delete()
    }
}

// MARK: - Error

enum StorageError: LocalizedError {
    case invalidImage
    case invalidURL
    case uploadFailed
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "画像が無効です"
        case .invalidURL:
            return "URLが無効です"
        case .uploadFailed:
            return "アップロードに失敗しました"
        case .downloadFailed:
            return "ダウンロードに失敗しました"
        }
    }
}

import Foundation
import FirebaseCore
import FirebaseDatabase

class FirebaseConfig {
    static let shared = FirebaseConfig()
    
    private init() {}
    
    func configure() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
    
    var databaseRef: DatabaseReference {
        return Database.database().reference()
    }
    
    // ユーザーID取得（簡易版 - 実際は認証システムと連携）
    var userId: String {
        if let savedId = UserDefaults.standard.string(forKey: "userId") {
            return savedId
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: "userId")
        return newId
    }
}

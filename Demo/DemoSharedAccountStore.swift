//
//  DemoSharedAccountStore.swift
//  AIsns
//
//  Created by Apple on 2026/02/08.
//

import SwiftUI

// ============================================================
// MARK: - Shared Account Store (共有アカウントストア)
// ============================================================

class DemoSharedAccountStore: ObservableObject {
    static let shared = DemoSharedAccountStore()
    
    @Published var accounts: [DemoAccount] = []
    
    private let accountsKey = "demo_shared_accounts_v1"
    // 旧データとの互換性のため
    private let legacyTimelineKey = "demo_accounts_v2"
    private let legacyReactionKey = "demo_pr_followers_v1"
    
    init() {
        loadAccounts()
    }
    
    func addAccount(name: String, avatarImageBase64: String?) -> DemoAccount {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseHandle = trimmed
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "　", with: "")
        let handle = baseHandle.isEmpty ? "user_\(UUID().uuidString.prefix(6))" : "\(baseHandle)"

        let newAccount = DemoAccount(
            id: "acc_\(UUID().uuidString.prefix(8))",
            name: trimmed.isEmpty ? "新規アカウント" : trimmed,
            handle: handle,
            avatarEmoji: "🙂",
            avatarColorHex: "#6C5CE7",
            avatarImageBase64: avatarImageBase64,
            isHidden: false
        )

        accounts.append(newAccount)
        save() // もし既に永続化してるならそれを呼ぶ（無ければ accounts の保存処理に合わせて）
        return newAccount
    }
    
    // MARK: - Load (既存データをマージ)
    
    func loadAccounts() {
        var loadedAccounts: [DemoAccount] = []
        
        // 新しい共有キーから読み込み
        if let data = UserDefaults.standard.data(forKey: accountsKey),
           let decoded = try? JSONDecoder().decode([DemoAccount].self, from: data) {
            loadedAccounts = decoded
        }
        
        // 既存のタイムラインデータをマージ
        if let data = UserDefaults.standard.data(forKey: legacyTimelineKey),
           let decoded = try? JSONDecoder().decode([DemoAccount].self, from: data) {
            for account in decoded {
                if !loadedAccounts.contains(where: { $0.id == account.id }) {
                    loadedAccounts.append(account)
                }
            }
        }
        
        // 既存のリアクションデモのフォロワーデータをマージ
        if let data = UserDefaults.standard.data(forKey: legacyReactionKey),
           let decoded = try? JSONDecoder().decode([DemoAccount].self, from: data) {
            for account in decoded {
                if !loadedAccounts.contains(where: { $0.id == account.id }) {
                    loadedAccounts.append(account)
                }
            }
        }
        
        // データが何もなければサンプルデータ
        if loadedAccounts.isEmpty {
            loadedAccounts = DemoAccount.samples
        }
        
        accounts = loadedAccounts
        save()
    }
    
    // MARK: - Save
    
    func save() {
        if let data = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(data, forKey: accountsKey)
        }
    }
    
    // MARK: - CRUD
    
    func addAccount(_ account: DemoAccount) {
        accounts.append(account)
        save()
    }
    
    func removeAccount(at offsets: IndexSet) {
        accounts.remove(atOffsets: offsets)
        save()
    }
    
    func removeAccount(id: String) {
        accounts.removeAll { $0.id == id }
        save()
    }
    
    func toggleAccountVisibility(id: String) {
        if let index = accounts.firstIndex(where: { $0.id == id }) {
            accounts[index].isHidden.toggle()
            save()
        }
    }
    
    func account(for id: String) -> DemoAccount? {
        accounts.first { $0.id == id }
    }
}

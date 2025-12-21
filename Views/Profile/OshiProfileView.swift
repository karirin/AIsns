//
//  OshiProfileView.swift
//  AIsns
//
//  Updated: 2025/12/20
//

import SwiftUI

struct OshiProfileView: View {
    let oshi: OshiCharacter
    @ObservedObject var viewModel: OshiViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteAlert = false
    @State private var showingEditView = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // プロフィール画像エリア
                VStack(spacing: 12) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: oshi.avatarColor),
                                    Color(hex: oshi.avatarColor).opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(String(oshi.name.prefix(1)))
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        )
                    
                    Text("写真を変更")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                .padding(.top, 24)
                .padding(.bottom, 32)
                
                // ユーザー情報セクション
                VStack(spacing: 0) {
                    Text("ユーザー情報")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    
                    VStack(spacing: 0) {
                        // 名前
                        ProfileRowButton(
                            label: "名前",
                            value: oshi.name,
                            showChevron: true
                        ) {
                            showingEditView = true
                        }
                        
                        Divider()
                            .padding(.leading, 16)
                        
                        // 性別
                        ProfileRowButton(
                            label: "性別",
                            value: oshi.gender?.rawValue ?? "未設定",
                            showChevron: true
                        ) {
                            showingEditView = true
                        }
                        
                        Divider()
                            .padding(.leading, 16)
                        
                        // ユーザー名
                        ProfileRowButton(
                            label: "ユーザー名",
                            value: "up\(String(format: "%05d", abs(oshi.id.hashValue % 100000)))",
                            showChevron: true
                        ) {
                            showingEditView = true
                        }
                        
                        Divider()
                            .padding(.leading, 16)
                        
                        // SNSリンク
                        HStack {
                            Spacer()
                            HStack(spacing: 4) {
                                Text("tiktok.com/@up\(String(format: "%05d", abs(oshi.id.hashValue % 100000)))")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Image(systemName: "doc.on.doc")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 14)
                        .background(Color(.systemBackground))
                        .contentShape(Rectangle())
                    }
                    .background(Color(.systemBackground))
                }
                
                // 自己紹介
                VStack(spacing: 0) {
                    Divider()
                        .padding(.leading, 16)
                    
                    ProfileRowButton(
                        label: "自己紹介",
                        value: oshi.speechCharacteristics.isEmpty ? "自己紹介を追加" : oshi.speechCharacteristics,
                        valueColor: oshi.speechCharacteristics.isEmpty ? .secondary : .primary,
                        showChevron: true
                    ) {
                        showingEditView = true
                    }
                }
                .background(Color(.systemBackground))
                .padding(.top, 20)
                
                // リンク
                VStack(spacing: 0) {
                    Divider()
                        .padding(.leading, 16)
                    
                    ProfileRowButton(
                        label: "リンク",
                        value: "追加",
                        valueColor: .secondary,
                        showChevron: true
                    ) {
                        // リンク追加処理
                    }
                }
                .background(Color(.systemBackground))
                
                // キャラクター設定セクション
                VStack(spacing: 0) {
                    Text("キャラクター設定")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 32)
                        .padding(.bottom, 8)
                    
                    VStack(spacing: 0) {
                        // 性格
                        ProfileRowButton(
                            label: "性格",
                            value: "\(oshi.personality.emoji) \(oshi.personality.rawValue)",
                            showChevron: true
                        ) {
                            showingEditView = true
                        }
                        
                        Divider()
                            .padding(.leading, 16)
                        
                        // 話し方の特徴
                        ProfileRowButton(
                            label: "話し方の特徴",
                            value: oshi.speechCharacteristics.isEmpty ? "追加" : oshi.speechCharacteristics,
                            valueColor: oshi.speechCharacteristics.isEmpty ? .secondary : .primary,
                            showChevron: true
                        ) {
                            showingEditView = true
                        }
                        
                        Divider()
                            .padding(.leading, 16)
                        
                        // ユーザーへの呼び方
                        ProfileRowButton(
                            label: "ユーザーへの呼び方",
                            value: oshi.userCallingName.isEmpty ? "追加" : oshi.userCallingName,
                            valueColor: oshi.userCallingName.isEmpty ? .secondary : .primary,
                            showChevron: true
                        ) {
                            showingEditView = true
                        }
                        
                        Divider()
                            .padding(.leading, 16)
                        
                        // 口調
                        ProfileRowButton(
                            label: "口調",
                            value: oshi.speechStyle.rawValue,
                            showChevron: true
                        ) {
                            showingEditView = true
                        }
                        
                        Divider()
                            .padding(.leading, 16)
                        
                        // 距離感
                        ProfileRowButton(
                            label: "距離感",
                            value: "\(oshi.relationshipDistance.icon) \(oshi.relationshipDistance.rawValue)",
                            showChevron: true
                        ) {
                            showingEditView = true
                        }
                        
                        Divider()
                            .padding(.leading, 16)
                        
                        // 世界観
                        ProfileRowButton(
                            label: "世界観",
                            value: "\(oshi.worldSetting.icon) \(oshi.worldSetting.rawValue)",
                            showChevron: true
                        ) {
                            showingEditView = true
                        }
                    }
                    .background(Color(.systemBackground))
                }
                
                // AI Self
                VStack(spacing: 0) {
                    Divider()
                        .padding(.leading, 16)
                    
                    ProfileRowButton(
                        label: "AI Self",
                        value: "私のAI Self",
                        valueColor: .secondary,
                        showChevron: true
                    ) {
                        // AI Self処理
                    }
                }
                .background(Color(.systemBackground))
                .padding(.top, 20)
                
                // 統計情報
                VStack(spacing: 0) {
                    Text("統計")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 32)
                        .padding(.bottom, 8)
                    
                    VStack(spacing: 0) {
                        ProfileRowButton(
                            label: "親密度レベル",
                            value: "Lv.\(oshi.intimacyLevel)",
                            showChevron: false
                        ) { }
                        
                        Divider()
                            .padding(.leading, 16)
                        
                        ProfileRowButton(
                            label: "やりとり",
                            value: "\(oshi.totalInteractions)回",
                            showChevron: false
                        ) { }
                        
                        Divider()
                            .padding(.leading, 16)
                        
                        ProfileRowButton(
                            label: "最後のやりとり",
                            value: formatDateShort(oshi.lastInteractionDate),
                            showChevron: false
                        ) { }
                    }
                    .background(Color(.systemBackground))
                }
                
                // 削除ボタン
                Button(action: { showingDeleteAlert = true }) {
                    Text("推しを削除")
                        .font(.body)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .background(Color(.systemBackground))
                .padding(.top, 32)
                .padding(.bottom, 32)
            }
        }
        .background(Color(.systemGray6))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingEditView = true
                } label: {
                    Text("編集")
                        .foregroundColor(.primary)
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            NavigationStack {
                OshiProfileEditView(oshi: oshi, viewModel: viewModel)
            }
        }
        .alert("推しを削除しますか?", isPresented: $showingDeleteAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("削除", role: .destructive) {
                viewModel.deleteOshi(oshi)
                dismiss()
            }
        } message: {
            Text("この操作は取り消せません。チャット履歴も削除されます。")
        }
    }
    
    private func formatDateShort(_ date: Date?) -> String {
        guard let date = date else { return "なし" }
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "今日"
        } else if calendar.isDateInYesterday(date) {
            return "昨日"
        } else {
            let components = calendar.dateComponents([.day], from: date, to: now)
            if let days = components.day, days < 7 {
                return "\(days)日前"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "M/d"
                return formatter.string(from: date)
            }
        }
    }
}

// プロフィール行ボタン
struct ProfileRowButton: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    var showChevron: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(valueColor)
                    .lineLimit(1)
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 14)
            .background(Color(.systemBackground))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationStack {
        OshiProfileView(
            oshi: OshiCharacter(
                name: "UI Pocket",
                gender: .female,
                personality: .cool,
                speechCharacteristics: "柔らかくて優しい口調",
                userCallingName: "あなた",
                speechStyle: .casual,
                relationshipDistance: .bestFriend,
                worldSetting: .student,
                avatarColor: "#FF69B4"
            ),
            viewModel: OshiViewModel()
        )
    }
}

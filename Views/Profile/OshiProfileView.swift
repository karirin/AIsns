//
//  OshiProfileView 2.swift
//  AIsns
//
//  Created by Apple on 2025/12/20.
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
                // ヘッダー背景グラデーション
                ZStack(alignment: .bottom) {
                    LinearGradient(
                        colors: [
                            Color(hex: oshi.avatarColor).opacity(0.3),
                            Color(hex: oshi.avatarColor).opacity(0.1),
                            Color(.systemBackground)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 280)
                    .ignoresSafeArea(edges: .top)
                    
                    VStack(spacing: 16) {
                        // アバター
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
                                    .font(.system(size: 44, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                            )
                            .shadow(color: Color(hex: oshi.avatarColor).opacity(0.4), radius: 20, y: 10)
                        
                        Text(oshi.name)
                            .font(.system(size: 28, weight: .bold))
                        
                        // 親密度バッジ
                        HStack(spacing: 6) {
                            Image(systemName: "heart.fill")
                                .font(.caption)
                                .foregroundColor(.pink)
                            Text("Lv.\(oshi.intimacyLevel)")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
                        )
                    }
                    .padding(.bottom, 20)
                }
                
                // 親密度プログレスバー
                VStack(spacing: 12) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemGray5))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            .pink,
                                            .purple,
                                            Color(hex: oshi.avatarColor)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: geometry.size.width * CGFloat(oshi.intimacyLevel) / 100,
                                    height: 8
                                )
                                .shadow(color: .pink.opacity(0.5), radius: 4, y: 2)
                        }
                    }
                    .frame(height: 8)
                    
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.caption2)
                                .foregroundColor(.pink)
                            Text("親密度")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(oshi.intimacyLevel) / 100")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // 統計カード
                HStack(spacing: 12) {
                    ModernStatCard(
                        icon: "message.fill",
                        iconColor: .blue,
                        title: "やりとり",
                        value: "\(oshi.totalInteractions)",
                        unit: "回"
                    )
                    
                    ModernStatCard(
                        icon: "clock.fill",
                        iconColor: .orange,
                        title: "最後",
                        value: formatDateShort(oshi.lastInteractionDate),
                        unit: ""
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // プロフィールセクション
                VStack(spacing: 16) {
                    HStack {
                        Text("プロフィール")
                            .font(.system(size: 20, weight: .bold))
                        Spacer()
                        Button {
                            showingEditView = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("編集")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    
                    VStack(spacing: 12) {
                        // 性別
//                        if let gender = oshi.gender {
//                            ModernProfileRow(
//                                icon: "person.fill",
//                                iconColor: .purple,
//                                title: "性別",
//                                value: gender.rawValue
//                            )
//                            
//                            Divider()
//                                .padding(.leading, 40)
//                        }
                        
                        // 性格
                        ModernProfileRow(
                            icon: "face.smiling",
                            iconColor: .orange,
                            title: "性格",
                            value: "\(oshi.personality.emoji) \(oshi.personality.rawValue)"
                        )
                        
                        Divider()
                            .padding(.leading, 40)
                        
                        // 話し方の特徴

                        
                        // 口調
                        ModernProfileRow(
                            icon: "message",
                            iconColor: .blue,
                            title: "口調",
                            value: oshi.speechStyle.rawValue
                        )
                        
                        Divider()
                            .padding(.leading, 40)
                        
          
                        
                        // 距離感
                        ModernProfileRow(
                            icon: "person.2",
                            iconColor: .purple,
                            title: "距離感",
                            value: "\(oshi.relationshipDistance.icon) \(oshi.relationshipDistance.rawValue)"
                        )
                        
                        Divider()
                            .padding(.leading, 40)
                        
                        // 世界観
                        ModernProfileRow(
                            icon: "globe",
                            iconColor: .blue,
                            title: "世界観",
                            value: "\(oshi.worldSetting.icon) \(oshi.worldSetting.rawValue)"
                        )
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6).opacity(0.5))
                    )
                    
                    // NG項目
                    if !oshi.ngTopics.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("NG項目")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(oshi.ngTopics, id: \.self) { topic in
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(Color.orange.opacity(0.3))
                                            .frame(width: 6, height: 6)
                                        Text(topic)
                                            .font(.subheadline)
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.orange.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                
                // 削除ボタン
                Button(action: { showingDeleteAlert = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                        Text("推しを削除")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditView) {
            NavigationStack {
//                OshiProfileEditView(oshi: oshi, viewModel: viewModel)
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

struct ModernStatCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(iconColor.opacity(0.15))
                )
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        )
    }
}

struct ModernProfileRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(iconColor)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(iconColor.opacity(0.15))
                )
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        OshiProfileView(
            oshi: OshiCharacter(
                name: "さくら",
                personality: .cool,
                speechStyle: .casual,
                relationshipDistance: .bestFriend,
                worldSetting: .student,
                avatarColor: "FF69B4"
            ),
            viewModel: OshiViewModel()
        )
    }
}

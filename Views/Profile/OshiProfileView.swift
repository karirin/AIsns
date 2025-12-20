import SwiftUI

struct OshiProfileView: View {
    let oshi: OshiCharacter
    @ObservedObject var viewModel: OshiViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // ヘッダー
                VStack(spacing: 16) {
                    // アバター
                    Circle()
                        .fill(Color(hex: oshi.avatarColor).gradient)
                        .frame(width: 120, height: 120)
                        .overlay(
                            Text(String(oshi.name.prefix(1)))
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .shadow(color: Color(hex: oshi.avatarColor).opacity(0.3), radius: 15, y: 8)
                    
                    Text(oshi.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // 親密度
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.pink)
                            Text("親密度")
                                .font(.headline)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                                    .frame(height: 12)
                                
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [.pink, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * CGFloat(oshi.intimacyLevel) / 100, 
                                          height: 12)
                            }
                        }
                        .frame(height: 12)
                        
                        Text("Lv.\(oshi.intimacyLevel) / 100")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 20)
                
                // 統計情報
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatCard(
                        icon: "message.fill",
                        title: "総やりとり",
                        value: "\(oshi.totalInteractions)回"
                    )
                    
                    StatCard(
                        icon: "calendar",
                        title: "最後のやりとり",
                        value: formatDate(oshi.lastInteractionDate)
                    )
                }
                .padding(.horizontal)
                
                // プロフィール情報
                VStack(alignment: .leading, spacing: 16) {
                    Text("プロフィール")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    ProfileRow(icon: "face.smiling", title: "性格", value: "\(oshi.personality.emoji) \(oshi.personality.rawValue)")
                    ProfileRow(icon: "text.bubble", title: "口調", value: oshi.speechStyle.rawValue)
                    ProfileRow(icon: "person.2", title: "距離感", value: "\(oshi.relationshipDistance.icon) \(oshi.relationshipDistance.rawValue)")
                    ProfileRow(icon: "globe", title: "世界観", value: "\(oshi.worldSetting.icon) \(oshi.worldSetting.rawValue)")
                    
                    if !oshi.ngTopics.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                Text("NG項目")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            
                            ForEach(oshi.ngTopics, id: \.self) { topic in
                                Text("• \(topic)")
                                    .font(.subheadline)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                .padding(.horizontal)
                
                // 削除ボタン
                Button(action: { showingDeleteAlert = true }) {
                    Text("推しを削除")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .alert("推しを削除しますか？", isPresented: $showingDeleteAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("削除", role: .destructive) {
                viewModel.deleteOshi(oshi)
                dismiss()
            }
        } message: {
            Text("この操作は取り消せません。チャット履歴も削除されます。")
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "なし" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ProfileRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }
}

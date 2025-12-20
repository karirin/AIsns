import SwiftUI

struct OshiListView: View {
    @ObservedObject var viewModel: OshiViewModel
    @State private var showingCreationSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.oshiList.isEmpty {
                    // 空の状態
                    VStack(spacing: 20) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.gray)
                        
                        Text("推しを作成しよう")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("あなた専用のAI推しを作成して\n自分だけのSNSを楽しもう")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Button(action: { showingCreationSheet = true }) {
                            Text("推しを作成")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(25)
                        }
                        .padding(.top)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.oshiList) { oshi in
                                NavigationLink(destination: OshiProfileView(oshi: oshi, viewModel: viewModel)) {
                                    OshiCard(oshi: oshi)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("推し一覧")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreationSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreationSheet) {
                OshiCreationView(viewModel: viewModel)
            }
        }
    }
}

struct OshiCard: View {
    let oshi: OshiCharacter
    
    var body: some View {
        HStack(spacing: 16) {
            // アバター
            Circle()
                .fill(Color(hex: oshi.avatarColor).gradient)
                .frame(width: 70, height: 70)
                .overlay(
                    Text(String(oshi.name.prefix(1)))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
                .shadow(color: Color(hex: oshi.avatarColor).opacity(0.3), radius: 8, y: 4)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(oshi.name)
                    .font(.title3)
                    .fontWeight(.bold)
                
                HStack(spacing: 4) {
                    Text(oshi.personality.emoji)
                    Text(oshi.personality.rawValue)
                    Text("•")
                    Text(oshi.worldSetting.icon)
                    Text(oshi.worldSetting.rawValue)
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                // 親密度バー
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.pink)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray6))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [.pink, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * CGFloat(oshi.intimacyLevel) / 100, 
                                      height: 6)
                        }
                    }
                    .frame(height: 6)
                    
                    Text("Lv.\(oshi.intimacyLevel)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .trailing)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

#Preview {
    OshiListView(viewModel: OshiViewModel())
}

//
//  OshiListView.swift
//  AIsns
//
//  Updated: Removed Mutual Tab & Changed Mutual Icon
//

import SwiftUI

struct OshiListView: View {
    @ObservedObject var viewModel: OshiViewModel
    
    // 0: フォロワー, 1: フォロー中
    @State private var selectedTab: Int = 0
    @Namespace private var animation
    @Binding var isPresented: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        // ✅ NavigationStack の代わりに NavigationView を使用
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    // カスタムタブバー
                    HStack(spacing: 0) {
                        TabButton(title: "フォロワー", tag: 0, selectedTab: $selectedTab, namespace: animation)
                        TabButton(title: "フォロー中", tag: 1, selectedTab: $selectedTab, namespace: animation)
                    }
                    .padding(.top, 8)
                    .background(Color(.systemBackground))
                    .zIndex(1)
                    
                    // スワイプ可能なコンテンツエリア
                    TabView(selection: $selectedTab) {
                        OshiListPage(
                            oshis: viewModel.oshiList.filter { $0.isFollowingUser },
                            emptyTitle: "フォロワーはいません",
                            emptySubtitle: "投稿してフォローしてもらいましょう",
                            iconName: "person.2.slash",
                            viewModel: viewModel
                        )
                        .tag(0)
                        
                        OshiListPage(
                            oshis: viewModel.oshiList.filter { $0.isFollowedByUser },
                            emptyTitle: "フォロー中のアカウントはいません",
                            emptySubtitle: "気になるアカウントを見つけてフォローしましょう",
                            iconName: "person.slash",
                            viewModel: viewModel
                        )
                        .tag(1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: selectedTab)
                }
                
                // アカウント追加ボタン (NavigationLink)
                // NavigationViewの中なので正常に画面遷移します
                NavigationLink(destination: OshiCreationView(viewModel: viewModel)) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            // ✅ ナビゲーションバーの設定は NavigationView の「中身」に対して行う
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isPresented {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
        // ✅ これを指定することで、iPad等でも強制的に全画面表示（スタック形式）になります
        .navigationViewStyle(.stack)
        .navigationBarBackButtonHidden(true)
    }
}

// リスト表示部分
struct OshiListPage: View {
    let oshis: [OshiCharacter]
    let emptyTitle: String
    let emptySubtitle: String
    let iconName: String
    @ObservedObject var viewModel: OshiViewModel
    
    var body: some View {
        if oshis.isEmpty {
            emptyStateView
        } else {
            List {
                ForEach(oshis) { oshi in
                    ZStack {
                        // 詳細画面へ遷移
                        NavigationLink(destination: OshiProfileDetailView(oshi: oshi, viewModel: viewModel, isPreset: false)) {
                            EmptyView()
                        }
                        .opacity(0)
                        
                        // 行デザイン
                        OshiListRowWithButton(oshi: oshi, viewModel: viewModel)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 80, height: 80)
                
                Image(systemName: iconName)
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                Text(emptyTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(emptySubtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 100)
    }
}

// フォローボタン付きの行コンポーネント
struct OshiListRowWithButton: View {
    let oshi: OshiCharacter
    @ObservedObject var viewModel: OshiViewModel
    @State private var showingUnfollowAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            // アイコン
            if let url = oshi.avatarImageURL, let imageURL = URL(string: url) {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color(.systemGray5)
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color(.systemGray6), lineWidth: 1))
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(oshi.name.prefix(1))
                            .font(.headline)
                            .foregroundColor(.blue)
                    )
            }
            
            // 名前と自己紹介
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(oshi.name)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    // ✅ 変更: 相互フォローの場合はバッジを表示
                    if oshi.isMutualFollow {
                        Text("相互")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.8))
                            .cornerRadius(4)
                    }
                }
                
                Text(oshi.personalityText.isEmpty ? "自己紹介文なし" : oshi.personalityText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // フォローボタン
            Button {
                if oshi.isFollowedByUser {
                    showingUnfollowAlert = true
                } else {
                    Task {
                        await viewModel.followOshi(oshi)
                    }
                }
            } label: {
                Text(oshi.isFollowedByUser ? "フォロー中" : "フォロー")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(oshi.isFollowedByUser ? .primary : .white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Group {
                            if oshi.isFollowedByUser {
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            } else {
                                Capsule()
                                    .fill(Color.blue)
                            }
                        }
                    )
            }
            .buttonStyle(PlainButtonStyle()) // リストタップと干渉しないように
            .alert("フォロー解除", isPresented: $showingUnfollowAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("解除", role: .destructive) {
                    Task {
                        await viewModel.unfollowOshi(oshi)
                    }
                }
            } message: {
                Text("\(oshi.name)のフォローを解除しますか?")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
}

// カスタムタブボタン
struct TabButton: View {
    let title: String
    let tag: Int
    @Binding var selectedTab: Int
    var namespace: Namespace.ID
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tag
            }
        } label: {
            VStack(spacing: 12) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(selectedTab == tag ? .bold : .medium)
                    .foregroundColor(selectedTab == tag ? .primary : .secondary)
                
                ZStack {
                    Capsule()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 2)
                    
                    if selectedTab == tag {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 3)
                            .matchedGeometryEffect(id: "TabIndicator", in: namespace)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    OshiListView(viewModel: OshiViewModel(mock: true), isPresented: .constant(false))
}

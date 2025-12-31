//
//  OshiProfileDetailView.swift
//  AIsns
//
//  Updated: 2025/12/29 - プリセット判定機能追加
//

import SwiftUI

struct OshiProfileDetailView: View {
    let oshi: OshiCharacter
    @ObservedObject var viewModel: OshiViewModel
    @Environment(\.dismiss) var dismiss
    
    // ✅ プリセットかどうかを判定するフラグ
    let isPreset: Bool
    
    @State private var avatarImage: UIImage?
    @State private var isLoadingImage = false
    @State private var selectedTab: ProfileTab = .posts
    @State private var showingEditSheet = false
    @State private var showingUnfollowAlert = false
    
    private let avatarSize: CGFloat = 100
    
    enum ProfileTab: String, CaseIterable {
        case posts = "ポスト"
    }
    
    // ✅ この推しの投稿をフィルタリング
    var oshiPosts: [Post] {
        viewModel.posts.filter { $0.authorId == oshi.id }
    }
    
    // ✅ イニシャライザにisPresetを追加(デフォルトはfalse)
    init(oshi: OshiCharacter, viewModel: OshiViewModel, isPreset: Bool = false) {
        self.oshi = oshi
        self.viewModel = viewModel
        self.isPreset = isPreset
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // アバターセクション
                avatarSection
                
                // プロフィール情報
                profileInfoSection
                
                Divider()
                    .padding(.horizontal, 24)
                
                // コンテンツエリア
                contentSection
            }
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("プロフィールを編集", systemImage: "pencil")
                    }
                    
                    // ✅ プリセットの場合はフォロー解除を表示しない
                    if !isPreset {
                        Button(role: .destructive) {
                            showingUnfollowAlert = true
                        } label: {
                            Label("フォロー解除", systemImage: "person.badge.minus")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                // ✅ isPresetフラグを渡す
                OshiProfileEditView(
                    oshi: oshi,
                    viewModel: viewModel,
                    isPreset: isPreset
                )
            }
        }
        .alert("フォロー解除", isPresented: $showingUnfollowAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("解除", role: .destructive) {
                viewModel.deleteOshi(oshi)
                dismiss()
            }
        } message: {
            Text("\(oshi.name)のフォローを解除しますか?")
        }
        .task {
            print("🖼️ OshiProfileDetailView: \(oshi.name) (isPreset: \(isPreset))")
            print("  - avatarImageURL: \(oshi.avatarImageURL ?? "nil")")
            
            if let urlString = oshi.avatarImageURL, !urlString.isEmpty {
                isLoadingImage = true
                
                do {
                    let image = try await FirebaseStorageManager.shared.downloadImage(from: urlString)
                    await MainActor.run {
                        avatarImage = image
                        isLoadingImage = false
                        print("  ✅ 画像読み込み成功")
                    }
                } catch {
                    await MainActor.run {
                        isLoadingImage = false
                    }
                    print("  ❌ 画像読み込み失敗: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Avatar Section
    
    private var avatarSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // 背景のグラデーションリング
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.pink.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: avatarSize + 12, height: avatarSize + 12)
                
                avatarView
            }
        }
    }
    
    private var avatarView: some View {
        Group {
            if isLoadingImage {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: avatarSize, height: avatarSize)
                    .overlay(
                        ProgressView()
                            .tint(.gray)
                    )
            } else if let image = avatarImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: avatarSize, height: avatarSize)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: avatarSize, height: avatarSize)
                    .overlay(
                        Text(String(oshi.name.prefix(1)))
                            .font(.system(size: 40, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    )
            }
        }
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Profile Info Section
    
    private var profileInfoSection: some View {
        VStack(spacing: 12) {
            // 名前
            Text(oshi.name)
                .font(.title2)
                .fontWeight(.bold)
            
            // 自己紹介
            if !oshi.speechCharacteristics.isEmpty {
                Text(oshi.speechCharacteristics)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
            
            // キャラクター属性タグ
            characterTagsView
                .padding(.top, 4)
        }
    }
    
    private var characterTagsView: some View {
        FlowLayout(spacing: 8) {
            if let gender = oshi.gender {
                TagView(text: gender.rawValue, icon: gender.icon)
            }
            
            // 性格タグを分割して表示
            if !oshi.personalityText.isEmpty {
                ForEach(splitTags(oshi.personalityText), id: \.self) { tag in
                    TagView(text: tag, icon: "heart.fill")
                }
            }
            
            // 話し方タグを分割して表示
            if !oshi.speechStyleText.isEmpty {
                ForEach(splitTags(oshi.speechStyleText), id: \.self) { tag in
                    TagView(text: tag, icon: "text.bubble.fill")
                }
            }
        }
        .padding(.horizontal, 24)
    }

    // 「。」や「、」で分割してタグ化
    private func splitTags(_ text: String) -> [String] {
        text.components(separatedBy: CharacterSet(charactersIn: "。、"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
    
    // MARK: - Content Section
    
    private var contentSection: some View {
        VStack(spacing: 16) {
            // セクションヘッダー
            HStack {
                Text("ポスト")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // ✅ 投稿数を表示
                if !oshiPosts.isEmpty {
                    Text("\(oshiPosts.count)件")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            
            // ✅ 投稿がある場合は表示、ない場合は空状態
            if oshiPosts.isEmpty {
                emptyContentView(
                    icon: "bubble.left.and.bubble.right",
                    title: "まだポストがありません",
                    subtitle: "チャットを始めると、ここに表示されます"
                )
            } else {
                // ✅ 投稿一覧を表示
                LazyVStack(spacing: 0) {
                    ForEach(oshiPosts) { post in
                        PostCardView(post: post, viewModel: viewModel)
                        
                        if post.id != oshiPosts.last?.id {
                            Divider()
                                .padding(.leading, 68)
                        }
                    }
                }
                .background(Color(.systemBackground))
            }
        }
    }
    
    private func emptyContentView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 40)
            
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 80, height: 80)
                
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
                .frame(height: 60)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            var rowWidth: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    // 次の行へ
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                rowWidth = max(rowWidth, x - spacing)
            }
            
            size = CGSize(width: rowWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Tag View

struct TagView: View {
    let text: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 5) {
            if icon.count <= 2 {
                Text(icon)
                    .font(.caption)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.pink)
            }
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        OshiProfileDetailView(
            oshi: OshiCharacter(
                name: "さくら",
                gender: .female,
                personalityText: "優しくて明るい",
                speechCharacteristics: "アプリの個人開発してます 🌸 いつも応援ありがとう!開発やマーケティングの気づきを発信します",
                userCallingName: "あなた",
                speechStyleText: "敬語"
            ),
            viewModel: OshiViewModel(),
            isPreset: false  // ✅ プレビューではfalse
        )
    }
}

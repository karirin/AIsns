//
//  CommonComponents.swift
//  AIsns
//
//  Created: 2026/01/02 - Shared UI Components
//

import SwiftUI

// MARK: - Avatar View

/// 統一されたアバター表示コンポーネント
struct AvatarView: View {
    let image: UIImage?
    let name: String
    let size: CGFloat
    var showBorder: Bool = false
    var borderGradient: LinearGradient = AppColors.primaryGradient
    var placeholderGradient: LinearGradient = AppColors.pinkGradient
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(placeholderGradient)
                    .frame(width: size, height: size)
                    .overlay(
                        Text(String(name.prefix(1)))
                            .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    )
            }
        }
        .overlay(
            Circle()
                .stroke(showBorder ? borderGradient : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom), lineWidth: showBorder ? 3 : 0)
                .padding(-2)
        )
    }
}

/// 非同期で画像を読み込むアバター
struct AsyncAvatarView: View {
    let imageURL: String?
    let name: String
    let size: CGFloat
    var showBorder: Bool = false
    var borderGradient: LinearGradient = AppColors.primaryGradient
    var placeholderGradient: LinearGradient = AppColors.pinkGradient
    
    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        AvatarView(
            image: loadedImage,
            name: name,
            size: size,
            showBorder: showBorder,
            borderGradient: borderGradient,
            placeholderGradient: placeholderGradient
        )
        .overlay(
            Group {
                if isLoading {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: size, height: size)
                        .shimmer()
                }
            }
        )
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard let urlString = imageURL, !urlString.isEmpty else { return }
        isLoading = true
        loadedImage = try? await FirebaseStorageManager.shared.downloadImage(from: urlString)
        isLoading = false
    }
}

// MARK: - Badge View

/// バッジ表示コンポーネント
struct BadgeView: View {
    let count: Int
    var maxCount: Int = 99
    var size: CGFloat = 20
    var gradient: LinearGradient = AppColors.pinkGradient
    
    var displayText: String {
        count > maxCount ? "\(maxCount)+" : "\(count)"
    }
    
    var body: some View {
        if count > 0 {
            Text(displayText)
                .font(.system(size: size * 0.55, weight: .bold))
                .foregroundColor(.white)
                .frame(minWidth: size, minHeight: size)
                .padding(.horizontal, count > 9 ? 4 : 0)
                .background(gradient)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Tag View

/// タグ表示コンポーネント
struct AppTagView: View {
    let text: String
    var icon: String? = nil
    var style: TagStyle = .default
    
    enum TagStyle {
        case `default`
        case primary
        case success
        case warning
        case pink
        
        var backgroundColor: Color {
            switch self {
            case .default: return Color(.systemGray6)
            case .primary: return AppColors.primary.opacity(0.1)
            case .success: return AppColors.success.opacity(0.1)
            case .warning: return AppColors.warning.opacity(0.1)
            case .pink: return AppColors.pink.opacity(0.1)
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .default: return .secondary
            case .primary: return AppColors.primary
            case .success: return AppColors.success
            case .warning: return AppColors.warning
            case .pink: return AppColors.pink
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
            }
            
            Text(text)
                .font(AppTypography.caption)
        }
        .foregroundColor(style.foregroundColor)
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background(style.backgroundColor)
        .clipShape(Capsule())
    }
}

// MARK: - Section Header

/// セクションヘッダー
struct SectionHeader: View {
    let title: String
    var icon: String? = nil
    var iconColor: Color = AppColors.primary
    var action: (() -> Void)? = nil
    var actionLabel: String? = nil
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            if let icon = icon {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(iconColor)
                }
            }
            
            Text(title)
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            if let action = action, let actionLabel = actionLabel {
                Button(action: action) {
                    Text(actionLabel)
                        .font(AppTypography.subheadlineMedium)
                        .foregroundColor(AppColors.primary)
                }
            }
        }
    }
}

// MARK: - Empty State View

/// 空状態の表示コンポーネント
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.primary.opacity(0.08),
                                AppColors.pink.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: icon)
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(AppColors.primaryGradient)
            }
            
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text(title)
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(subtitle)
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, DesignTokens.Spacing.xxl)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Text(actionTitle)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, DesignTokens.Spacing.sm)
            }
            
            Spacer()
        }
    }
}

// MARK: - Loading View

/// ローディング表示コンポーネント
struct LoadingView: View {
    let message: String
    var subtitle: String? = nil
    
    @State private var isRotating = false
    @State private var isPulsing = false
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            ZStack {
                // 背景リング
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 4)
                    .frame(width: 64, height: 64)
                
                // アニメーションリング
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        AppColors.primaryGradientH,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(isRotating ? 360 : 0))
                
                // 中央アイコン
                Image(systemName: "sparkles")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(AppColors.primaryGradient)
                    .scaleEffect(isPulsing ? 1.1 : 1.0)
                    .opacity(isPulsing ? 0.8 : 1.0)
            }
            
            VStack(spacing: DesignTokens.Spacing.xs) {
                Text(message)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                isRotating = true
            }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Action Button Row

/// アクションボタン（いいね、コメント等）
struct ActionButtonView: View {
    let icon: String
    var count: Int? = nil
    var isActive: Bool = false
    var activeColor: Color = AppColors.pink
    var inactiveColor: Color = AppColors.textSecondary
    let action: () -> Void
    
    // ✅ 修正: .fill版が存在しないアイコンを考慮
    private var displayIcon: String {
        guard isActive else { return icon }
        
        // fill版が存在しないアイコンのリスト
        let noFillIcons = ["arrow.2.squarepath", "square.and.arrow.up", "paperplane"]
        
        if noFillIcons.contains(icon) {
            return icon  // そのまま返す
        }
        
        return "\(icon).fill"
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: displayIcon)
                    .font(.system(size: DesignTokens.IconSize.sm))
                
                if let count = count, count > 0 {
                    Text("\(count)")
                        .font(AppTypography.footnote)
                }
            }
            .foregroundColor(isActive ? activeColor : inactiveColor)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Floating Action Button

/// フローティングアクションボタン
struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = 56
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(AppColors.primaryGradient)
                    .frame(width: size, height: size)
                    .shadow(
                        color: AppColors.primary.opacity(0.4),
                        radius: 12,
                        x: 0,
                        y: 6
                    )
                
                Image(systemName: icon)
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .pressableStyle()
    }
}

// MARK: - Navigation Bar Button

/// ナビゲーションバーボタン
struct NavBarButton: View {
    let icon: String
    var badge: Int? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: icon)
                    .font(.system(size: DesignTokens.IconSize.md, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 32, height: 32)
                
                if let badge = badge, badge > 0 {
                    BadgeView(count: badge, size: 16)
                        .offset(x: 6, y: -4)
                }
            }
        }
    }
}

// MARK: - Divider

/// カスタムディバイダー
struct AppDivider: View {
    var leadingPadding: CGFloat = 0
    var color: Color = Color(.separator)
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: 0.5)
            .padding(.leading, leadingPadding)
    }
}

// MARK: - Toast View

/// トースト通知
struct ToastView: View {
    let message: String
    var icon: String? = "checkmark"
    var style: ToastStyle = .success
    
    enum ToastStyle {
        case success
        case error
        case info
        
        var gradient: LinearGradient {
            switch self {
            case .success: return AppColors.successGradient
            case .error: return LinearGradient(colors: [AppColors.error], startPoint: .leading, endPoint: .trailing)
            case .info: return AppColors.primaryGradientH
            }
        }
    }
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            if let icon = icon {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            Text(message)
                .font(AppTypography.bodyMedium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.md)
        .background(
            Capsule()
                .fill(style.gradient)
                .shadow(color: Color.black.opacity(0.15), radius: 12, y: 6)
        )
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Relative Time Text

/// X/Twitter風の相対時間表示
struct RelativeTimeText: View {
    let date: Date
    
    var body: some View {
        TimelineView(.periodic(from: Date(), by: 60)) { context in
            Text(Self.format(from: date, now: context.date))
        }
    }
    
    private static func format(from date: Date, now: Date) -> String {
        let diff = max(0, Int(now.timeIntervalSince(date)))
        
        if diff < 60 { return "たった今" }
        
        let minutes = diff / 60
        if minutes < 60 { return "\(minutes)分" }
        
        let hours = minutes / 60
        if hours < 24 { return "\(hours)時間" }
        
        let days = hours / 24
        if days < 7 { return "\(days)日" }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview("Common Components") {
    ScrollView {
        VStack(spacing: 32) {
            // Avatars
            VStack(alignment: .leading, spacing: 16) {
                Text("Avatars").font(AppTypography.headline)
                
                HStack(spacing: 16) {
                    AvatarView(image: nil, name: "テスト", size: DesignTokens.AvatarSize.sm)
                    AvatarView(image: nil, name: "ユーザー", size: DesignTokens.AvatarSize.md)
                    AvatarView(image: nil, name: "さくら", size: DesignTokens.AvatarSize.lg, showBorder: true)
                    AvatarView(image: nil, name: "推し", size: DesignTokens.AvatarSize.xl)
                }
            }
            .padding()
            
            // Tags
            VStack(alignment: .leading, spacing: 16) {
                Text("Tags").font(AppTypography.headline)
                
                HStack(spacing: 8) {
                    AppTagView(text: "デフォルト")
                    AppTagView(text: "プライマリ", icon: "star.fill", style: .primary)
                    AppTagView(text: "成功", style: .success)
                    AppTagView(text: "ピンク", style: .pink)
                }
            }
            .padding()
            
            // Badges
            VStack(alignment: .leading, spacing: 16) {
                Text("Badges").font(AppTypography.headline)
                
                HStack(spacing: 16) {
                    BadgeView(count: 1)
                    BadgeView(count: 9)
                    BadgeView(count: 99)
                    BadgeView(count: 100)
                }
            }
            .padding()
            
            // Empty State
            EmptyStateView(
                icon: "bubble.left.and.bubble.right",
                title: "投稿がありません",
                subtitle: "最初の投稿をしてみましょう",
                actionTitle: "投稿を作成",
                action: {}
            )
            .frame(height: 300)
            
            // Toast
            ToastView(message: "保存しました", style: .success)
            ToastView(message: "エラーが発生しました", icon: "xmark", style: .error)
            
            // Loading
            LoadingView(message: "読み込み中...", subtitle: "少々お待ちください")
                .frame(height: 200)
        }
    }
}

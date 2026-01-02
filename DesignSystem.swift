//
//  DesignSystem.swift
//  AIsns
//
//  Created: 2026/01/02 - Unified Design System
//

import SwiftUI

// MARK: - Design Tokens

/// アプリ全体で使用するデザイントークン
enum DesignTokens {
    
    // MARK: - Spacing
    
    enum Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 40
        static let xxxxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    
    enum Radius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let full: CGFloat = 9999
    }
    
    // MARK: - Font Sizes
    
    enum FontSize {
        static let caption2: CGFloat = 11
        static let caption: CGFloat = 12
        static let footnote: CGFloat = 13
        static let subheadline: CGFloat = 14
        static let body: CGFloat = 15
        static let callout: CGFloat = 16
        static let headline: CGFloat = 17
        static let title3: CGFloat = 20
        static let title2: CGFloat = 22
        static let title: CGFloat = 28
        static let largeTitle: CGFloat = 34
    }
    
    // MARK: - Icon Sizes
    
    enum IconSize {
        static let xs: CGFloat = 12
        static let sm: CGFloat = 16
        static let md: CGFloat = 20
        static let lg: CGFloat = 24
        static let xl: CGFloat = 28
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
    }
    
    // MARK: - Avatar Sizes
    
    enum AvatarSize {
        static let xs: CGFloat = 24
        static let sm: CGFloat = 32
        static let md: CGFloat = 40
        static let lg: CGFloat = 48
        static let xl: CGFloat = 56
        static let xxl: CGFloat = 72
        static let xxxl: CGFloat = 100
        static let xxxxl: CGFloat = 120
    }
    
    // MARK: - Shadow
    
    enum Shadow {
        static let sm = (color: Color.black.opacity(0.04), radius: CGFloat(4), y: CGFloat(2))
        static let md = (color: Color.black.opacity(0.06), radius: CGFloat(8), y: CGFloat(4))
        static let lg = (color: Color.black.opacity(0.08), radius: CGFloat(16), y: CGFloat(8))
        static let xl = (color: Color.black.opacity(0.12), radius: CGFloat(24), y: CGFloat(12))
    }
    
    // MARK: - Animation
    
    enum Animation {
        static let fast = SwiftUI.Animation.easeOut(duration: 0.15)
        static let normal = SwiftUI.Animation.easeOut(duration: 0.25)
        static let slow = SwiftUI.Animation.easeOut(duration: 0.35)
        static let spring = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.7)
        static let bouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
    }
}

// MARK: - App Colors

/// アプリのカラーパレット
struct AppColors {
    
    // MARK: - Primary Gradient
    
    /// メインのグラデーション（アクセントカラー）
    // 修正: colors: [...] ではなく、gradient: Gradient(colors: [...]) を使用
    static let primaryGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "0EA5E9"),  // Sky Blue
            Color(hex: "6366F1"),  // Indigo
            Color(hex: "8B5CF6")   // Violet
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 水平方向のプライマリグラデーション
    static let primaryGradientH: LinearGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "0EA5E9"),
            Color(hex: "6366F1")
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - Secondary Gradients
    
    /// サクセス（緑系）
    static let successGradient: LinearGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "10B981"),
            Color(hex: "059669")
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// ワーニング（オレンジ系）
    static let warningGradient: LinearGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "F59E0B"),
            Color(hex: "D97706")
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// エラー/ピンク（いいね等）
    static let pinkGradient: LinearGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "EC4899"),
            Color(hex: "DB2777")
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// ゴールド/イエロー
    static let goldGradient: LinearGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "FBBF24"),
            Color(hex: "F59E0B")
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Solid Colors
    
    static let primary = Color(hex: "6366F1")
    static let primaryLight = Color(hex: "818CF8")
    static let primaryDark = Color(hex: "4F46E5")
    
    static let secondary = Color(hex: "64748B")
    static let secondaryLight = Color(hex: "94A3B8")
    static let secondaryDark = Color(hex: "475569")
    
    static let success = Color(hex: "10B981")
    static let warning = Color(hex: "F59E0B")
    static let error = Color(hex: "EF4444")
    static let pink = Color(hex: "EC4899")
    
    // MARK: - Background Colors
    
    static let backgroundPrimary = Color(.systemBackground)
    static let backgroundSecondary = Color(.secondarySystemBackground)
    static let backgroundTertiary = Color(.tertiarySystemBackground)
    
    /// 柔らかいグラデーション背景
    static let softBackground: LinearGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "F0F9FF"),  // Sky 50
            Color(hex: "F5F3FF")   // Violet 50
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// ダークモード用の柔らかい背景
    static let softBackgroundDark: LinearGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "0F172A"),
            Color(hex: "1E1B4B")
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Text Colors
    
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)
    
    // MARK: - Border Colors
    
    static let border = Color(.separator)
    static let borderLight = Color(.separator).opacity(0.5)
    
    // MARK: - Overlay Colors
    
    static let overlay = Color.black.opacity(0.4)
    static let overlayLight = Color.black.opacity(0.2)
}

// MARK: - App Typography

/// アプリのタイポグラフィスタイル
struct AppTypography {
    
    // MARK: - Display
    
    static let largeTitle = Font.system(size: DesignTokens.FontSize.largeTitle, weight: .bold, design: .rounded)
    static let title = Font.system(size: DesignTokens.FontSize.title, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: DesignTokens.FontSize.title2, weight: .bold, design: .rounded)
    static let title3 = Font.system(size: DesignTokens.FontSize.title3, weight: .semibold, design: .rounded)
    
    // MARK: - Body
    
    static let headline = Font.system(size: DesignTokens.FontSize.headline, weight: .semibold)
    static let body = Font.system(size: DesignTokens.FontSize.body, weight: .regular)
    static let bodyMedium = Font.system(size: DesignTokens.FontSize.body, weight: .medium)
    static let callout = Font.system(size: DesignTokens.FontSize.callout, weight: .regular)
    static let calloutMedium = Font.system(size: DesignTokens.FontSize.callout, weight: .medium)
    
    // MARK: - Small
    
    static let subheadline = Font.system(size: DesignTokens.FontSize.subheadline, weight: .regular)
    static let subheadlineMedium = Font.system(size: DesignTokens.FontSize.subheadline, weight: .medium)
    static let footnote = Font.system(size: DesignTokens.FontSize.footnote, weight: .regular)
    static let footnoteMedium = Font.system(size: DesignTokens.FontSize.footnote, weight: .medium)
    static let caption = Font.system(size: DesignTokens.FontSize.caption, weight: .regular)
    static let captionMedium = Font.system(size: DesignTokens.FontSize.caption, weight: .medium)
    static let caption2 = Font.system(size: DesignTokens.FontSize.caption2, weight: .regular)
}

// MARK: - View Extensions

extension View {
    
    /// プライマリグラデーションを適用
    func primaryGradientForeground() -> some View {
        self.foregroundStyle(AppColors.primaryGradient)
    }
    
    /// カード風のスタイルを適用
    func cardStyle(
        cornerRadius: CGFloat = DesignTokens.Radius.lg,
        shadowSize: (color: Color, radius: CGFloat, y: CGFloat) = DesignTokens.Shadow.md
    ) -> some View {
        self
            .background(Color(.systemBackground))
            .cornerRadius(cornerRadius)
            .shadow(color: shadowSize.color, radius: shadowSize.radius, x: 0, y: shadowSize.y)
    }
    
    /// グラスモーフィズム効果
    func glassStyle(cornerRadius: CGFloat = DesignTokens.Radius.xl) -> some View {
        self
            .background(.ultraThinMaterial)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
    
    /// ボタンのスケールエフェクト
    func pressableStyle() -> some View {
        self.buttonStyle(PressableButtonStyle())
    }
    
    /// Shimmer ローディング効果
    func shimmer(isActive: Bool = true) -> some View {
        self.modifier(ShimmerModifier(isActive: isActive))
    }
}

// MARK: - Button Styles

/// 押した時にスケールするボタンスタイル
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(DesignTokens.Animation.fast, value: configuration.isPressed)
    }
}

/// プライマリボタンスタイル
struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.bodyMedium)
            .foregroundColor(.white)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(
                Group {
                    if isEnabled {
                        AppColors.primaryGradientH
                    } else {
                        LinearGradient(
                            colors: [Color.gray.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
            )
            .cornerRadius(DesignTokens.Radius.full)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(DesignTokens.Animation.fast, value: configuration.isPressed)
    }
}

/// セカンダリボタンスタイル（アウトライン）
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.bodyMedium)
            .foregroundColor(AppColors.primary)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(Color.clear)
            .cornerRadius(DesignTokens.Radius.full)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.full)
                    .stroke(AppColors.primary, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(DesignTokens.Animation.fast, value: configuration.isPressed)
    }
}

// MARK: - View Modifiers

/// Shimmer アニメーション
struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        if isActive {
            content
                .overlay(
                    GeometryReader { geometry in
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.3),
                                Color.white.opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 2)
                        .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                    }
                )
                .mask(content)
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
        } else {
            content
        }
    }
}

/// スケルトンプレースホルダー
struct SkeletonView: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16
    var cornerRadius: CGFloat = DesignTokens.Radius.sm
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color(.systemGray5))
            .frame(width: width, height: height)
            .shimmer()
    }
}

// MARK: - Preview

#Preview("Design System") {
    ScrollView {
        VStack(spacing: 32) {
            // Colors
            VStack(alignment: .leading, spacing: 16) {
                Text("Primary Gradient")
                    .font(AppTypography.headline)
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.primaryGradient)
                    .frame(height: 60)
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.pinkGradient)
                    .frame(height: 60)
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.successGradient)
                    .frame(height: 60)
            }
            .padding()
            
            // Typography
            VStack(alignment: .leading, spacing: 12) {
                Text("Typography")
                    .font(AppTypography.headline)
                
                Text("Large Title").font(AppTypography.largeTitle)
                Text("Title").font(AppTypography.title)
                Text("Title 2").font(AppTypography.title2)
                Text("Headline").font(AppTypography.headline)
                Text("Body").font(AppTypography.body)
                Text("Caption").font(AppTypography.caption)
            }
            .padding()
            
            // Buttons
            VStack(spacing: 16) {
                Text("Buttons")
                    .font(AppTypography.headline)
                
                Button("Primary Button") {}
                    .buttonStyle(PrimaryButtonStyle())
                
                Button("Secondary Button") {}
                    .buttonStyle(SecondaryButtonStyle())
            }
            .padding()
            
            // Skeleton
            VStack(alignment: .leading, spacing: 12) {
                Text("Skeleton Loading")
                    .font(AppTypography.headline)
                
                HStack(spacing: 12) {
                    SkeletonView(width: 48, height: 48, cornerRadius: 24)
                    VStack(alignment: .leading, spacing: 8) {
                        SkeletonView(width: 120, height: 14)
                        SkeletonView(width: 80, height: 12)
                    }
                }
            }
            .padding()
        }
    }
}

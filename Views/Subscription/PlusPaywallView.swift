import StoreKit
import SwiftUI

struct PlusPaywallView: View {
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    @Environment(\.dismiss) private var dismiss

    // 添付デザインに合わせてデフォルトは月間プラン
    @State private var selectedPlanID: String = SubscriptionStore.plusMonthlyProductID
    @State private var isPurchasing = false
    @State private var appearAnimation = false

    private let privacyPolicyURL = URL(string: "https://aisns-4ea20.web.app/privacy.html")!
    private let termsOfUseURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    // MARK: - Palette（ライトは添付デザインのまま・ダークモードにも対応）

    private let pageBackground = Color(light: Color(hex: "F6F6FA"), dark: Color(hex: "12121A"))
    private let cardSurface = Color(light: .white, dark: Color(hex: "1D1D28"))
    private let titleColor = Color(light: .black, dark: .white)
    private let subtitleGray = Color(light: Color(hex: "8D8D96"), dark: Color(hex: "9B9BA8"))
    private let strokeGray = Color(light: Color(hex: "DCDDE4"), dark: Color(hex: "33333F"))
    private let heroImageHeight: CGFloat = 300

    private let premiumGradient = LinearGradient(
        colors: [Color(hex: "EF8EC1"), Color(hex: "B983F2"), Color(hex: "89A6F4")],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// StoreKitから取得した実際のプランを表示するためのモデル
    private struct PlanDisplay: Identifiable {
        let id: String
        let title: String
        let subtitle: String?
        let price: String
        let period: String
        let badge: String?
        let isPopular: Bool
        /// 無料トライアル日数（対象外なら nil）
        let trialDays: Int?
    }

    private var displayPlans: [PlanDisplay] {
        if !subscriptionStore.products.isEmpty {
            return subscriptionStore.products.sorted { lhs, rhs in
                planSortIndex(for: lhs.id) < planSortIndex(for: rhs.id)
            }.map { product in
                PlanDisplay(
                    id: product.id,
                    title: displayName(for: product),
                    subtitle: perPeriodLabel(for: product),
                    price: product.displayPrice,
                    period: periodLabel(for: product.id),
                    badge: badgeLabel(for: product.id),
                    isPopular: product.id == SubscriptionStore.plusMonthlyProductID,
                    trialDays: subscriptionStore.freeTrialDays(for: product)
                )
            }
        }
        return []
    }

    private var selectedPlan: PlanDisplay? {
        displayPlans.first { $0.id == selectedPlanID }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                hero
                    .staged(appearAnimation, delay: 0)

                benefitsGrid
                    .padding(.horizontal, 20)
                    .staged(appearAnimation, delay: 0.1)

                planSection
                    .padding(.horizontal, 20)
                    .staged(appearAnimation, delay: 0.2)

                trustRow
                    .padding(.horizontal, 20)
                    .staged(appearAnimation, delay: 0.3)

                restoreSection
                    .padding(.horizontal, 20)
                footnote
                    .padding(.horizontal, 20)

                legalLinks
                    .padding(.horizontal, 20)

                bottomBackButton
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 24)
        }
        .ignoresSafeArea(edges: .top)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !subscriptionStore.isPlusActive && !displayPlans.isEmpty {
                ctaBar
                    .staged(appearAnimation, delay: 0.25)
            }
        }
        .background(pageBackground)
        .navigationBarHidden(true)
        .task {
            await subscriptionStore.refreshEntitlements()
            if subscriptionStore.products.isEmpty {
                await subscriptionStore.loadProducts()
            }
        }
        .onAppear {
            AppAnalytics.log(.paywallView)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                appearAnimation = true
            }
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 10) {
            paywallImageSlot

            VStack(spacing: 10) {
                HStack(spacing: 14) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "F08AC6"), Color(hex: "A78BFA")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text(subscriptionStore.isPlusActive ? "Plus利用中" : "プレミアムプラン")
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundColor(titleColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Text(subscriptionStore.isPlusActive ? "広告非表示とチャット無制限が有効です" : "推しとの時間をもっと特別に")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(subtitleGray)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
        }
    }

    private var paywallImageSlot: some View {
        GeometryReader { proxy in
            Image("PlusPaywallHero")
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: heroImageHeight)
                .offset(y: 100)
                .clipped()
        }
        .frame(height: heroImageHeight)
        .clipped()
    }

    // MARK: - Benefits

    private struct Benefit: Identifiable {
        let id = UUID()
        let icon: String
        let tint: Color
        let title: String
        let detail: String
    }

    private var benefitItems: [Benefit] {
        [
            Benefit(icon: "infinity", tint: Color(hex: "D946EF"), title: "チャット無制限", detail: "推しとのチャットが\n無制限で楽しめる"),
            Benefit(icon: "rectangle.badge.xmark", tint: Color(hex: "FB923C"), title: "広告非表示", detail: "全ての広告が\n非表示になります"),
            Benefit(icon: "message.badge.filled.fill", tint: Color(hex: "EC4899"), title: "返信アップ", detail: "投稿やコメントへの\n反応が増えます"),
            Benefit(icon: "clock.badge.checkmark.fill", tint: Color(hex: "22C55E"), title: "投稿頻度アップ", detail: "タイムラインが\nもっと賑やかに"),
            Benefit(icon: "person.2.wave.2.fill", tint: Color(hex: "8B5CF6"), title: "AI同士の会話", detail: "推し同士の会話を\n楽しめます"),
            Benefit(icon: "slider.horizontal.3", tint: Color(hex: "3B82F6"), title: "詳細設定", detail: "性格や口調を\n細かく調整")
        ]
    }

    private var benefitsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("プレミアム特典")
                .font(.system(size: 22, weight: .heavy))
                .foregroundColor(subtitleGray)
                .padding(.horizontal, 4)

            GeometryReader { proxy in
                let cardWidth = max(150, (proxy.size.width - 12) / 2)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(benefitItems) { benefit in
                            benefitCard(benefit, width: cardWidth)
                        }
                    }
                }
            }
            .frame(height: 176)
        }
    }

    private func benefitCard(_ benefit: Benefit, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(benefit.tint.opacity(0.14))
                    .frame(width: 46, height: 46)

                Image(systemName: benefit.icon)
                    .font(.system(size: 23, weight: .bold))
                    .foregroundColor(benefit.tint)
            }

            Text(benefit.title)
                .font(.system(size: 16, weight: .heavy))
                .foregroundColor(titleColor)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(benefit.detail)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(subtitleGray)
                .lineSpacing(2)
                .lineLimit(3)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(width: width, alignment: .topLeading)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(cardSurface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 12, y: 4)
    }

    // MARK: - Plans

    private var planSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if subscriptionStore.isLoadingProducts && displayPlans.isEmpty {
                ProgressView("プランを読み込み中...")
                    .frame(maxWidth: .infinity)
                    .padding(20)
            } else if displayPlans.isEmpty {
                VStack(spacing: 10) {
                    Text("プラン情報を取得できません")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textPrimary)
                    Text(subscriptionStore.productLoadingMessage ?? "時間をおいて再度お試しください。")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)

                    Button {
                        Task { await subscriptionStore.loadProducts() }
                    } label: {
                        Label("再読み込み", systemImage: "arrow.clockwise")
                            .font(AppTypography.bodyMedium)
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding(18)
                .background(cardSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                VStack(spacing: 14) {
                    ForEach(displayPlans) { plan in
                        planCard(for: plan)
                    }
                }
            }

            if !displayPlans.isEmpty,
               let message = subscriptionStore.productLoadingMessage {
                Text(message)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            if let error = subscriptionStore.purchaseErrorMessage {
                Text(error)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.error)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private func planCard(for plan: PlanDisplay) -> some View {
        let isSelected = plan.id == selectedPlanID

        return Button {
            generateHapticFeedback()
            withAnimation(DesignTokens.Animation.snappy) {
                selectedPlanID = plan.id
            }
        } label: {
            HStack(spacing: 12) {
                radioIndicator(isSelected: isSelected)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(titleColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        if let badge = plan.badge {
                            Text(badge)
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(plan.isPopular ? AppColors.pinkGradient : LinearGradient(colors: [Color(hex: "FF7A3D"), Color(hex: "FF9A3D")], startPoint: .leading, endPoint: .trailing))
                                .clipShape(Capsule())
                        }
                    }

                    if let trialDays = plan.trialDays {
                        Label("\(trialDays)日間無料トライアル", systemImage: "gift.fill")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(Color(hex: "22A35A"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    if let subtitle = plan.subtitle {
                        Text(subtitle)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(subtitleGray)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }

                Spacer(minLength: 8)

                // 価格は「金額＋期間」の縦積みで横幅を節約
                VStack(alignment: .trailing, spacing: 0) {
                    Text(plan.price)
                        .font(.system(size: 21, weight: .heavy))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(isSelected ? AnyShapeStyle(AppColors.pinkGradient) : AnyShapeStyle(titleColor))

                    Text("/\(plan.period)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(subtitleGray)
                }
                .layoutPriority(1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                cardSurface,
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        isSelected
                        ? AnyShapeStyle(LinearGradient(colors: [Color(hex: "F08AC6"), Color(hex: "8EA2FF")], startPoint: .leading, endPoint: .trailing))
                        : AnyShapeStyle(strokeGray),
                        lineWidth: isSelected ? 3 : 1.5
                    )
            )
            .shadow(
                color: isSelected ? Color(hex: "A78BFA").opacity(0.16) : Color.black.opacity(0.03),
                radius: isSelected ? 14 : 8,
                x: 0,
                y: isSelected ? 6 : 3
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(subscriptionStore.isPlusActive)
    }

    private func radioIndicator(isSelected: Bool) -> some View {
        ZStack {
            if isSelected {
                Circle()
                    .fill(AppColors.pinkGradient)
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(.white)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Circle()
                    .strokeBorder(strokeGray, lineWidth: 4)
            }
        }
        .frame(width: 34, height: 34)
    }

    // MARK: - CTA

    private var ctaBar: some View {
        VStack(spacing: 10) {
            Button {
                generateHapticFeedback()
                startPurchase()
            } label: {
                HStack(spacing: 14) {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 21, weight: .heavy))
                        Text(selectedPlan?.trialDays.map { "\($0)日間無料で試す" } ?? "プレミアムを始める")
                            .font(.system(size: 21, weight: .heavy))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 70)
                .background(premiumGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.35), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
                .overlay(CTASheenView())
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(
                    color: Color(hex: "A78BFA").opacity(0.22),
                    radius: 18,
                    x: 0,
                    y: 8
                )
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(isPurchasing)

            // 選択中プランの要約
            Group {
                if let plan = selectedPlan, let trialDays = plan.trialDays {
                    Text("\(trialDays)日間無料、その後 \(plan.price)/\(plan.period) ・ いつでもキャンセルできます")
                } else if let plan = selectedPlan {
                    Text("\(plan.title) \(plan.price)/\(plan.period) ・ いつでもキャンセルできます")
                } else {
                    Text("いつでもキャンセルできます")
                }
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(subtitleGray)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity)
            .animation(DesignTokens.Animation.fast, value: selectedPlanID)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(
            pageBackground
                .opacity(0.96)
                .overlay(alignment: .top) {
                    // 上端をふわっとフェードさせてコンテンツと馴染ませる
                    LinearGradient(
                        colors: [pageBackground.opacity(0), pageBackground],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 24)
                    .offset(y: -24)
                }
        )
    }

    private func startPurchase() {
        if let product = subscriptionStore.products.first(where: { $0.id == selectedPlanID }) {
            isPurchasing = true
            Task {
                await subscriptionStore.purchase(product)
                await MainActor.run { isPurchasing = false }
            }
            return
        }
    }

    // MARK: - Trust / Restore / Footnote

    private var trustRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "22C55E"))

            Text("App Storeを通じた安全な決済")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(subtitleGray)
        }
        .frame(maxWidth: .infinity)
    }

    private var restoreSection: some View {
        VStack(spacing: 4) {
            Button {
                Task { await subscriptionStore.restorePurchases() }
            } label: {
                Text("購入を復元")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }

#if DEBUG
            Button(subscriptionStore.isPlusActive ? "DEBUG: PlusをOFF" : "DEBUG: PlusをON") {
                subscriptionStore.setDebugPlusActive(!subscriptionStore.isPlusActive)
            }
            .font(AppTypography.caption)
            .foregroundColor(AppColors.textSecondary)
#endif
        }
    }

    private var footnote: some View {
        Text("無料トライアルは初めてご利用の方が対象です。トライアル終了の24時間前までにキャンセルしない限り、選択したプランの料金が自動的に請求されます。サブスクリプションは期間終了の24時間前までにキャンセルしない限り自動更新されます。購入後はApp Storeのアカウント設定から管理できます。")
            .font(AppTypography.caption2)
            .foregroundColor(AppColors.textTertiary)
            .lineSpacing(2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var legalLinks: some View {
        HStack(spacing: 20) {
            Link(destination: termsOfUseURL) {
                Label("利用規約", systemImage: "arrow.up.right.square")
            }
            .accessibilityIdentifier("plus_terms_of_use_link")

            Link(destination: privacyPolicyURL) {
                Label("プライバシーポリシー", systemImage: "arrow.up.right.square")
            }
            .accessibilityIdentifier("plus_privacy_policy_link")
        }
        .font(AppTypography.caption)
        .foregroundColor(AppColors.primary)
        .frame(maxWidth: .infinity)
    }

    private var bottomBackButton: some View {
        Button {
            dismiss()
        } label: {
            Label("戻る", systemImage: "chevron.left")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(titleColor)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(cardSurface)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(strokeGray, lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("前の画面に戻る")
    }

    // MARK: - Helpers

    private func displayName(for product: Product) -> String {
        switch product.id {
        case SubscriptionStore.plusWeeklyProductID:
            return "週間プラン"
        case SubscriptionStore.plusMonthlyProductID:
            return "月間プラン"
        case SubscriptionStore.plusYearlyProductID:
            return "年間プラン"
        default:
            return product.displayName
        }
    }

    /// 「月あたり◯◯円」などの補足表示
    private func perPeriodLabel(for product: Product) -> String? {
        switch product.id {
        case SubscriptionStore.plusYearlyProductID:
            let monthly = product.price / 12
            return "月額換算 \(monthly.formatted(product.priceFormatStyle))"
        default:
            return nil
        }
    }

    private func periodLabel(for productID: String) -> String {
        switch productID {
        case SubscriptionStore.plusWeeklyProductID:
            return "週"
        case SubscriptionStore.plusMonthlyProductID:
            return "月"
        case SubscriptionStore.plusYearlyProductID:
            return "年"
        default:
            return ""
        }
    }

    private func badgeLabel(for productID: String) -> String? {
        switch productID {
        case SubscriptionStore.plusMonthlyProductID:
            return "人気"
        case SubscriptionStore.plusYearlyProductID:
            return "2ヶ月分お得"
        default:
            return nil
        }
    }

    private func planSortIndex(for productID: String) -> Int {
        switch productID {
        case SubscriptionStore.plusYearlyProductID:
            return 0
        case SubscriptionStore.plusMonthlyProductID:
            return 1
        case SubscriptionStore.plusWeeklyProductID:
            return 2
        default:
            return 3
        }
    }
}

// MARK: - Staged Appear Modifier

private extension View {
    /// 登場時に下からふわっと現れるステージングを適用
    func staged(_ isVisible: Bool, delay: Double) -> some View {
        self
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 18)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.85).delay(delay),
                value: isVisible
            )
    }
}

// MARK: - CTA Sheen

/// CTAボタンの上を定期的に横切る光のエフェクト
private struct CTASheenView: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [
                    .white.opacity(0),
                    .white.opacity(0.35),
                    .white.opacity(0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geo.size.width * 0.45)
            .rotationEffect(.degrees(18))
            .offset(x: phase * geo.size.width * 1.6)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 2.4)
                    .repeatForever(autoreverses: false)
                    .delay(0.8)
                ) {
                    phase = 1
                }
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    NavigationStack {
        PlusPaywallView()
            .environmentObject(SubscriptionStore())
    }
}

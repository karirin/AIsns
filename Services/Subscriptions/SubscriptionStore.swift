import Foundation
import OSLog
import StoreKit

@MainActor
final class SubscriptionStore: ObservableObject {
    static let plusWeeklyProductID = "aimate_plus_weekly"
    static let plusMonthlyProductID = "aimate_plus_monthly"
    static let plusYearlyProductID = "aimate_plus_yearly"

    static let plusProductIDs: Set<String> = [
        plusWeeklyProductID,
        plusMonthlyProductID,
        plusYearlyProductID
    ]

    @Published private(set) var products: [Product] = []
    @Published private(set) var isPlusActive = false
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var productLoadingMessage: String?
    @Published var purchaseErrorMessage: String?
    /// 無料トライアルを利用できる商品ID（過去にトライアル/購入済みのユーザーは空になる）
    @Published private(set) var trialEligibleProductIDs: Set<String> = []

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "AIsns",
        category: "StoreKit"
    )
    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = listenForTransactions()
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProducts() async {
        guard !isLoadingProducts else { return }

        isLoadingProducts = true
        productLoadingMessage = nil
        purchaseErrorMessage = nil
        defer { isLoadingProducts = false }

        do {
            let requestedIDs = Self.plusProductIDs.sorted()
            let loadedProducts = try await Product.products(for: requestedIDs)
            products = loadedProducts.sorted { lhs, rhs in
                sortPriority(for: lhs.id) < sortPriority(for: rhs.id)
            }
            await refreshTrialEligibility()

            let receivedIDs = Set(loadedProducts.map(\.id))
            let missingIDs = Self.plusProductIDs.subtracting(receivedIDs).sorted()

            if loadedProducts.isEmpty {
                productLoadingMessage = "プラン情報を取得できませんでした。通信環境を確認して再試行してください。"
            } else if !missingIDs.isEmpty {
                productLoadingMessage = "一部のプランを取得できませんでした。"
            }

            if !missingIDs.isEmpty {
                logger.error(
                    "StoreKit returned \(loadedProducts.count, privacy: .public)/\(requestedIDs.count, privacy: .public) products. Missing IDs: \(missingIDs.joined(separator: ", "), privacy: .public). Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown", privacy: .public)"
                )
            }
        } catch {
            products = []
            productLoadingMessage = "プラン情報を取得できませんでした。時間をおいて再試行してください。"
            logger.error("StoreKit product request failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func purchase(_ product: Product) async {
        purchaseErrorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseErrorMessage = "購入を完了できませんでした。"
        }
    }

    func restorePurchases() async {
        purchaseErrorMessage = nil

        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            purchaseErrorMessage = "購入の復元に失敗しました。"
        }
    }

#if DEBUG
    func setDebugPlusActive(_ active: Bool) {
        isPlusActive = active
    }
#endif

    func refreshEntitlements() async {
        var hasActivePlus = false

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            guard Self.plusProductIDs.contains(transaction.productID) else { continue }
            guard transaction.revocationDate == nil else { continue }

            if let expirationDate = transaction.expirationDate {
                hasActivePlus = expirationDate > Date()
            } else {
                hasActivePlus = true
            }

            if hasActivePlus { break }
        }

        isPlusActive = hasActivePlus
        await refreshTrialEligibility()
    }

    /// 無料トライアルの日数。対象外（トライアル無し・利用済み）の場合は nil
    func freeTrialDays(for product: Product) -> Int? {
        guard trialEligibleProductIDs.contains(product.id),
              let offer = product.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else { return nil }

        let period = offer.period
        let days: Int
        switch period.unit {
        case .day: days = period.value
        case .week: days = period.value * 7
        case .month: days = period.value * 30
        case .year: days = period.value * 365
        @unknown default: return nil
        }
        return days * offer.periodCount
    }

    private func refreshTrialEligibility() async {
        var eligibleIDs: Set<String> = []
        for product in products {
            guard let subscription = product.subscription,
                  subscription.introductoryOffer?.paymentMode == .freeTrial else { continue }
            if await subscription.isEligibleForIntroOffer {
                eligibleIDs.insert(product.id)
            }
        }
        trialEligibleProductIDs = eligibleIDs
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            guard let self else { return }

            for await result in Transaction.updates {
                guard let transaction = try? self.checkVerified(result) else { continue }
                await transaction.finish()
                await self.refreshEntitlements()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw StoreError.failedVerification
        }
    }

    private func sortPriority(for productID: String) -> Int {
        switch productID {
        case Self.plusWeeklyProductID:
            return 0
        case Self.plusMonthlyProductID:
            return 1
        case Self.plusYearlyProductID:
            return 2
        default:
            return 99
        }
    }
}

private enum StoreError: Error {
    case failedVerification
}

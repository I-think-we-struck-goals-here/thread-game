import Combine
import Foundation
import StoreKit

struct ThreadArchiveStoreProduct: Equatable, Sendable {
    let displayName: String
    let description: String
    let displayPrice: String
}

enum ThreadArchivePurchaseOutcome: Equatable, Sendable {
    case purchased
    case pending
    case cancelled
}

protocol ThreadArchivePurchaseServicing: Sendable {
    func loadProduct() async throws -> ThreadArchiveStoreProduct
    func hasCurrentEntitlement() async -> Bool
    func purchase() async throws -> ThreadArchivePurchaseOutcome
    func restore() async throws -> Bool
    func entitlementUpdates() -> AsyncStream<Bool>
}

enum ThreadArchiveStoreError: LocalizedError {
    case productUnavailable
    case unverifiedTransaction
    case unexpectedPurchaseResult

    var errorDescription: String? {
        switch self {
        case .productUnavailable:
            return "The Archive is temporarily unavailable. Please try again."
        case .unverifiedTransaction:
            return "The App Store could not verify this purchase."
        case .unexpectedPurchaseResult:
            return "The purchase could not be completed. Please try again."
        }
    }
}

actor StoreKitThreadArchivePurchaseService: ThreadArchivePurchaseServicing {
    static let productID = "co.dailythread.threadapp.archive"

    private var cachedProduct: Product?

    func loadProduct() async throws -> ThreadArchiveStoreProduct {
        let product = try await archiveProduct()
        return ThreadArchiveStoreProduct(
            displayName: product.displayName,
            description: product.description,
            displayPrice: product.displayPrice
        )
    }

    func hasCurrentEntitlement() async -> Bool {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.productID == Self.productID,
                  transaction.revocationDate == nil else {
                continue
            }
            return true
        }
        return false
    }

    func purchase() async throws -> ThreadArchivePurchaseOutcome {
        let product = try await archiveProduct()

        switch try await product.purchase() {
        case .success(let result):
            let transaction = try Self.verifiedTransaction(result)
            guard transaction.productID == Self.productID,
                  transaction.revocationDate == nil else {
                throw ThreadArchiveStoreError.unverifiedTransaction
            }
            await transaction.finish()
            return .purchased

        case .pending:
            return .pending

        case .userCancelled:
            return .cancelled

        @unknown default:
            throw ThreadArchiveStoreError.unexpectedPurchaseResult
        }
    }

    func restore() async throws -> Bool {
        try await AppStore.sync()
        return await hasCurrentEntitlement()
    }

    nonisolated func entitlementUpdates() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            let task = Task {
                for await result in Transaction.updates {
                    guard !Task.isCancelled,
                          case .verified(let transaction) = result,
                          transaction.productID == Self.productID else {
                        continue
                    }

                    continuation.yield(transaction.revocationDate == nil)
                    await transaction.finish()
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private func archiveProduct() async throws -> Product {
        if let cachedProduct {
            return cachedProduct
        }

        let products = try await Product.products(for: [Self.productID])
        guard let product = products.first(where: { $0.id == Self.productID }) else {
            throw ThreadArchiveStoreError.productUnavailable
        }
        cachedProduct = product
        return product
    }

    private nonisolated static func verifiedTransaction(
        _ result: VerificationResult<Transaction>
    ) throws -> Transaction {
        switch result {
        case .verified(let transaction):
            return transaction
        case .unverified:
            throw ThreadArchiveStoreError.unverifiedTransaction
        }
    }
}

@MainActor
final class ThreadArchivePurchaseController: ObservableObject {
    @Published private(set) var product: ThreadArchiveStoreProduct?
    @Published private(set) var isEntitled = false
    @Published private(set) var isLoading = false
    @Published private(set) var isProcessing = false
    @Published private(set) var message: String?

    private let service: any ThreadArchivePurchaseServicing
    private var hasStarted = false
    private var entitlementUpdateRevision = 0
    private var entitlementUpdatesTask: Task<Void, Never>?

    init(service: any ThreadArchivePurchaseServicing = StoreKitThreadArchivePurchaseService()) {
        self.service = service
    }

    deinit {
        entitlementUpdatesTask?.cancel()
    }

    func start() async {
        guard !hasStarted else { return }
        hasStarted = true
        isLoading = true
        message = nil

        entitlementUpdatesTask = Task { [weak self, service] in
            for await isEntitled in service.entitlementUpdates() {
                guard let self else { return }
                self.entitlementUpdateRevision += 1
                self.isEntitled = isEntitled
            }
        }

        let entitlementRevisionAtLookupStart = entitlementUpdateRevision
        async let entitlement = service.hasCurrentEntitlement()
        async let storeProduct = service.loadProduct()

        let initialEntitlement = await entitlement
        if entitlementUpdateRevision == entitlementRevisionAtLookupStart {
            isEntitled = initialEntitlement
        }
        do {
            product = try await storeProduct
        } catch {
            message = error.localizedDescription
        }
        isLoading = false
    }

    @discardableResult
    func purchase() async -> Bool {
        guard !isProcessing else { return false }
        isProcessing = true
        message = nil
        defer { isProcessing = false }

        do {
            switch try await service.purchase() {
            case .purchased:
                entitlementUpdateRevision += 1
                isEntitled = true
                return true
            case .pending:
                message = "Purchase pending approval. The Archive will unlock automatically once approved."
            case .cancelled:
                break
            }
        } catch {
            message = error.localizedDescription
        }
        return false
    }

    @discardableResult
    func restore() async -> Bool {
        guard !isProcessing else { return false }
        isProcessing = true
        message = nil
        defer { isProcessing = false }

        do {
            let restored = try await service.restore()
            entitlementUpdateRevision += 1
            isEntitled = restored
            message = restored
                ? "Archive purchase restored."
                : "No Archive purchase was found for this Apple Account."
            return restored
        } catch {
            message = error.localizedDescription
            return false
        }
    }

    func retryProductLoad() async {
        guard !isProcessing else { return }
        isLoading = true
        message = nil
        do {
            product = try await service.loadProduct()
        } catch {
            message = error.localizedDescription
        }
        isLoading = false
    }
}

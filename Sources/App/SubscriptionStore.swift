import StoreKit
import Combine

@MainActor
final class SubscriptionStore: ObservableObject {
    static let productIDs: Set<String> = ["com.dd.fitnessplanner.monthly", "com.dd.fitnessplanner.yearly"]
    @Published private(set) var products: [Product] = []
    @Published private(set) var hasPremium = false
    @Published private(set) var isBusy = false
    @Published var message: String?
    private var updates: Task<Void, Never>?

    init() {
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = result {
                    await self.refreshEntitlements()
                    await transaction.finish()
                }
            }
        }
    }

    deinit { updates?.cancel() }

    func load() async {
        await refreshEntitlements()
        do {
            products = try await Product.products(for: Self.productIDs).sorted { $0.price < $1.price }
            if products.isEmpty { message = "Plans are unavailable. Run the shared Xcode scheme with its local StoreKit configuration, or configure products in App Store Connect." }
        } catch { message = error.localizedDescription }
    }

    func refreshEntitlements() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  Self.productIDs.contains(transaction.productID),
                  transaction.revocationDate == nil,
                  !transaction.isUpgraded else { continue }
            if let expiry = transaction.expirationDate, expiry <= Date() { continue }
            active = true
        }
        hasPremium = active
    }

    func purchase(_ product: Product) async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            switch try await product.purchase() {
            case .success(let result):
                guard case .verified(let transaction) = result else {
                    message = "The purchase could not be verified. No access was granted."
                    return
                }
                await refreshEntitlements()
                await transaction.finish()
            case .pending: message = "Your purchase is awaiting approval. Access will update when it is approved."
            case .userCancelled: break
            @unknown default: message = "The purchase returned an unfamiliar status. Please try restoring purchases."
            }
        } catch { message = error.localizedDescription }
    }

    func restore() async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            message = hasPremium ? "Your membership is restored." : "No active membership was found."
        } catch { message = error.localizedDescription }
    }
}

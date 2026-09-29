import StoreKit
import StoreKitTest
import XCTest

@testable import Subscription_Fitness_Planner

@available(iOS 17.0, *)
@MainActor
final class PurchaseTests: XCTestCase {
    private var session: SKTestSession!
    override func setUpWithError() throws {
        session = try SKTestSession(configurationFileNamed: "Subscriptions")
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
    }
    override func tearDownWithError() throws {
        session.clearTransactions()
        session = nil
    }

    func testPurchaseGrantsAccessAndRefundRemovesIt() async throws {
        let store = SubscriptionStore()
        await store.load()
        XCTAssertFalse(store.hasPremium)
        let transaction = try await session.buyProduct(identifier: "com.dd.fitnessplanner.monthly")
        try await assertEntitlement(true, store: store)
        try session.refundTransaction(identifier: UInt(transaction.id))
        try await assertEntitlement(false, store: store)
    }
    func testExpiredSubscriptionDoesNotGrantAccess() async throws {
        let store = SubscriptionStore()
        let transaction = try await session.buyProduct(identifier: "com.dd.fitnessplanner.monthly")
        try await assertEntitlement(true, store: store)
        try session.disableAutoRenewForTransaction(identifier: UInt(transaction.id))
        try session.expireSubscription(productIdentifier: "com.dd.fitnessplanner.monthly")
        try await assertEntitlement(false, store: store)
    }
    private func assertEntitlement(
        _ expected: Bool, store: SubscriptionStore, file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        // StoreKit changes propagate asynchronously through its transaction service.
        for _ in 0..<50 {
            await store.refreshEntitlements()
            if store.hasPremium == expected { return }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTAssertEqual(store.hasPremium, expected, file: file, line: line)
    }
    func testProductsLoadFromLocalConfiguration() async throws {
        let store = SubscriptionStore()
        await store.load()
        XCTAssertEqual(
            Set(store.products.map(\.id)), SubscriptionStore.productIDs,
            store.message ?? "No StoreKit message")
    }
}

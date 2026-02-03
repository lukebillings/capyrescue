import Foundation
import SwiftUI
import StoreKit

// MARK: - Subscription Manager
@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    // Product IDs - update these with your actual App Store Connect product IDs
    static let annualProductId = "com.capybara.pro.annual"
    static let monthlyProductId = "com.capybara.pro.monthly"
    
    @Published private(set) var products: [String: Product] = [:]
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published private(set) var activeSubscription: SubscriptionTier? = nil
    
    enum SubscriptionTier: String, Codable {
        case free
        case monthly
        case annual
        
        var displayName: String {
            switch self {
            case .free: return "Free"
            case .monthly: return "Pro (Monthly)"
            case .annual: return "Pro (Annual)"
            }
        }
        
        var startingCoins: Int {
            switch self {
            case .free: return 500
            case .monthly: return 2000
            case .annual: return 15000
            }
        }
        
        var monthlyCoins: Int {
            switch self {
            case .free: return 0
            case .monthly: return 2000
            case .annual: return 10000
            }
        }
        
        var hasAds: Bool {
            return self == .free
        }
        
        var hasProItems: Bool {
            return self != .free
        }
    }
    
    private init() {
        Task {
            await loadProducts()
            await checkSubscriptionStatus()
        }
    }
    
    // MARK: - Load Products
    func loadProducts() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        
        let productIds = [Self.annualProductId, Self.monthlyProductId]
        
        do {
            let fetchedProducts = try await Product.products(for: productIds)
            var dict: [String: Product] = [:]
            for product in fetchedProducts {
                dict[product.id] = product
            }
            products = dict
            print("✅ Loaded \(products.count) subscription products")
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("❌ Failed to load subscription products: \(error)")
        }
    }
    
    // MARK: - Purchase Subscription
    func purchaseSubscription(productId: String) async throws {
        guard let product = products[productId] else {
            throw NSError(domain: "Subscription", code: 404, userInfo: [NSLocalizedDescriptionKey: "Product not found"])
        }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await checkSubscriptionStatus()
            print("✅ Subscription purchased successfully")
        case .userCancelled:
            throw CancellationError()
        case .pending:
            throw NSError(domain: "Subscription", code: 102, userInfo: [NSLocalizedDescriptionKey: "Purchase pending approval"])
        @unknown default:
            throw NSError(domain: "Subscription", code: 999, userInfo: [NSLocalizedDescriptionKey: "Unknown purchase result"])
        }
    }
    
    // MARK: - Check Subscription Status
    func checkSubscriptionStatus() async {
        var currentSubscription: SubscriptionTier? = nil
        
        // Check current entitlements for active subscriptions
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Check if this is one of our subscription products
                if transaction.productID == Self.annualProductId {
                    currentSubscription = .annual
                    break // Annual takes precedence
                } else if transaction.productID == Self.monthlyProductId {
                    currentSubscription = .monthly
                }
            } catch {
                print("❌ Failed to verify transaction: \(error)")
            }
        }
        
        activeSubscription = currentSubscription ?? .free
        print("ℹ️ Current subscription tier: \(activeSubscription?.displayName ?? "Free")")
    }
    
    // MARK: - Restore Purchases
    func restorePurchases() async throws {
        try await AppStore.sync()
        await checkSubscriptionStatus()
        
        if activeSubscription != .free {
            print("✅ Purchases restored successfully")
        } else {
            throw NSError(domain: "Subscription", code: 404, userInfo: [NSLocalizedDescriptionKey: "No active subscriptions found"])
        }
    }
    
    // MARK: - Helper Methods
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw NSError(domain: "Subscription", code: 401, userInfo: [NSLocalizedDescriptionKey: "Transaction unverified"])
        case .verified(let safe):
            return safe
        }
    }
    
    func displayPrice(for productId: String, fallback: String) -> String {
        if let product = products[productId] {
            return product.displayPrice
        }
        return fallback
    }
    
    // Calculate monthly price for annual subscription
    func monthlyPriceForAnnual() -> String {
        guard let product = products[Self.annualProductId] else {
            return "£2.49"
        }
        
        let annualPrice = product.price
        let monthlyPrice = annualPrice / 12
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceFormatStyle.locale
        
        return formatter.string(from: monthlyPrice as NSDecimalNumber) ?? "£2.49"
    }
    
    // Calculate savings percentage for annual vs monthly
    func annualSavingsPercentage() -> Int {
        guard let annualProduct = products[Self.annualProductId],
              let monthlyProduct = products[Self.monthlyProductId] else {
            return 38 // Default fallback
        }
        
        let annualPrice = Double(truncating: annualProduct.price as NSDecimalNumber)
        let monthlyPrice = Double(truncating: monthlyProduct.price as NSDecimalNumber)
        let monthlyEquivalent = monthlyPrice * 12
        
        guard monthlyEquivalent > 0 else { return 38 }
        
        let savings = ((monthlyEquivalent - annualPrice) / monthlyEquivalent) * 100
        return Int(savings.rounded())
    }
}

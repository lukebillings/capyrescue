import SwiftUI
import StoreKit

// MARK: - Paywall View
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Binding var selectedTier: SubscriptionManager.SubscriptionTier?
    var hideFreeOption: Bool = false // When true, hides the Free tier option
    var showDismissButton: Bool = false // When true, shows X button to dismiss
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showRestoreSuccess = false
    
    var body: some View {
        ZStack {
            // Animated background matching app style
            AnimatedBackground()
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Dismiss button (when shown via sheet)
                    if showDismissButton {
                        HStack {
                            Spacer()
                            Button(action: {
                                dismiss()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            .padding(.trailing, 8)
                        }
                        .padding(.top, 8)
                    }
                    
                    // Header
                    VStack(spacing: 12) {
                        Image("iconcapybara")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 4
                                    )
                            )
                            .shadow(color: Color(hex: "FFD700").opacity(0.4), radius: 20, x: 0, y: 10)
                        
                        Text("Welcome to")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Capyrescue")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("Choose your plan")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 4)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 8)
                    
                    // Annual Plan (Featured - Most Prominent)
                    SubscriptionCard(
                        tier: .annual,
                        title: "Pro (Annual)",
                        price: subscriptionManager.displayPrice(for: SubscriptionManager.annualProductId, fallback: "£29.99"),
                        priceSubtext: "per year",
                        priceSubtext2: "Effectively \(subscriptionManager.monthlyPriceForAnnual())/month",
                        badge: "BEST VALUE",
                        badgeColor: Color(hex: "FFD700"),
                        features: [
                            "15,000 coins",
                            "10,000 extra coins every month",
                            "No banner ads",
                            "Access exclusive items while subscribed"
                        ],
                        isFeatured: true,
                        savings: "Save \(subscriptionManager.annualSavingsPercentage())% compared with monthly",
                        rimColor: Color(hex: "FFD700"),
                        buttonColor: Color(hex: "FFD700"),
                        isProcessing: isProcessing
                    ) {
                        selectAnnualPlan()
                    }
                    .scaleEffect(1.05) // Make it slightly larger
                    .shadow(color: Color(hex: "FFD700").opacity(0.6), radius: 30, x: 0, y: 15)
                    
                    // Monthly Plan
                    SubscriptionCard(
                        tier: .monthly,
                        title: "Pro (Monthly)",
                        price: subscriptionManager.displayPrice(for: SubscriptionManager.monthlyProductId, fallback: "£3.99"),
                        priceSubtext: "per month",
                        priceSubtext2: nil,
                        badge: nil,
                        badgeColor: nil,
                        features: [
                            "2,000 coins",
                            "2,000 extra coins every month",
                            "No banner ads",
                            "Access exclusive items while subscribed"
                        ],
                        isFeatured: false,
                        savings: nil,
                        rimColor: Color(hex: "C0C0C0"),
                        buttonColor: Color(hex: "A8A8A8"),
                        isProcessing: isProcessing
                    ) {
                        selectMonthlyPlan()
                    }
                    
                    // Free Plan (only show if not hidden)
                    if !hideFreeOption {
                        SubscriptionCard(
                            tier: .free,
                            title: "Free",
                            price: "£0",
                            priceSubtext: "forever",
                            priceSubtext2: nil,
                            badge: nil,
                            badgeColor: nil,
                            features: [
                                "500 coins",
                                "Banner ads shown",
                                "Unlock coins via reward ads and achievements"
                            ],
                            isFeatured: false,
                            savings: nil,
                            rimColor: Color(hex: "CD7F32"),
                            buttonColor: Color(hex: "B8722C"),
                            isProcessing: isProcessing
                        ) {
                            selectFreePlan()
                        }
                    }
                    
                    // Restore Purchases Button
                    Button(action: restorePurchases) {
                        Text("Restore Purchases")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                            .underline()
                    }
                    .disabled(isProcessing)
                    .padding(.top, 8)
                    
                    // Legal text - Apple Compliance
                    VStack(spacing: 10) {
                        // Auto-renewal information
                        Text("Payment will be charged to your iTunes Account at confirmation of purchase. Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period.")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.white.opacity(0.4))
                            .multilineTextAlignment(.center)
                        
                        // Cancellation information
                        Text("Cancel anytime in App Store settings. Your account will be charged for renewal within 24 hours prior to the end of the current period.")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.white.opacity(0.4))
                            .multilineTextAlignment(.center)
                        
                        // Legal links
                        VStack(spacing: 8) {
                            HStack(spacing: 16) {
                                Button(action: { openURL("https://lukebillings.github.io/capyrescue/privacypolicy/") }) {
                                    Text("Privacy Policy")
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundColor(.white.opacity(0.4))
                                        .underline()
                                }
                                
                                Button(action: { openURL("https://lukebillings.github.io/capyrescue/termsandconditions/") }) {
                                    Text("Terms and Conditions")
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundColor(.white.opacity(0.4))
                                        .underline()
                                }
                            }
                            
                            Button(action: { openURL("https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") }) {
                                Text("Terms of Use (EULA)")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(.white.opacity(0.4))
                                    .underline()
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 20)
            }
            
            // Loading overlay
            if isProcessing {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    
                    Text("Processing...")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showRestoreSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your purchases have been restored!")
        }
    }
    
    // MARK: - Actions
    private func selectAnnualPlan() {
        Task {
            isProcessing = true
            defer { isProcessing = false }
            
            do {
                try await subscriptionManager.purchaseSubscription(productId: SubscriptionManager.annualProductId)
                await subscriptionManager.checkSubscriptionStatus()
                selectedTier = .annual
                HapticManager.shared.purchaseSuccess()
            } catch is CancellationError {
                // User cancelled, do nothing
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                HapticManager.shared.purchaseFailed()
            }
        }
    }
    
    private func selectMonthlyPlan() {
        Task {
            isProcessing = true
            defer { isProcessing = false }
            
            do {
                try await subscriptionManager.purchaseSubscription(productId: SubscriptionManager.monthlyProductId)
                await subscriptionManager.checkSubscriptionStatus()
                selectedTier = .monthly
                HapticManager.shared.purchaseSuccess()
            } catch is CancellationError {
                // User cancelled, do nothing
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                HapticManager.shared.purchaseFailed()
            }
        }
    }
    
    private func selectFreePlan() {
        HapticManager.shared.buttonPress()
        selectedTier = .free
    }
    
    private func restorePurchases() {
        Task {
            isProcessing = true
            defer { isProcessing = false }
            
            do {
                try await subscriptionManager.restorePurchases()
                
                if subscriptionManager.activeSubscription != .free {
                    selectedTier = subscriptionManager.activeSubscription
                    showRestoreSuccess = true
                    HapticManager.shared.purchaseSuccess()
                } else {
                    errorMessage = "No active subscriptions found for this Apple ID"
                    showError = true
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                HapticManager.shared.purchaseFailed()
            }
        }
    }
    
    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Subscription Card
struct SubscriptionCard: View {
    let tier: SubscriptionManager.SubscriptionTier
    let title: String
    let price: String
    let priceSubtext: String
    let priceSubtext2: String?
    let badge: String?
    let badgeColor: Color?
    let features: [String]
    let isFeatured: Bool
    let savings: String?
    let rimColor: Color
    let buttonColor: Color
    let isProcessing: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // Badge at top
                if let badge = badge, let badgeColor = badgeColor {
                    HStack {
                        Spacer()
                        Text(badge)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [badgeColor, badgeColor.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                        Spacer()
                    }
                    .offset(y: -12)
                }
                
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: isFeatured ? 28 : 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        VStack(spacing: 4) {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(price)
                                    .font(.system(size: isFeatured ? 40 : 32, weight: .heavy, design: .rounded))
                                    .foregroundStyle(
                                        isFeatured ?
                                        LinearGradient(
                                            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ) :
                                        LinearGradient(
                                            colors: [.white, .white.opacity(0.9)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                
                                Text(priceSubtext)
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            if let priceSubtext2 = priceSubtext2 {
                                Text(priceSubtext2)
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        
                        if let savings = savings {
                            Text(savings)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.green, Color.green.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.green.opacity(0.2))
                                )
                        }
                    }
                    .padding(.top, badge != nil ? 4 : 16)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(features, id: \.self) { feature in
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [rimColor, rimColor.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                Text(feature)
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Spacer()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // CTA Button
                    Text("Get Started")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [buttonColor, buttonColor.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: buttonColor.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(24)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        isFeatured ?
                        Color.white.opacity(0.15) :
                        Color.white.opacity(0.08)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [rimColor.opacity(0.6), rimColor.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isFeatured ? 2 : 1.5
                            )
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isProcessing)
        .opacity(isProcessing ? 0.5 : 1.0)
    }
}

#Preview {
    PaywallView(selectedTier: .constant(nil))
}

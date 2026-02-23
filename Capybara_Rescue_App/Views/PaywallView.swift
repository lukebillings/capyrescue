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
    /// Currently selected plan (one of the 3 options); purchase happens when CTA is tapped.
    @State private var selectedPlan: SubscriptionManager.SubscriptionTier = .annual
    
    var body: some View {
        ZStack {
            // Animated background matching app style
            AnimatedBackground()
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    // Dismiss button (when shown via sheet)
                    if showDismissButton {
                        HStack {
                            Spacer()
                            Button(action: {
                                dismiss()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 26))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            .padding(.trailing, 8)
                        }
                        .padding(.top, 4)
                    }
                    
                    // Header (compact)
                    VStack(spacing: 6) {
                        Image("iconcapybara")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 72, height: 72)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 3
                                    )
                            )
                            .shadow(color: Color(hex: "FFD700").opacity(0.35), radius: 12, x: 0, y: 6)
                        
                        Text("Welcome to")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Capyrescue")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("What plan would you like?")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                    
                    // Three selectable options (radio-style) — tap to select, then use CTA to purchase
                    VStack(spacing: 8) {
                        PaywallPlanRow(
                            tier: .annual,
                            title: "Yearly",
                            subtext: "",
                            subtextHighlight: "7-day free trial",
                            price: subscriptionManager.displayPrice(for: SubscriptionManager.annualProductId, fallback: "£29.99"),
                            priceSubtext: "/ year",
                            priceSubtext2: "Only \(subscriptionManager.monthlyPriceForAnnual())/month",
                            badge: "BEST VALUE",
                            savingsBadge: "Save \(subscriptionManager.annualSavingsPercentage())% vs monthly",
                            features: [
                                "No banner ads",
                                "15,000 coins + 10,000 every month",
                                "Access exclusive items while subscribed"
                            ],
                            isSelected: selectedPlan == .annual,
                            isProcessing: isProcessing
                        ) {
                            HapticManager.shared.buttonPress()
                            selectedPlan = .annual
                        }
                        
                        PaywallPlanRow(
                            tier: .monthly,
                            title: "Monthly",
                            subtext: "",
                            subtextHighlight: nil,
                            price: subscriptionManager.displayPrice(for: SubscriptionManager.monthlyProductId, fallback: "£3.99"),
                            priceSubtext: "/ month",
                            priceSubtext2: nil,
                            badge: nil,
                            savingsBadge: nil,
                            features: [
                                "No banner ads",
                                "2,000 coins + 2,000 every month",
                                "Access exclusive items while subscribed"
                            ],
                            isSelected: selectedPlan == .monthly,
                            isProcessing: isProcessing
                        ) {
                            HapticManager.shared.buttonPress()
                            selectedPlan = .monthly
                        }
                        
                        PaywallPlanRow(
                            tier: .weekly,
                            title: "Weekly",
                            subtext: "",
                            subtextHighlight: nil,
                            price: subscriptionManager.displayPrice(for: SubscriptionManager.weeklyProductId, fallback: "£0.99"),
                            priceSubtext: "/ week",
                            priceSubtext2: nil,
                            badge: nil,
                            savingsBadge: nil,
                            features: [
                                "No banner ads",
                                "1,000 coins + 500 every week",
                                "Access exclusive items while subscribed"
                            ],
                            isSelected: selectedPlan == .weekly,
                            isProcessing: isProcessing
                        ) {
                            HapticManager.shared.buttonPress()
                            selectedPlan = .weekly
                        }
                    }
                    
                    // Single CTA button — "Start Your 7-Day Free Trial" when yearly selected
                    Button(action: purchaseSelectedPlan) {
                        HStack(spacing: 6) {
                            Text(ctaButtonTitle)
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: Color(hex: "FFD700").opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(isProcessing)
                    .opacity(isProcessing ? 0.7 : 1)
                    .padding(.top, 4)
                    
                    // Footer line: trial / cancel copy (clear "after trial" for yearly)
                    Text(footerTrialText)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                    
                    // Restore Purchases Button
                    Button(action: restorePurchases) {
                        Text("Restore Purchases")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                            .underline()
                    }
                    .disabled(isProcessing)
                    .padding(.top, 4)
                    
                    // Legal text - Apple Compliance
                    VStack(spacing: 6) {
                        // Auto-renewal information
                        Text("Payment will be charged to your Apple Account at confirmation of purchase. Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period.")
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
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 18)
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
    
    /// Title for the single CTA button (e.g. "Start Your 7-Day Free Trial" when yearly selected).
    private var ctaButtonTitle: String {
        switch selectedPlan {
        case .annual: return "Start Your 7-Day Free Trial"
        case .monthly: return "Subscribe Monthly"
        case .weekly: return "Subscribe Weekly"
        case .free: return "Start Your 7-Day Free Trial"
        }
    }
    
    /// Footer text below CTA (trial / cancel copy).
    private var footerTrialText: String {
        let annualPrice = subscriptionManager.displayPrice(for: SubscriptionManager.annualProductId, fallback: "£29.99")
        let monthlyPrice = subscriptionManager.displayPrice(for: SubscriptionManager.monthlyProductId, fallback: "£3.99")
        let weeklyPrice = subscriptionManager.displayPrice(for: SubscriptionManager.weeklyProductId, fallback: "£0.99")
        switch selectedPlan {
        case .annual: return "7-day free trial, then \(annualPrice)/year. Billed annually. Cancel anytime."
        case .monthly: return "\(monthlyPrice)/month · Billed monthly · Cancel anytime"
        case .weekly: return "\(weeklyPrice)/week · Billed weekly · Cancel anytime"
        case .free: return "7-day free trial, then \(annualPrice)/year. Billed annually. Cancel anytime."
        }
    }
    
    // MARK: - Actions
    /// Purchases the currently selected plan (single CTA flow).
    private func purchaseSelectedPlan() {
        Task {
            isProcessing = true
            defer { isProcessing = false }
            
            let productId: String
            switch selectedPlan {
            case .annual: productId = SubscriptionManager.annualProductId
            case .monthly: productId = SubscriptionManager.monthlyProductId
            case .weekly: productId = SubscriptionManager.weeklyProductId
            case .free: return
            }
            
            do {
                try await subscriptionManager.purchaseSubscription(productId: productId)
                await subscriptionManager.checkSubscriptionStatus()
                selectedTier = selectedPlan
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

// MARK: - Paywall Plan Row (selectable option: radio + title + subtext + benefits in rectangle, price + badges)
struct PaywallPlanRow: View {
    let tier: SubscriptionManager.SubscriptionTier
    let title: String
    let subtext: String
    var subtextHighlight: String? = nil  // When set (e.g. "7-day free trial"), shown bold + gold below subtext
    let price: String
    let priceSubtext: String
    var priceSubtext2: String? = nil  // Optional line under price (e.g. "Only £2.49/month" for yearly)
    let badge: String?
    let savingsBadge: String?
    let features: [String]
    let isSelected: Bool
    let isProcessing: Bool
    let action: () -> Void
    
    private var accentColor: Color {
        isSelected ? Color(hex: "FFD700") : Color.white.opacity(0.7)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                // Top row: radio + title/subtext left, price + badges right
                HStack(alignment: .top, spacing: 10) {
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: isSelected ? "circle.inset.filled" : "circle")
                            .font(.system(size: 22))
                            .foregroundStyle(isSelected ? Color(hex: "FFD700") : .white.opacity(0.5))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            if !subtext.isEmpty {
                                Text(subtext)
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            if let highlight = subtextHighlight {
                                Text(highlight)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                        }
                        
                        Spacer(minLength: 8)
                    }
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        if let badge = badge, tier == .annual {
                            Text(badge)
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color(hex: "FFD700").opacity(0.9)))
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(price)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text(priceSubtext)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        if let line2 = priceSubtext2 {
                            Text(line2)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        if let savings = savingsBadge, tier == .annual {
                            Text(savings)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: "FFD700"))
                        }
                    }
                }
                
                // Benefits inside the rectangle
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(features, id: \.self) { feature in
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(accentColor)
                            Text(feature)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isSelected ? Color(hex: "FFD700").opacity(0.7) : Color.white.opacity(0.15),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isProcessing)
        .opacity(isProcessing ? 0.6 : 1)
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

import SwiftUI
import StoreKit

// MARK: - Paywall View 2 (Single-option, revenue-maximizing)
/// One offer only: annual with 7-day trial. Clean layout like reference design.
struct PaywallView2: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Binding var selectedTier: SubscriptionManager.SubscriptionTier?
    var showDismissButton: Bool = false
    var onSkip: (() -> Void)? = nil
    /// When set, shows "\(name) is looking forward to seeing you!"; otherwise "Unlock the full experience".
    var capybaraName: String? = nil
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showRestoreSuccess = false

    private var welcomeLine: String {
        if let name = capybaraName, !name.isEmpty {
            return "\(name) is looking forward to seeing you!"
        }
        return "Unlock the full experience"
    }

    var body: some View {
        ZStack {
            AnimatedBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    if showDismissButton {
                        HStack {
                            Spacer()
                            Button(action: {
                                onSkip?()
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

                    // Header
                    VStack(spacing: 10) {
                        Image("iconcapybara")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
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
                            .shadow(color: Color(hex: "FFD700").opacity(0.4), radius: 14, x: 0, y: 6)

                        Text("Welcome to")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))

                        Text("Capyrescue")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Text(welcomeLine)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 12)

                    // Benefits (checkmarks) above button
                    VStack(alignment: .leading, spacing: 10) {
                        Paywall2BenefitRow(text: "No banner ads")
                        Paywall2BenefitRow(text: "15,000 coins + 10,000 every month")
                        Paywall2BenefitRow(text: "Access exclusive items while subscribed")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 8)

                    // Pricing and frequency — above button for Apple compliance (clearly visible before tap)
                    Text(footerTrialText)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 12)

                    // Single CTA — one option only
                    Button(action: purchaseAnnual) {
                        Text("Start Your 7 Day Free Trial")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .shadow(color: Color(hex: "FFD700").opacity(0.5), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(isProcessing)
                    .opacity(isProcessing ? 0.7 : 1)

                    // Restore + legal — pushed down for spacing
                    VStack(spacing: 6) {
                        Button(action: restorePurchases) {
                            Text("Restore Purchases")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))
                                .underline()
                        }
                        .disabled(isProcessing)

                        // Legal — Apple compliance
                        VStack(spacing: 6) {
                            Text("Payment will be charged to your Apple Account at confirmation of purchase. Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period.")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.white.opacity(0.4))
                                .multilineTextAlignment(.center)
                            Text("Cancel anytime in App Store settings. Your account will be charged for renewal within 24 hours prior to the end of the current period.")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.white.opacity(0.4))
                                .multilineTextAlignment(.center)
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
                    }
                    .padding(.top, 48)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
            }

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

    private var footerTrialText: String {
        let annualPrice = subscriptionManager.displayPrice(for: SubscriptionManager.annualProductId, fallback: "£9.99")
        return "7-day free trial, then \(annualPrice)/year. Billed annually. Cancel anytime."
    }

    private func purchaseAnnual() {
        Task {
            isProcessing = true
            defer { isProcessing = false }
            do {
                try await subscriptionManager.purchaseSubscription(productId: SubscriptionManager.annualProductId)
                await subscriptionManager.checkSubscriptionStatus()
                selectedTier = .annual
                HapticManager.shared.purchaseSuccess()
            } catch is CancellationError { }
            catch {
                errorMessage = error.localizedDescription
                showError = true
                HapticManager.shared.purchaseFailed()
            }
        }
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

// MARK: - Benefit row (yellow checkmark + text)
private struct Paywall2BenefitRow: View {
    let text: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color(hex: "FFD700"))
            Text(text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

#Preview {
    PaywallView2(selectedTier: .constant(nil))
}

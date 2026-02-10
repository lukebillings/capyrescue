import SwiftUI

// MARK: - Remove Banner Ad Promotion View
struct RemoveBannerAdPromoView: View {
    @EnvironmentObject var gameManager: GameManager
    @Binding var isPresented: Bool
    @State private var showPaywall: Bool = false
    @State private var selectedTier: SubscriptionManager.SubscriptionTier? = nil
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    HapticManager.shared.buttonPress()
                    isPresented = false
                }
            
            // Popup card
            VStack(spacing: 20) {
                // Icon
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(.top, 8)
                
                // Title
                Text("Enjoying Capybara Rescue Universe?")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                // Description
                Text("Remove ads and get more coins")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                
                // Buttons
                HStack(spacing: 12) {
                    // Cancel button
                    Button(action: {
                        HapticManager.shared.buttonPress()
                        isPresented = false
                    }) {
                        Text("Maybe Later")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.white.opacity(0.1))
                            )
                    }
                    
                    // View Subscriptions button
                    Button(action: {
                        HapticManager.shared.buttonPress()
                        showPaywall = true
                    }) {
                        Text("View Subscriptions")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue, Color.purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .shadow(color: Color.blue.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "1a1a2e").opacity(0.95),
                                Color(hex: "16213e").opacity(0.95)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 32)
            .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(selectedTier: $selectedTier, hideFreeOption: true, showDismissButton: true)
        }
        .onChange(of: selectedTier) { _, newTier in
            if newTier != nil {
                // User selected a tier, close this promo view
                isPresented = false
            }
        }
    }
}

#Preview {
    ZStack {
        AppColors.background
            .ignoresSafeArea()
        
        RemoveBannerAdPromoView(isPresented: .constant(true))
            .environmentObject(GameManager())
    }
}

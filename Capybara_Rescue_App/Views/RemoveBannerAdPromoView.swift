import SwiftUI

// MARK: - Remove Banner Ad Promotion View
struct RemoveBannerAdPromoView: View {
    @EnvironmentObject var gameManager: GameManager
    @Binding var isPresented: Bool
    
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
                Text("Remove banner ads for £3.99")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                
                Text("One-time purchase. No subscriptions.")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
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
                    
                    // Purchase button
                    Button(action: {
                        HapticManager.shared.purchaseSuccess()
                        gameManager.purchaseRemoveBannerAds()
                        isPresented = false
                    }) {
                        Text("Remove Banner Ads")
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

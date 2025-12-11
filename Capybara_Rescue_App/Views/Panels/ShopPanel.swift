import SwiftUI

// MARK: - Shop Panel
struct ShopPanel: View {
    @EnvironmentObject var gameManager: GameManager
    @StateObject private var rewardedAdViewModel = RewardedAdViewModel()
    @StateObject private var trackingManager = TrackingManager.shared
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Hero Balance Card
                BalanceHeroCard(coins: gameManager.gameState.capycoins)
                
                // Free Coins Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.green)
                        
                        Text("Free Coins")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    WatchAdCard(
                        isLoading: rewardedAdViewModel.isLoading || rewardedAdViewModel.isShowingAd,
                        progress: 0,
                        isAdReady: rewardedAdViewModel.isAdReady,
                        showReward: trackingManager.hasRequestedTracking
                    ) {
                        watchAd()
                    }
                    .padding(.horizontal, 16)
                    
                    // Tracking disclaimer
                    Text("Ads may use tracking. Manage in Settings.")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                }
                
                // Coin Packs Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Coin Packs")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(spacing: 8) {
                        ForEach(Array(CoinPack.packs.sorted(by: { $0.coins < $1.coins }).enumerated()), id: \.element.id) { index, pack in
                            CoinPackCard(pack: pack, tier: index) {
                                handleCoinPackPurchase(pack)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Purchase disclaimers
                    VStack(spacing: 6) {
                        Text("Purchases are processed by Apple. Refunds handled via Apple Support.")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                        
                        Text("Coins can be used for purchasing In Game Items, In Game Foods and In Game Drinks. Coins are non-refundable and have no cash value.")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                        
                        Text("Terms of Service  •  Privacy Policy")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                }
                
                Spacer(minLength: 20)
            }
            .padding(.top, 12)
        }
        .onAppear {
            // Update tracking status
            trackingManager.updateTrackingStatus()
            
            // Set up reward handler
            rewardedAdViewModel.onRewardEarned = {
                gameManager.watchAd()
                HapticManager.shared.purchaseSuccess()
            }
        }
    }
    
    private func handleCoinPackPurchase(_ pack: CoinPack) {
        HapticManager.shared.purchaseSuccess()
        gameManager.purchaseCoinPack(pack)
    }
    
    private func watchAd() {
        HapticManager.shared.buttonPress()
        
        // Request tracking authorization if needed before showing ad
        Task {
            await trackingManager.requestTrackingAuthorizationIfNeeded()
            rewardedAdViewModel.showAd()
        }
    }
}

// MARK: - Balance Hero Card
struct BalanceHeroCard: View {
    let coins: Int
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 20) {
            // Coin icon with glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "FFD700").opacity(0.4),
                                Color(hex: "FFD700").opacity(0)
                            ],
                            center: .center,
                            startRadius: 15,
                            endRadius: 50
                        )
                    )
                    .frame(width: 80, height: 80)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                
                CoinIcon(size: 50)
                    .shadow(color: Color(hex: "FFD700").opacity(0.5), radius: 10, y: 5)
            }
            
            // Balance Text
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Balance")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                
                Text(formatCoins(coins))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(hex: "FFD700")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                
                Text("Coins")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: "FFD700").opacity(0.8))
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "2a1f4e"),
                            Color(hex: "1a1530")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: "FFD700").opacity(0.5),
                                    Color(hex: "FFD700").opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: Color(hex: "FFD700").opacity(0.15), radius: 15, y: 8)
        )
        .padding(.horizontal, 16)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
    
    private func formatCoins(_ coins: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: coins)) ?? "\(coins)"
    }
}

// MARK: - Coin Icon
struct CoinIcon: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "FFE55C").opacity(0.6), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .frame(width: size * 0.9, height: size * 0.9)
            
            Text("₵")
                .font(.system(size: size * 0.5, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "8B4513"))
        }
    }
}

// MARK: - Coin Pack Card
struct CoinPackCard: View {
    let pack: CoinPack
    let tier: Int
    let action: () -> Void
    
    private var tierGradient: [Color] {
        switch tier {
        case 0: // Ultra - Purple (no gold)
            return [Color(hex: "9B59B6"), Color(hex: "6C3483")]
        case 1: // Mega - Purple
            return [Color(hex: "9B59B6"), Color(hex: "6C3483")]
        case 2: // Super - Blue
            return [Color(hex: "3498DB"), Color(hex: "2471A3")]
        default: // Starter - Green
            return [Color(hex: "27AE60"), Color(hex: "1E8449")]
        }
    }
    
    // Unified price button gradient for consistent appearance
    private var priceButtonGradient: [Color] {
        return [Color(hex: "4A90E2"), Color(hex: "357ABD")]
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Coin Icon
                CoinIcon(size: 56)
                    .shadow(color: Color(hex: "FFD700").opacity(0.5), radius: 8, y: 4)
                
                // Pack Info
                VStack(alignment: .leading, spacing: 6) {
                    if let badge = pack.badge {
                        HStack(spacing: 8) {
                            Text(badge)
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: tierGradient,
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                        }
                    }
                    
                    HStack(spacing: 4) {
                        CoinIcon(size: 18)
                        Text(formatCoins(pack.coins))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(hex: "FFD700"))
                        Text("coins")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                
                Spacer()
                
                // Price Button
                Text(pack.price)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 80, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: priceButtonGradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: priceButtonGradient[0].opacity(0.4), radius: 6, y: 3)
                    )
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                tierGradient[0].opacity(0.15),
                                tierGradient[1].opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(tierGradient[0].opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private func formatCoins(_ coins: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: coins)) ?? "\(coins)"
    }
}

// MARK: - Watch Ad Card
struct WatchAdCard: View {
    let isLoading: Bool
    let progress: CGFloat
    let isAdReady: Bool
    let showReward: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            if !isLoading && isAdReady {
                action()
            }
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.green.opacity(0.3), Color.green.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    
                    if isLoading {
                        ProgressView()
                            .tint(.green)
                    } else {
                        Image(systemName: isAdReady ? "play.fill" : "hourglass")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(isAdReady ? .green : .white.opacity(0.5))
                    }
                }
                
                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(isLoading ? "Loading Ad..." : (isAdReady ? "Watch Ad" : "Preparing Ad..."))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Watch the 5 second video and receive 10 coins")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
                
                Spacer()
                
                // Reward - always show when ad is ready
                if !isLoading && isAdReady {
                    HStack(spacing: 6) {
                        Text("+10")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.green)
                        CoinIcon(size: 24)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.green.opacity(0.1),
                                Color.green.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.green.opacity(0.25), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isLoading || !isAdReady)
    }
}

#Preview {
    ZStack {
        AppColors.background
            .ignoresSafeArea()
        
        ShopPanel()
            .environmentObject(GameManager())
    }
}

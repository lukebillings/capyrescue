import SwiftUI

// MARK: - Shop Panel
struct ShopPanel: View {
    @EnvironmentObject var gameManager: GameManager
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var isPurchasing: Bool = false
    @State private var showIAPError: Bool = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Hero Balance Card
                BalanceHeroCard(coins: gameManager.gameState.capycoins)
                
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
                        
                        Text(L("panel.coinPacks"))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(spacing: 8) {
                        ForEach(Array(CoinPack.packs.sorted(by: { $0.coins < $1.coins }).enumerated()), id: \.element.id) { index, pack in
                            let priceText = gameManager.displayPrice(forProductId: pack.productId, fallback: pack.price)
                            CoinPackCard(pack: pack, tier: index, priceText: priceText, isPurchasing: isPurchasing) {
                                handleCoinPackPurchase(pack)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Purchase disclaimers
                    VStack(spacing: 8) {
                        Text("Purchases are processed by Apple. Refunds handled via Apple Support.")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(.black.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        Text("Coins can be used for purchasing In Game Items, In Game Foods and In Game Drinks. Coins are non-refundable and have no cash value.")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(.black.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        // Legal links
                        VStack(spacing: 6) {
                            HStack(spacing: 8) {
                                Link(destination: URL(string: "https://lukebillings.github.io/capyrescue/privacypolicy/")!) {
                                    Text("Privacy Policy")
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundStyle(.black)
                                }
                                
                                Text("•")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundStyle(.black)
                                
                                Link(destination: URL(string: "https://lukebillings.github.io/capyrescue/termsandconditions/")!) {
                                    Text("Terms and Conditions")
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundStyle(.black)
                                }
                            }
                            
                                Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                                    Text("Terms of Use (EULA)")
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundStyle(.black)
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                }
                
                Spacer(minLength: 20)
            }
            .padding(.top, 12)
        }
        .alert("Purchase Issue", isPresented: $showIAPError) {
            Button("OK") {
                gameManager.iapLastErrorMessage = nil
            }
        } message: {
            Text(gameManager.iapLastErrorMessage ?? "Unknown error")
        }
        .onChange(of: gameManager.iapLastErrorMessage) { _, newValue in
            showIAPError = (newValue != nil)
        }
    }
    
    private func handleCoinPackPurchase(_ pack: CoinPack) {
        HapticManager.shared.buttonPress()
        Task {
            isPurchasing = true
            let success = await gameManager.purchaseCoinPack(pack)
            isPurchasing = false
            if success {
                HapticManager.shared.purchaseSuccess()
            }
        }
    }
    
}

// MARK: - Balance Hero Card
struct BalanceHeroCard: View {
    let coins: Int
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                CoinIcon(size: 50)
            }
            
            // Balance Text
            VStack(alignment: .leading, spacing: 4) {
                Text(L("panel.shopBalance"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.black.opacity(0.7))
                
                Text(formatCoins(coins))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                
                Text(L("common.coins"))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color(hex: "FFD700").opacity(0.4), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        )
        .padding(.horizontal, 16)
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
    let priceText: String
    let isPurchasing: Bool
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
                            .foregroundStyle(.black)
                        Text("coins")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.black.opacity(0.6))
                    }
                }
                
                Spacer()
                
                // Price Button
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
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
                        )
                } else {
                    Text(priceText)
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
        .disabled(isPurchasing)
    }
    
    private func formatCoins(_ coins: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: coins)) ?? "\(coins)"
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

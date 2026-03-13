import SwiftUI

// MARK: - Shop Panel
struct ShopPanel: View {
    @EnvironmentObject var gameManager: GameManager
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var isPurchasing: Bool = false
    @State private var showIAPError: Bool = false
    @State private var showCatchTheOrangeGame: Bool = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Hero Balance Card
                BalanceHeroCard(coins: gameManager.gameState.capycoins)
                
                // Catch the Orange - daily mini-game card
                CatchTheOrangeCard(
                    canPlayToday: gameManager.canPlayCatchTheOrangeToday(),
                    onPlay: {
                        HapticManager.shared.buttonPress()
                        showCatchTheOrangeGame = true
                    }
                )
                .padding(.top, 24)
                
                // Coin Packs Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color(hex: "1a5f1a"))
                        
                        Text(L("panel.coinPacks"))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "1a1a2e"))
                        
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
        .fullScreenCover(isPresented: $showCatchTheOrangeGame) {
            CatchTheOrangeView(isPresented: $showCatchTheOrangeGame)
                .environmentObject(gameManager)
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

// MARK: - Catch the Orange Card (Get More / Shop)
struct CatchTheOrangeCard: View {
    let canPlayToday: Bool
    let onPlay: () -> Void
    
    private static let cream = Color(hex: "FFF8E7")
    private static let primaryText = Color(hex: "1a1a2e")
    private static let secondaryText = Color(hex: "5A5A5A")
    private static let settingsGreen = Color(hex: "1a5f1a")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text("🍊")
                    .font(.system(size: 28))
                Text(L("orange.title"))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Self.primaryText)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            Text(L("orange.subtitle"))
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Self.secondaryText)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 16)
            
            if canPlayToday {
                Button(action: onPlay) {
                    Text(L("orange.play"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Self.settingsGreen)
                        )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            } else {
                Text(L("orange.comeBackTomorrow"))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Self.secondaryText)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
        }
        .padding(.top, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Self.cream)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Self.settingsGreen.opacity(0.4), lineWidth: 1.5)
                )
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - Balance Hero Card
struct BalanceHeroCard: View {
    let coins: Int
    
    private static let primaryText = Color(hex: "1a1a2e")
    private static let secondaryText = Color(hex: "5A5A5A")
    private static let settingsGreen = Color(hex: "1a5f1a")
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                CoinIcon(size: 50)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(L("panel.shopBalance"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Self.secondaryText)
                
                Text(formatCoins(coins))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Self.primaryText)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                
                Text(L("common.coins"))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Self.secondaryText)
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
                        .stroke(Self.settingsGreen.opacity(0.4), lineWidth: 1.5)
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
                        colors: [Color(hex: "2E7D32"), Color(hex: "1a5f1a")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "4CAF50").opacity(0.5), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .frame(width: size * 0.9, height: size * 0.9)
            
            Text("₵")
                .font(.system(size: size * 0.5, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
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
    
    private static let settingsGreen = Color(hex: "1a5f1a")
    private static let primaryText = Color(hex: "1a1a2e")
    private static let secondaryText = Color(hex: "5A5A5A")
    private static let cream = Color(hex: "FFF8E7")
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                CoinIcon(size: 56)
                    .shadow(color: Self.settingsGreen.opacity(0.3), radius: 8, y: 4)
                
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
                                        .fill(Self.settingsGreen)
                                )
                        }
                    }
                    
                    HStack(spacing: 4) {
                        CoinIcon(size: 18)
                        Text(formatCoins(pack.coins))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(Self.primaryText)
                        Text("coins")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Self.secondaryText)
                    }
                }
                
                Spacer()
                
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                        .frame(width: 80, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Self.settingsGreen)
                        )
                } else {
                    Text(priceText)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Self.settingsGreen)
                                .shadow(color: Self.settingsGreen.opacity(0.35), radius: 6, y: 3)
                        )
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Self.cream)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Self.settingsGreen.opacity(0.25), lineWidth: 1)
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

import SwiftUI

// MARK: - Shop Panel
struct ShopPanel: View {
    @EnvironmentObject var gameManager: GameManager
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var isPurchasing: Bool = false
    @State private var subscriptionProductLoadingId: String? = nil
    @State private var isSubscriptionRestoreLoading: Bool = false
    @State private var showIAPError: Bool = false
    @State private var showCatchTheOrangeGame: Bool = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Hero Balance Card
                BalanceHeroCard(coins: gameManager.gameState.capycoins)
                
                // Coin subscription plans (Pro)
                shopCoinSubscriptionsSection
                    .padding(.top, 8)
                
                // Play Daily Games section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color(hex: "1a5f1a"))
                        
                        Text(L("panel.playDailyGames"))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Color(hex: "1a1a2e"))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(spacing: 8) {
                        CatchTheOrangeCard(
                            coinsPerDay: GameManager.catchTheOrangeCoinsReward,
                            canPlayToday: gameManager.canPlayCatchTheOrangeToday(),
                            onPlay: {
                                HapticManager.shared.buttonPress()
                                showCatchTheOrangeGame = true
                            }
                        )
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.top, 24)
                
                // Coin Packs Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color(hex: "1a5f1a"))
                        
                        Text(L("panel.coinPacks"))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Color(hex: "1a1a2e"))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(spacing: 8) {
                        ForEach(Array(CoinPack.packsSortedMostExpensiveFirst.enumerated()), id: \.element.productId) { index, pack in
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
        .task {
            await subscriptionManager.loadProducts()
        }
    }
    
    // MARK: - Coin subscription plans (Get More)
    
    private static let subscriptionGrantDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        f.locale = .current
        return f
    }()
    
    @ViewBuilder
    private func subscriptionNextCapycoinsCallout(capycoinAmount: Int, scheduledDate: Date?) -> some View {
        let amountStr = formatShopCapycoinNumber(capycoinAmount)
        VStack(alignment: .leading, spacing: 6) {
            Text(L("panel.subscriptionNextCoinsTitle"))
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color(hex: "1a5f1a").opacity(0.9))
            if let when = scheduledDate {
                Text(String(format: L("panel.subscriptionNextCoinsScheduled"), amountStr, Self.subscriptionGrantDateFormatter.string(from: when)))
            } else {
                Text(String(format: L("panel.subscriptionNextCoinsPending"), amountStr))
            }
        }
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(Color(hex: "1a1a2e"))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "1a5f1a").opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "1a5f1a").opacity(0.22), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
    
    private func formatShopCapycoinNumber(_ value: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = .current
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
    private func subscriptionPlanRow(for plan: ShopSubscriptionPlan) -> some View {
        let priceText = subscriptionManager.displayPrice(for: plan.productId, fallback: plan.fallbackPrice)
        let isCurrent = gameManager.currentSubscriptionTier() == plan.tier
        let isThisRowLoading = subscriptionProductLoadingId == plan.productId
        let isAnySubscriptionBusy = subscriptionProductLoadingId != nil || isSubscriptionRestoreLoading
        return ShopSubscriptionPlanRow(
            plan: plan,
            priceText: priceText,
            isCurrent: isCurrent,
            isThisRowLoading: isThisRowLoading,
            isAnySubscriptionBusy: isAnySubscriptionBusy
        ) {
            Task { await purchaseShopSubscription(plan: plan) }
        }
    }
    
    private var shopCoinSubscriptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "crown.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(hex: "1a5f1a"))
                Text(L("panel.coinSubscriptionPlans"))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color(hex: "1a1a2e"))
                Spacer()
            }
            .padding(.horizontal, 20)
            
            Text(L("panel.coinSubscriptionBlurb"))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(hex: "5A5A5A"))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 20)
            
            if let nextGrant = gameManager.nextSubscriptionCoinGrantInfo() {
                subscriptionNextCapycoinsCallout(
                    capycoinAmount: nextGrant.capycoinAmount,
                    scheduledDate: nextGrant.scheduledDate
                )
            }
            
            VStack(spacing: 8) {
                ForEach(ShopSubscriptionPlan.displayOrder) { plan in
                    subscriptionPlanRow(for: plan)
                }
            }
            .padding(.horizontal, 16)
            
            VStack(spacing: 6) {
                Button(action: { Task { await restoreShopSubscriptions() } }) {
                    Text(L("panel.restorePurchases"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "1a5f1a"))
                }
                .buttonStyle(.plain)
                .disabled(subscriptionProductLoadingId != nil || isSubscriptionRestoreLoading)
                
                Text(L("panel.subscriptionBillingNote"))
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(Color(hex: "5A5A5A").opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    @MainActor
    private func purchaseShopSubscription(plan: ShopSubscriptionPlan) async {
        guard subscriptionProductLoadingId == nil, !isSubscriptionRestoreLoading else { return }
        if gameManager.currentSubscriptionTier() == plan.tier { return }
        subscriptionProductLoadingId = plan.productId
        gameManager.iapLastErrorMessage = nil
        defer { subscriptionProductLoadingId = nil }
        do {
            try await subscriptionManager.purchaseSubscription(productId: plan.productId)
            gameManager.upgradeSubscription(to: plan.tier)
            HapticManager.shared.purchaseSuccess()
        } catch is CancellationError {
            return
        } catch {
            gameManager.iapLastErrorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    private func restoreShopSubscriptions() async {
        guard subscriptionProductLoadingId == nil, !isSubscriptionRestoreLoading else { return }
        isSubscriptionRestoreLoading = true
        gameManager.iapLastErrorMessage = nil
        defer { isSubscriptionRestoreLoading = false }
        do {
            try await subscriptionManager.restorePurchases()
            if let sub = subscriptionManager.activeSubscription, sub != .free {
                gameManager.upgradeSubscription(to: sub)
                HapticManager.shared.purchaseSuccess()
            }
        } catch {
            gameManager.iapLastErrorMessage = error.localizedDescription
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
    let coinsPerDay: Int
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
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Self.primaryText)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // Coins per day (standard font, weight, size throughout)
            HStack(spacing: 6) {
                CoinIcon(size: 22)
                Text("\(coinsPerDay) coins per day")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Self.primaryText)
            }
            .padding(.horizontal, 16)
            
            Text(L("orange.subtitle"))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Self.secondaryText)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 16)
            
            if canPlayToday {
                Button(action: onPlay) {
                    Text(L("orange.play"))
                        .font(.system(size: 16, weight: .bold))
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
                    .font(.system(size: 14, weight: .semibold))
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
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Self.primaryText)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                
                Text(L("common.coins"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Self.secondaryText)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(GlassBackground())
        .padding(.horizontal, 16)
    }
    
    private func formatCoins(_ coins: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: coins)) ?? "\(coins)"
    }
}

// MARK: - Coin Icon (gold style)
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
                        colors: [Color(hex: "FFF8DC").opacity(0.6), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .frame(width: size * 0.9, height: size * 0.9)
            
            Text("₵")
                .font(.system(size: size * 0.5, weight: .bold))
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
                                .font(.system(size: 9, weight: .heavy))
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
                        Text(formatCoins(pack.coins))
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Self.primaryText)
                        Text("coins")
                            .font(.system(size: 22, weight: .medium))
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
                        .font(.system(size: 18, weight: .bold))
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

// MARK: - Shop subscription (StoreKit) — product IDs and copy aligned with onboarding coin paywall
private enum ShopSubscriptionPlan: String, CaseIterable, Identifiable {
    case annual, monthly, weekly
    
    var id: String { rawValue }
    
    static let displayOrder: [ShopSubscriptionPlan] = [.annual, .monthly, .weekly]
    
    var tier: SubscriptionManager.SubscriptionTier {
        switch self {
        case .annual: return .annual
        case .monthly: return .monthly
        case .weekly: return .weekly
        }
    }
    
    var productId: String {
        switch self {
        case .annual: return SubscriptionManager.annualProductId
        case .monthly: return SubscriptionManager.monthlyProductId
        case .weekly: return SubscriptionManager.weeklyProductId
        }
    }
    
    var coinsPerPeriod: Int {
        switch self {
        case .weekly: return SubscriptionManager.SubscriptionTier.weekly.weeklyCoins
        case .monthly: return SubscriptionManager.SubscriptionTier.monthly.monthlyCoins
        case .annual: return SubscriptionManager.SubscriptionTier.annual.annualCoins
        }
    }
    
    var fallbackPrice: String {
        switch self {
        case .weekly: return "$0.99"
        case .monthly: return "$9.99"
        case .annual: return "$99.99"
        }
    }
    
    var leftCoinsSubtitleKey: String {
        switch self {
        case .weekly: return "onboarding.coinPaywallLeftCoinsWeek"
        case .monthly: return "onboarding.coinPaywallLeftCoinsMonth"
        case .annual: return "onboarding.coinPaywallLeftCoinsYear"
        }
    }
    
    var listPeriodKey: String {
        switch self {
        case .weekly: return "onboarding.coinPaywallListPeriodWeek"
        case .monthly: return "onboarding.coinPaywallListPeriodMonth"
        case .annual: return "onboarding.coinPaywallListPeriodYear"
        }
    }
}

// MARK: - Shop subscription plan row
private struct ShopSubscriptionPlanRow: View {
    let plan: ShopSubscriptionPlan
    let priceText: String
    let isCurrent: Bool
    let isThisRowLoading: Bool
    let isAnySubscriptionBusy: Bool
    let action: () -> Void
    
    private static let settingsGreen = Color(hex: "1a5f1a")
    private static let primaryText = Color(hex: "1a1a2e")
    private static let secondaryText = Color(hex: "5A5A5A")
    private static let cream = Color(hex: "FFF8E7")
    
    var body: some View {
        Button(action: {
            HapticManager.shared.buttonPress()
            action()
        }) {
            HStack(spacing: 12) {
                CoinIcon(size: 44)
                    .shadow(color: Self.settingsGreen.opacity(0.25), radius: 6, y: 2)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(formattedCoins(plan.coinsPerPeriod))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Self.primaryText)
                        if isCurrent {
                            Text(L("panel.currentPlan"))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Self.settingsGreen))
                        }
                    }
                    Text(L(plan.leftCoinsSubtitleKey))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Self.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer(minLength: 6)
                
                if isThisRowLoading {
                    ProgressView()
                        .tint(Self.settingsGreen)
                        .frame(width: 88, height: 40)
                } else if isCurrent {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Self.settingsGreen)
                        .frame(width: 88, height: 40)
                } else {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(priceText)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Self.primaryText)
                        Text(L(plan.listPeriodKey))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Self.secondaryText)
                    }
                    .frame(minWidth: 80, alignment: .trailing)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Self.cream)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isCurrent ? Self.settingsGreen.opacity(0.45) : Self.settingsGreen.opacity(0.25), lineWidth: isCurrent ? 2 : 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isCurrent || isAnySubscriptionBusy)
        .opacity(isAnySubscriptionBusy && !isThisRowLoading ? 0.55 : 1.0)
    }
    
    private func formattedCoins(_ value: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale.current
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
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

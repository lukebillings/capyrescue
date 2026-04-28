import SwiftUI
import UserNotifications
import Combine

// MARK: - Onboarding View
struct OnboardingView: View {
    @EnvironmentObject var gameManager: GameManager
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Binding var isPresented: Bool
    
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var currentStep: OnboardingStep = .language
    @State private var capybaraName: String = ""
    @State private var selectedCoinPlan: CoinPaywallPlan = .annual
    @State private var isPurchasing: Bool = false
    @State private var paywallErrorMessage: String? = nil
    /// Auto-rotating hat preview on the coin paywall (`paywallShowcaseHats`).
    @State private var paywallShowcaseHatIndex: Int = 0
    /// Anchor for hat rotation so it stays in sync with wall clock while the dismiss countdown runs (avoids a second Combine timer that resets on every 1s state update).
    @State private var paywallShowcaseStartedAt: Date = Date()
    /// Counts down from 20; at 0 the top-trailing control becomes an exit button.
    @State private var paywallDismissSecondsRemaining: Int = 20
    @State private var coinPackDismissSecondsRemaining: Int = 20
    @State private var selectedCoinPackProductId: String = ""
    @State private var isPurchasingCoinPack: Bool = false
    @State private var adoptionGiftShowConfetti = false
    @State private var adoptionGiftCoinReveal = false
    @State private var adoptionGiftSparkleRotation: Double = 0
    
    enum OnboardingStep {
        case language
        case welcome
        case notifications
        case pledge
        case adoptionGift
        case coinPaywall
        case coinPackOnboarding
    }
    
    /// Pro coin subscription options (maps to `SubscriptionManager` product IDs and recurring grant amounts).
    private enum CoinPaywallPlan: String, CaseIterable, Identifiable {
        case weekly, monthly, annual
        var id: String { rawValue }
        /// Shown on the marketing paywall: annual (trial) first, weekly second.
        static let displayOrder: [CoinPaywallPlan] = [.annual, .weekly]
        var productId: String {
            switch self {
            case .weekly: return SubscriptionManager.weeklyProductId
            case .monthly: return SubscriptionManager.monthlyProductId
            case .annual: return SubscriptionManager.annualProductId
            }
        }
        var tier: SubscriptionManager.SubscriptionTier {
            switch self {
            case .weekly: return .weekly
            case .monthly: return .monthly
            case .annual: return .annual
            }
        }
        /// Shown in the list (recurring amount for that cadence).
        var coinsPerPeriod: Int {
            switch self {
            case .weekly: return SubscriptionManager.SubscriptionTier.weekly.weeklyCoins
            case .monthly: return SubscriptionManager.SubscriptionTier.monthly.monthlyCoins
            case .annual: return SubscriptionManager.SubscriptionTier.annual.annualCoins
            }
        }
        /// Unused placeholders (shop/onboarding use StoreKit `displayPrice` when available).
        var hardcodedPaywallPrice: String {
            switch self {
            case .weekly: return "$0.99"
            case .monthly: return "$9.99"
            case .annual: return "$99.99"
            }
        }
        /// For the main CTA: "Give me X coins per [freq]."
        var ctaFrequencyKey: String {
            switch self {
            case .weekly: return "onboarding.coinPaywallFrequencyWeek"
            case .monthly: return "onboarding.coinPaywallFrequencyMonth"
            case .annual: return "onboarding.coinPaywallFrequencyYear"
            }
        }
        /// Shorter subtitle under the coin amount in each row.
        var listPeriodKey: String {
            switch self {
            case .weekly: return "onboarding.coinPaywallListPeriodWeek"
            case .monthly: return "onboarding.coinPaywallListPeriodMonth"
            case .annual: return "onboarding.coinPaywallListPeriodYear"
            }
        }
        /// Under the big number: "coins per week" (no repeat of the amount).
        var leftCoinsOnlySubtitleKey: String {
            switch self {
            case .weekly: return "onboarding.coinPaywallLeftCoinsWeek"
            case .monthly: return "onboarding.coinPaywallLeftCoinsMonth"
            case .annual: return "onboarding.coinPaywallLeftCoinsYear"
            }
        }
    }
    
    /// Onboarding uses light color scheme (cream background) like the homepage for consistency and legibility.
    private static let onboardingBackground = Color(hex: "FFF8E7")
    private static let onboardingPrimaryText = Color(hex: "1a1a2e")
    private static let onboardingSecondaryText = Color(hex: "5A5A5A")
    private static let onboardingCardFill = Color.white.opacity(0.85)
    private static let onboardingCardStroke = Color(hex: "1a1a2e").opacity(0.12)
    
    /// Same top inset and capybara height on every onboarding step so capybara and CTA stay in exact same position.
    private static let onboardingTopInset: CGFloat = 20
    /// One style for language + both onboarding paywall headlines (same size, weight, and vertical position).
    private static let onboardingScreenTitleSize: CGFloat = 24
    private static let onboardingCapybaraHeight: CGFloat = 180
    private static let onboardingCTAHorizontalPadding: CGFloat = 24
    private static let onboardingCTABottomPadding: CGFloat = 40
    private static let paywallHatCycleSeconds: TimeInterval = 2.4
    private static let paywallDismissCountdownSeconds: Int = 20
    private static let paywallHeroCapybaraHeight: CGFloat = 118
    private static let paywallHeroCapybaraScale: CGFloat = 0.30
    /// Subscription paywall: slightly taller hero than coin-pack paywall so tall hat previews aren’t clipped; capybara uses center scale like paywall 2.
    private static let paywallSubscriptionHeroHeight: CGFloat = 136
    private static let paywallHatStripHeight: CGFloat = 48
    private static let paywallPlanRowVPadding: CGFloat = 9
    private static let paywallPlanCardCornerRadius: CGFloat = 14
    private static let paywallPlanCoinFontSize: CGFloat = 21
    private static let paywallBottomSectionSpacing: CGFloat = 8
    /// Restore, disclaimer body, Privacy/Terms — same as `LegalFinePrintTypography` in ShopPanel.swift.
    private static let paywallLegalCopySize: CGFloat = 10
    /// Pushes footer + CTA identically above the bottom on subscription vs coin-pack paywall (`Spacer` before legal block).
    private static let paywallPreCTAFooterSpacerMinLength: CGFloat = 12
    /// Shown only while StoreKit hasn’t returned `Product.displayPrice` yet.
    private static let coinPaywallPriceLoadingPlaceholder = "…"
    private static let paywallLegalPrivacyURL = URL(string: "https://lukebillings.github.io/capyrescue/privacypolicy/")!
    private static let paywallLegalTermsURL = URL(string: "https://lukebillings.github.io/capyrescue/termsandconditions/")!
    private static let paywallLegalEULAURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    
    private static let paywallFirstHatId = "sombrerohat"
    
    /// Hats on the coin paywall: sombrero first, then pricier hats in ascending order, then cheaper hats (baseball cap → …) ascending.
    private var paywallShowcaseHats: [AccessoryItem] {
        let owned = gameManager.gameState.ownedAccessories
        let base = AccessoryItem.allItems.filter { item in
            guard item.isHat, item.modelFileName != nil else { return false }
            if item.id == "redlantern" {
                return Date.shouldShowCNYItems2026() || owned.contains(item.id)
            }
            return true
        }
        let byPrice = base.sorted { $0.cost < $1.cost }
        guard let i = byPrice.firstIndex(where: { $0.id == Self.paywallFirstHatId }) else {
            return byPrice
        }
        let sombrero = byPrice[i]
        let pricier = byPrice[(i + 1)...]
        let cheaper = byPrice[..<i]
        return [sombrero] + Array(pricier) + Array(cheaper)
    }
    
    private var paywallPreviewHatId: String? {
        paywallPreviewedAccessory?.id
    }
    
    /// The hat currently highlighted in the strip / on the 3D model.
    private var paywallPreviewedAccessory: AccessoryItem? {
        let hats = paywallShowcaseHats
        guard !hats.isEmpty else { return nil }
        return hats[paywallShowcaseHatIndex % hats.count]
    }
    
    /// Name + coin price for the cycling hat preview (paywall 1 & 2).
    @ViewBuilder
    private var paywallShowcaseCyclingItemCaption: some View {
        if let item = paywallPreviewedAccessory {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(localizedAccessoryName(id: item.id))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Self.onboardingPrimaryText)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(formattedCoinCount(item.cost))
                        .font(.system(size: 14, weight: .medium))
                    Text(L("common.coins"))
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(Self.onboardingPrimaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
        }
    }
    
    /// Drives the hat strip / 3D preview from elapsed time so rotation keeps going during the 20s dismiss countdown.
    private func updatePaywallShowcaseHatIndexFromElapsedTime() {
        let n = paywallShowcaseHats.count
        guard n > 0 else { return }
        let elapsed = max(0, Date().timeIntervalSince(paywallShowcaseStartedAt))
        let newIndex = Int(floor(elapsed / Self.paywallHatCycleSeconds)) % n
        if newIndex != paywallShowcaseHatIndex {
            paywallShowcaseHatIndex = newIndex
        }
    }
    
    var body: some View {
        ZStack {
            Self.onboardingBackground
                .ignoresSafeArea()
            
            switch currentStep {
            case .language:
                languageView
            case .welcome:
                welcomeView
            case .notifications:
                notificationsView
            case .pledge:
                pledgeView
            case .adoptionGift:
                adoptionGiftView
            case .coinPaywall:
                coinPaywallView
            case .coinPackOnboarding:
                coinPackOnboardingView
            }
        }
        .preferredColorScheme(.light)
        .alert(L("onboarding.coinPaywallErrorTitle"), isPresented: .init(
            get: { paywallErrorMessage != nil },
            set: { if !$0 { paywallErrorMessage = nil } }
        )) {
            Button(L("common.ok"), role: .cancel) { paywallErrorMessage = nil }
        } message: {
            Text(paywallErrorMessage ?? "")
        }
    }
    
    // MARK: - Language View
    private var languageView: some View {
        VStack(spacing: 12) {
            Spacer()
                .frame(height: Self.onboardingTopInset)
            
            Text(L("onboarding.languageTitle"))
                .font(.system(size: Self.onboardingScreenTitleSize, weight: .bold))
                .foregroundStyle(Self.onboardingPrimaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Text(L("onboarding.languageSubtitle"))
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Self.onboardingSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Image(systemName: "globe")
                .font(.system(size: 44))
                .foregroundStyle(AppColors.paywallCTAGreen)
            
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(LocalizationManager.supportedLanguages, id: \.code) { lang in
                    Button(action: {
                        localizationManager.currentLanguage = lang.code
                    }) {
                        HStack(spacing: 6) {
                            Text(lang.displayName)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Self.onboardingPrimaryText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Spacer(minLength: 0)
                            if localizationManager.currentLanguage == lang.code {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(AppColors.paywallCTAGreen)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Self.onboardingCardFill)
                                .overlay(
                                    Capsule()
                                        .stroke(Self.onboardingCardStroke, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    currentStep = .welcome
                }
            }) {
                Text(L("onboarding.continue"))
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        Capsule()
                            .fill(AppColors.paywallCTAGreen)
                    )
            }
            .padding(.horizontal, Self.onboardingCTAHorizontalPadding)
            .padding(.bottom, Self.onboardingCTABottomPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Welcome / Name View
    private var welcomeView: some View {
        VStack(spacing: 12) {
            Spacer()
                .frame(height: Self.onboardingTopInset)
            
            Text(L("onboarding.welcomeTitle"))
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Self.onboardingPrimaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Text(L("onboarding.welcomeSubtitle"))
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Self.onboardingSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if #available(iOS 17.0, *) {
                Capybara3DView(
                    emotion: gameManager.gameState.capybaraEmotion,
                    equippedAccessories: gameManager.gameState.equippedAccessories,
                    previewingAccessoryId: nil,
                    onPet: { },
                    initialRotation: nil
                )
                .frame(height: Self.onboardingCapybaraHeight)
                .scaleEffect(0.38)
                .frame(height: Self.onboardingCapybaraHeight)
                .clipped()
                .allowsHitTesting(false)
            } else {
                Text("🐹")
                    .font(.system(size: 80))
                    .frame(height: Self.onboardingCapybaraHeight)
            }
            
            TextField(L("onboarding.namePlaceholder"), text: $capybaraName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Self.onboardingPrimaryText)
                .tint(AppColors.paywallCTAGreen)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(Self.onboardingCardFill)
                        .overlay(
                            Capsule()
                                .stroke(Self.onboardingCardStroke, lineWidth: 1)
                        )
                )
                .padding(.horizontal, 32)
            
            Spacer()
            
            Button(action: {
                let trimmed = capybaraName.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                gameManager.renameCapybara(to: trimmed)
                withAnimation {
                    currentStep = .notifications
                }
            }) {
                Text(L("onboarding.continue"))
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        Capsule()
                            .fill(AppColors.paywallCTAGreen)
                    )
            }
            .disabled(capybaraName.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(capybaraName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
            .padding(.horizontal, Self.onboardingCTAHorizontalPadding)
            .padding(.bottom, Self.onboardingCTABottomPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Notifications View
    private var notificationsView: some View {
        VStack(spacing: 12) {
            Spacer()
                .frame(height: Self.onboardingTopInset)
            
            Text(L("onboarding.notificationsTitle"))
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Self.onboardingPrimaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Text(L("onboarding.notificationsSubtitle"))
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Self.onboardingSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if #available(iOS 17.0, *) {
                Capybara3DView(
                    emotion: gameManager.gameState.capybaraEmotion,
                    equippedAccessories: gameManager.gameState.equippedAccessories,
                    previewingAccessoryId: nil,
                    onPet: { },
                    initialRotation: nil
                )
                .frame(height: Self.onboardingCapybaraHeight)
                .scaleEffect(0.38)
                .frame(height: Self.onboardingCapybaraHeight)
                .clipped()
            } else {
                Text("🐹")
                    .font(.system(size: 80))
                    .frame(height: Self.onboardingCapybaraHeight)
            }
            
            Spacer()
                .frame(minHeight: 8)
            
            Image(systemName: "bell.fill")
                .font(.system(size: 88))
                .foregroundStyle(AppColors.paywallCTAGreen)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    currentStep = .pledge
                }
            }) {
                Text(L("onboarding.skip"))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Self.onboardingSecondaryText)
            }
            
            Button(action: {
                requestNotificationPermission()
            }) {
                Text(L("onboarding.enableNotifications"))
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        Capsule()
                            .fill(AppColors.paywallCTAGreen)
                    )
            }
            .padding(.horizontal, Self.onboardingCTAHorizontalPadding)
            .padding(.bottom, Self.onboardingCTABottomPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Pledge View
    private var pledgeView: some View {
        VStack(spacing: 12) {
            Spacer()
                .frame(height: Self.onboardingTopInset)
            
            Text(L("onboarding.pledgeTitle"))
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Self.onboardingPrimaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if #available(iOS 17.0, *) {
                Capybara3DView(
                    emotion: gameManager.gameState.capybaraEmotion,
                    equippedAccessories: gameManager.gameState.equippedAccessories,
                    previewingAccessoryId: nil,
                    onPet: { },
                    initialRotation: nil
                )
                .frame(height: Self.onboardingCapybaraHeight)
                .scaleEffect(0.38)
                .frame(height: Self.onboardingCapybaraHeight)
                .clipped()
            } else {
                Text("🐹")
                    .font(.system(size: 80))
                    .frame(height: Self.onboardingCapybaraHeight)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.paywallCTAGreen)
                    Text(L("onboarding.pledgeFeed"))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Self.onboardingPrimaryText)
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.paywallCTAGreen)
                    Text(L("onboarding.pledgeDrinks"))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Self.onboardingPrimaryText)
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.paywallCTAGreen)
                    Text(L("onboarding.pledgeHappy"))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Self.onboardingPrimaryText)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
                .frame(minHeight: 24)
            
            Text("📜")
                .font(.system(size: 88))
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    currentStep = .adoptionGift
                }
            }) {
                Text(L("onboarding.acceptAndGo"))
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        Capsule()
                            .fill(AppColors.paywallCTAGreen)
                    )
            }
            .padding(.horizontal, Self.onboardingCTAHorizontalPadding)
            .padding(.bottom, Self.onboardingCTABottomPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Adoption gift (starter coins)
    private var adoptionGiftView: some View {
        ZStack {
            VStack(spacing: 12) {
                Spacer()
                    .frame(height: Self.onboardingTopInset)
                Text(L("onboarding.adoptionGiftTitle"))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Self.onboardingPrimaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                Text(String(format: L("onboarding.adoptionGiftSubtitle"), formattedCoinCount(GameManager.onboardingAdoptionGiftCoins)))
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Self.onboardingSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                Group {
                    if #available(iOS 17.0, *) {
                        Capybara3DView(
                            emotion: gameManager.gameState.capybaraEmotion,
                            equippedAccessories: gameManager.gameState.equippedAccessories,
                            previewingAccessoryId: nil,
                            onPet: { },
                            initialRotation: nil
                        )
                        .frame(height: Self.onboardingCapybaraHeight)
                        .scaleEffect(0.38)
                        .frame(height: Self.onboardingCapybaraHeight)
                        .clipped()
                        .allowsHitTesting(false)
                    } else {
                        Text("🐹")
                            .font(.system(size: 80))
                            .frame(height: Self.onboardingCapybaraHeight)
                    }
                }
                .padding(.top, 8)
                VStack(spacing: 6) {
                    ZStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 32))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .rotationEffect(.degrees(adoptionGiftSparkleRotation))
                            .opacity(adoptionGiftCoinReveal ? 1 : 0)
                        CoinIcon(size: 50)
                            .scaleEffect(adoptionGiftCoinReveal ? 1 : 0.15)
                            .opacity(adoptionGiftCoinReveal ? 1 : 0)
                    }
                    Text("+\(formattedCoinCount(GameManager.onboardingAdoptionGiftCoins))")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "B8860B"), Color(hex: "FFD700")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .scaleEffect(adoptionGiftCoinReveal ? 1 : 0.3)
                        .opacity(adoptionGiftCoinReveal ? 1 : 0)
                }
                .padding(.top, 10)
                Spacer()
                Button(action: {
                    withAnimation {
                        currentStep = .coinPaywall
                    }
                }) {
                    Text(L("onboarding.continue"))
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            Capsule()
                                .fill(AppColors.paywallCTAGreen)
                        )
                }
                .padding(.horizontal, Self.onboardingCTAHorizontalPadding)
                .padding(.bottom, Self.onboardingCTABottomPadding)
            }
            ConfettiView(isActive: adoptionGiftShowConfetti) {
                adoptionGiftShowConfetti = false
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            gameManager.grantOnboardingAdoptionCoinsIfNeeded()
            adoptionGiftCoinReveal = false
            adoptionGiftShowConfetti = true
            adoptionGiftSparkleRotation = 0
            withAnimation(.spring(response: 0.52, dampingFraction: 0.68)) {
                adoptionGiftCoinReveal = true
            }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                adoptionGiftSparkleRotation = 25
            }
            HapticManager.shared.purchaseSuccess()
        }
    }
    
    private var paywallCoinBalanceHeader: some View {
        VStack(spacing: 6) {
            Text(L("onboarding.coinPaywallBalanceCaption"))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Self.onboardingSecondaryText)
            HStack(spacing: 10) {
                CoinIcon(size: 30)
                Text(formattedCoinCount(gameManager.gameState.capycoins))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Self.onboardingPrimaryText)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
    
    // MARK: - Coin Paywall (post-pledge)
    /// Same cream background and bottom green CTA as earlier onboarding steps; selectable plans use green rim.
    private var coinPaywallView: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: Self.onboardingTopInset)
                VStack(spacing: 6) {
                    Text(L("onboarding.coinPaywallTitleLine1"))
                        .font(.system(size: Self.onboardingScreenTitleSize, weight: .bold))
                        .foregroundStyle(Self.onboardingPrimaryText)
                    Text(L("onboarding.coinPaywallTitleLine2"))
                        .font(.system(size: Self.onboardingScreenTitleSize, weight: .bold))
                        .foregroundStyle(Self.onboardingPrimaryText)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.82)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                paywallCoinBalanceHeader
                VStack(spacing: 6) {
                    paywallHatShowcaseStrip
                    paywallShowcaseCyclingItemCaption
                    if #available(iOS 17.0, *) {
                        Capybara3DView(
                            emotion: gameManager.gameState.capybaraEmotion,
                            equippedAccessories: gameManager.gameState.equippedAccessories,
                            previewingAccessoryId: paywallPreviewHatId,
                            onPet: { },
                            initialRotation: nil
                        )
                        .frame(height: Self.paywallSubscriptionHeroHeight)
                        .scaleEffect(Self.paywallHeroCapybaraScale)
                        .frame(height: Self.paywallSubscriptionHeroHeight)
                        .offset(y: -14)
                        .clipped()
                        .allowsHitTesting(false)
                    } else {
                        Text(paywallShowcaseHats.isEmpty ? "🐹" : (paywallShowcaseHats[paywallShowcaseHatIndex % paywallShowcaseHats.count].emoji))
                            .font(.system(size: 64))
                            .frame(height: Self.paywallSubscriptionHeroHeight, alignment: .bottom)
                    }
                }
                .padding(.top, 10)
                VStack(spacing: 10) {
                    ForEach(CoinPaywallPlan.displayOrder) { plan in
                        coinPaywallPlanCard(plan: plan)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                Spacer(minLength: 12)
                VStack(spacing: Self.paywallBottomSectionSpacing) {
                    coinPaywallPreCTALegalBlock
                    Button(action: { Task { await purchaseSelectedPlan() } }) {
                        Group {
                            if isPurchasing {
                                Text(L("onboarding.coinPaywallPurchasing"))
                            } else {
                                Text(ctaLabelForSelectedPlan())
                            }
                        }
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            ZStack {
                                Capsule()
                                    .fill(AppColors.paywallCTAGreen)
                                CoinPaywallCTADiagonalShine()
                                    .clipShape(Capsule())
                            }
                        )
                    }
                    .disabled(isPurchasing)
                    .opacity(isPurchasing ? 0.7 : 1.0)
                }
                .padding(.horizontal, Self.onboardingCTAHorizontalPadding)
                .padding(.bottom, Self.onboardingCTABottomPadding)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            paywallTopTrailingDismissControl
                .padding(.trailing, 16)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            paywallShowcaseStartedAt = Date()
            paywallShowcaseHatIndex = 0
            paywallDismissSecondsRemaining = Self.paywallDismissCountdownSeconds
            updatePaywallShowcaseHatIndexFromElapsedTime()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if paywallDismissSecondsRemaining > 0 {
                paywallDismissSecondsRemaining -= 1
            }
            updatePaywallShowcaseHatIndexFromElapsedTime()
        }
        .task {
            await subscriptionManager.loadProducts()
        }
    }
    
    private func coinPaywallPlanCard(plan: CoinPaywallPlan) -> some View {
        let selected = selectedCoinPlan == plan
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCoinPlan = plan
            }
        } label: {
            if plan == .annual {
                HStack(alignment: .center, spacing: 12) {
                    Text(L("onboarding.coinPaywallAnnualTitle"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Self.onboardingPrimaryText)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                    Spacer(minLength: 8)
                    Text(annualPaywallRenewSubtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Self.onboardingSecondaryText)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .contentShape(Rectangle())
            } else {
                HStack(alignment: .firstTextBaseline) {
                    Text(L("onboarding.coinPaywallWeeklyLabelLeft"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Self.onboardingPrimaryText)
                    Spacer(minLength: 8)
                    Text(weeklyPaywallPriceLine)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Self.onboardingSecondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, Self.paywallPlanRowVPadding)
        .background(
            RoundedRectangle(cornerRadius: Self.paywallPlanCardCornerRadius, style: .continuous)
                .fill(Self.onboardingCardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: Self.paywallPlanCardCornerRadius, style: .continuous)
                        .stroke(
                            selected ? AppColors.paywallCTAGreen : Self.onboardingCardStroke,
                            lineWidth: selected ? 2 : 1
                        )
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: Self.paywallPlanCardCornerRadius, style: .continuous))
    }
    
    private var annualPaywallRenewSubtitle: String {
        let price = subscriptionManager.displayPrice(
            for: CoinPaywallPlan.annual.productId,
            fallback: Self.coinPaywallPriceLoadingPlaceholder
        )
        return String(format: L("onboarding.coinPaywallAnnualRenewFormat"), price)
    }
    
    private var weeklyPaywallPriceLine: String {
        let price = subscriptionManager.displayPrice(
            for: CoinPaywallPlan.weekly.productId,
            fallback: Self.coinPaywallPriceLoadingPlaceholder
        )
        return String(format: L("onboarding.coinPaywallWeeklyRightFormat"), price)
    }
    
    // MARK: - Coin pack onboarding (after subscription paywall)
    private var coinPackOnboardingView: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: Self.onboardingTopInset)
                Text(L("onboarding.coinPackOfferTitle"))
                    .font(.system(size: Self.onboardingScreenTitleSize, weight: .bold))
                    .foregroundStyle(Self.onboardingPrimaryText)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.78)
                    .lineLimit(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)
                paywallCoinBalanceHeader
                VStack(spacing: 5) {
                    paywallHatShowcaseStrip
                    paywallShowcaseCyclingItemCaption
                    if #available(iOS 17.0, *) {
                        Capybara3DView(
                            emotion: gameManager.gameState.capybaraEmotion,
                            equippedAccessories: gameManager.gameState.equippedAccessories,
                            previewingAccessoryId: paywallPreviewHatId,
                            onPet: { },
                            initialRotation: nil
                        )
                        .frame(height: Self.paywallHeroCapybaraHeight)
                        .scaleEffect(Self.paywallHeroCapybaraScale)
                        .frame(height: Self.paywallHeroCapybaraHeight)
                        .clipped()
                        .allowsHitTesting(false)
                    } else {
                        Text(paywallShowcaseHats.isEmpty ? "🐹" : (paywallShowcaseHats[paywallShowcaseHatIndex % paywallShowcaseHats.count].emoji))
                            .font(.system(size: 64))
                            .frame(height: Self.paywallHeroCapybaraHeight)
                    }
                    VStack(spacing: 5) {
                        ForEach(CoinPack.topThreeCoinPacksForOnboarding, id: \.productId) { pack in
                            coinPackOnboardingOptionButton(pack: pack)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.top, 5)
                Spacer(minLength: Self.paywallPreCTAFooterSpacerMinLength)
                VStack(spacing: Self.paywallBottomSectionSpacing) {
                    coinPackOfferPreCTALegalBlock
                    Button(action: { Task { await purchaseSelectedCoinPack() } }) {
                        Group {
                            if isPurchasingCoinPack {
                                Text(L("onboarding.coinPackOfferPurchasing"))
                            } else {
                                Text(String(format: L("onboarding.coinPackOfferCTAFormat"), formattedCoinCount(selectedOnboardingCoinPack.grantCoins)))
                            }
                        }
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            ZStack {
                                Capsule()
                                    .fill(AppColors.paywallCTAGreen)
                                CoinPaywallCTADiagonalShine()
                                    .clipShape(Capsule())
                            }
                        )
                    }
                    .disabled(isPurchasingCoinPack)
                    .opacity(isPurchasingCoinPack ? 0.7 : 1.0)
                }
                .padding(.horizontal, Self.onboardingCTAHorizontalPadding)
                .padding(.bottom, Self.onboardingCTABottomPadding)
            }
            coinPackTopTrailingDismissControl
                .padding(.trailing, 16)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if selectedCoinPackProductId.isEmpty
                || CoinPack.topThreeCoinPacksForOnboarding.allSatisfy({ $0.productId != selectedCoinPackProductId }) {
                selectedCoinPackProductId = CoinPack.topThreeCoinPacksForOnboarding.first?.productId ?? ""
            }
            paywallShowcaseStartedAt = Date()
            paywallShowcaseHatIndex = 0
            coinPackDismissSecondsRemaining = Self.paywallDismissCountdownSeconds
            updatePaywallShowcaseHatIndexFromElapsedTime()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if coinPackDismissSecondsRemaining > 0 {
                coinPackDismissSecondsRemaining -= 1
            }
            updatePaywallShowcaseHatIndexFromElapsedTime()
        }
        .task {
            await gameManager.refreshIAPProducts()
        }
    }
    
    private var selectedOnboardingCoinPack: CoinPack {
        if let match = CoinPack.topThreeCoinPacksForOnboarding.first(where: { $0.productId == selectedCoinPackProductId }) {
            return match
        }
        return CoinPack.topThreeCoinPacksForOnboarding.first
            ?? CoinPack.packsSortedMostExpensiveFirst.first
            ?? CoinPack.packs[0]
    }
    
    private var coinPackTopTrailingDismissControl: some View {
        Group {
            if coinPackDismissSecondsRemaining > 0 {
                Text("\(coinPackDismissSecondsRemaining)")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(Self.onboardingPrimaryText)
                    .monospacedDigit()
                    .frame(minWidth: 40, minHeight: 40, alignment: .center)
                    .accessibilityLabel(Text(verbatim: "\(coinPackDismissSecondsRemaining)"))
            } else {
                Button(action: { completeOnboardingAndDismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Self.onboardingPrimaryText)
                        .frame(minWidth: 40, minHeight: 40)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: L("common.dismiss")))
            }
        }
    }
    
    private var coinPackOfferPreCTALegalBlock: some View {
        paywallLegalFooter(restoreDisabled: isPurchasingCoinPack) {
            Text(L("onboarding.coinPackOfferFinePrint"))
                .font(.system(size: Self.paywallLegalCopySize, weight: .regular))
                .foregroundStyle(Self.onboardingSecondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func coinPackOnboardingOptionButton(pack: CoinPack) -> some View {
        let selected = selectedCoinPackProductId == pack.productId
        let price = gameManager.displayPrice(forProductId: pack.productId, fallback: pack.price)
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCoinPackProductId = pack.productId
            }
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(formattedCoinCount(pack.grantCoins))
                            .font(.system(size: Self.paywallPlanCoinFontSize, weight: .bold))
                            .foregroundStyle(Self.onboardingPrimaryText)
                        Text(L("common.coins"))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Self.onboardingPrimaryText)
                    }
                    Text(L("onboarding.coinPackOfferRowSubtitle"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Self.onboardingSecondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Text(price)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Self.onboardingSecondaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, Self.paywallPlanRowVPadding)
            .background(
                RoundedRectangle(cornerRadius: Self.paywallPlanCardCornerRadius, style: .continuous)
                    .fill(Self.onboardingCardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: Self.paywallPlanCardCornerRadius, style: .continuous)
                            .stroke(selected ? AppColors.paywallCTAGreen : Self.onboardingCardStroke, lineWidth: selected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var paywallTopTrailingDismissControl: some View {
        Group {
            if paywallDismissSecondsRemaining > 0 {
                Text("\(paywallDismissSecondsRemaining)")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(Self.onboardingPrimaryText)
                    .monospacedDigit()
                    .frame(minWidth: 40, minHeight: 40, alignment: .center)
                    .accessibilityLabel(Text(verbatim: "\(paywallDismissSecondsRemaining)"))
            } else {
                Button(action: { advanceFromSubscriptionPaywall() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Self.onboardingPrimaryText)
                        .frame(minWidth: 40, minHeight: 40)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: L("common.dismiss")))
            }
        }
    }
    
    private var coinPaywallPreCTALegalBlock: some View {
        paywallLegalFooter(restoreDisabled: isPurchasing) {
            Text(L("onboarding.coinPaywallFinePrint"))
                .font(.system(size: Self.paywallLegalCopySize, weight: .regular))
                .foregroundStyle(Self.onboardingSecondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    /// Shared legal stack for both onboarding paywalls (same position, fonts, and weights).
    @ViewBuilder
    private func paywallLegalFooter(restoreDisabled: Bool, @ViewBuilder finePrint: () -> some View) -> some View {
        VStack(spacing: 6) {
            Button(action: { Task { await restorePurchases() } }) {
                Text(L("onboarding.restorePurchases"))
                    .font(.system(size: Self.paywallLegalCopySize, weight: .regular))
                    .foregroundStyle(Self.onboardingSecondaryText)
                    .underline()
            }
            .buttonStyle(.plain)
            .disabled(restoreDisabled)
            finePrint()
            coinPaywallLegalLinkRow
        }
        .frame(maxWidth: .infinity)
    }
    
    private var coinPaywallLegalLinkRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Link(L("settings.privacy"), destination: Self.paywallLegalPrivacyURL)
            Text("·")
            Link(L("settings.terms"), destination: Self.paywallLegalTermsURL)
            Text("·")
            Link(L("onboarding.termsOfUseEula"), destination: Self.paywallLegalEULAURL)
        }
        .font(.system(size: Self.paywallLegalCopySize, weight: .regular))
        .foregroundStyle(Self.onboardingSecondaryText)
        .tint(Self.onboardingSecondaryText)
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .minimumScaleFactor(0.75)
    }
    
    @ViewBuilder
    private var paywallHatShowcaseStrip: some View {
        let hats = paywallShowcaseHats
        if hats.isEmpty {
            Color.clear.frame(height: 0)
        } else {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(hats.enumerated()), id: \.element.id) { index, item in
                            paywallShowcaseItemCell(
                                item: item,
                                isSelected: index == (paywallShowcaseHatIndex % hats.count)
                            )
                            .id(item.id)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(height: Self.paywallHatStripHeight)
                .onAppear {
                    if let id = paywallPreviewHatId {
                        DispatchQueue.main.async {
                            proxy.scrollTo(id, anchor: .center)
                        }
                    }
                }
                .onChange(of: paywallShowcaseHatIndex) { _, _ in
                    if let id = paywallPreviewHatId {
                        withAnimation(.easeInOut(duration: 0.28)) {
                            proxy.scrollTo(id, anchor: .center)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func paywallShowcaseItemCell(item: AccessoryItem, isSelected: Bool) -> some View {
        let corner: CGFloat = 10
        ZStack {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(Self.onboardingCardFill)
            if item.id == "bunnyears" {
                Image("BunnyEarsReference")
                    .resizable()
                    .scaledToFit()
                    .padding(4)
                    .frame(width: 40, height: 40)
            } else if let file = item.modelFileName, !file.isEmpty {
                HatPreview3DView(fileName: file)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            } else {
                Text(item.emoji)
                    .font(.system(size: 24))
            }
        }
        .frame(width: 48, height: 48)
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(isSelected ? AppColors.paywallCTAGreen : Self.onboardingCardStroke, lineWidth: isSelected ? 2.5 : 1)
        )
    }
    
    private func formattedCoinCount(_ value: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale.current
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
    private func ctaLabelForSelectedPlan() -> String {
        switch selectedCoinPlan {
        case .annual:
            return L("onboarding.coinPaywallCTATrial")
        case .monthly, .weekly:
            return L("onboarding.coinPaywallCTAWeekly")
        }
    }
    
    @MainActor
    private func purchaseSelectedPlan() async {
        isPurchasing = true
        paywallErrorMessage = nil
        defer { isPurchasing = false }
        do {
            try await subscriptionManager.purchaseSubscription(productId: selectedCoinPlan.productId)
            gameManager.upgradeSubscription(to: selectedCoinPlan.tier)
            completeOnboardingAfterSubscriptionPurchase()
        } catch is CancellationError {
            return
        } catch {
            paywallErrorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    private func restorePurchases() async {
        isPurchasing = true
        paywallErrorMessage = nil
        defer { isPurchasing = false }
        do {
            try await subscriptionManager.restorePurchases()
            if let s = subscriptionManager.activeSubscription, s != .free {
                gameManager.upgradeSubscription(to: s)
                if currentStep == .coinPaywall {
                    completeOnboardingAfterSubscriptionPurchase()
                }
            }
        } catch {
            paywallErrorMessage = error.localizedDescription
        }
    }
    
    /// After a successful subscription (or restore) on the onboarding paywall, skip one-off coin packs and dismiss into the main app / tutorial.
    private func completeOnboardingAfterSubscriptionPurchase() {
        gameManager.gameState.hasCompletedPaywall = true
        completeOnboardingAndDismiss()
    }
    
    /// User closed the subscription paywall without subscribing — offer one-off coin packs next.
    private func advanceFromSubscriptionPaywall() {
        gameManager.gameState.hasCompletedPaywall = true
        coinPackDismissSecondsRemaining = Self.paywallDismissCountdownSeconds
        withAnimation(.easeInOut(duration: 0.2)) {
            currentStep = .coinPackOnboarding
        }
    }
    
    @MainActor
    private func purchaseSelectedCoinPack() async {
        isPurchasingCoinPack = true
        paywallErrorMessage = nil
        gameManager.iapLastErrorMessage = nil
        defer { isPurchasingCoinPack = false }
        let ok = await gameManager.purchaseCoinPack(selectedOnboardingCoinPack)
        if ok {
            completeOnboardingAndDismiss()
        } else if let err = gameManager.iapLastErrorMessage {
            paywallErrorMessage = err
        }
    }
    
    private func completeOnboardingAndDismiss() {
        gameManager.gameState.hasCompletedOnboarding = true
        withAnimation {
            isPresented = false
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    gameManager.scheduleFutureNotifications()
                }
                withAnimation {
                    currentStep = .pledge
                }
            }
        }
    }
}

// MARK: - Coin paywall CTA: diagonal light sweep
private struct CoinPaywallCTADiagonalShine: View {
    private let period: TimeInterval = 5.2
    /// Opposite tilt from the previous direction; still reads clearly across the pill.
    private let lineAngle: CGFloat = -56

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let h = max(geo.size.height, 1)
                let t = context.date.timeIntervalSinceReferenceDate
                let p = t.truncatingRemainder(dividingBy: period) / period
                // Long thin strip; gradient is sharp on the short axis so it reads as a line, not a soft blob.
                let span = hypot(w, h) * 1.45
                let lineThickness = max(4, min(w * 0.018, 8))
                let x = -span * 0.4 + p * (w + span * 0.85)
                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0), location: 0.0),
                        .init(color: .white.opacity(0), location: 0.46),
                        .init(color: .white.opacity(0.92), location: 0.5),
                        .init(color: .white.opacity(0), location: 0.54),
                        .init(color: .white.opacity(0), location: 1.0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: span, height: lineThickness)
                .rotationEffect(.degrees(lineAngle))
                .offset(x: x, y: h * 0.02)
                .blendMode(.screen)
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
        .environmentObject(GameManager())
}

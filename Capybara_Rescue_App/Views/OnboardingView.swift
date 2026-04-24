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
    
    enum OnboardingStep {
        case language
        case welcome
        case notifications
        case pledge
        case coinPaywall
    }
    
    /// Pro coin subscription options (maps to `SubscriptionManager` product IDs and recurring grant amounts).
    private enum CoinPaywallPlan: String, CaseIterable, Identifiable {
        case weekly, monthly, annual
        var id: String { rawValue }
        /// Top to bottom in the paywall: 100,000 / year first, 1,000 / week last.
        static let displayOrder: [CoinPaywallPlan] = [.annual, .monthly, .weekly]
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
        /// Temporary fixed prices until App Store Connect products are configured.
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
    private static let onboardingCapybaraHeight: CGFloat = 180
    private static let onboardingCTAHorizontalPadding: CGFloat = 24
    private static let onboardingCTABottomPadding: CGFloat = 40
    private static let paywallHatCycleSeconds: TimeInterval = 2.4
    
    /// Hats to cycle on the coin paywall (same rules as Items for CNY lantern).
    private var paywallShowcaseHats: [AccessoryItem] {
        let owned = gameManager.gameState.ownedAccessories
        return AccessoryItem.allItems.filter { item in
            guard item.isHat, item.modelFileName != nil else { return false }
            if item.id == "redlantern" {
                return Date.shouldShowCNYItems2026() || owned.contains(item.id)
            }
            return true
        }.sorted { $0.cost < $1.cost }
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
            case .coinPaywall:
                coinPaywallView
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
            
            Image(systemName: "globe")
                .font(.system(size: 44))
                .foregroundStyle(AppColors.paywallCTAGreen)
            
            Text(L("onboarding.languageTitle"))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Self.onboardingPrimaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Text(L("onboarding.languageSubtitle"))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Self.onboardingSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(LocalizationManager.supportedLanguages, id: \.code) { lang in
                    Button(action: {
                        localizationManager.currentLanguage = lang.code
                    }) {
                        HStack(spacing: 6) {
                            Text(lang.displayName)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
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
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Self.onboardingCardFill)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
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
                Text(L("common.next"))
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
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
            
            Text(L("onboarding.welcomeTitle"))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Self.onboardingPrimaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Text(L("onboarding.welcomeSubtitle"))
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(Self.onboardingSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            TextField(L("onboarding.namePlaceholder"), text: $capybaraName)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(Self.onboardingPrimaryText)
                .tint(AppColors.paywallCTAGreen)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Self.onboardingCardFill)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
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
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
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
            
            Text(L("onboarding.notificationsTitle"))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Self.onboardingPrimaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Text(L("onboarding.notificationsSubtitle"))
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(Self.onboardingSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
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
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Self.onboardingSecondaryText)
            }
            
            Button(action: {
                requestNotificationPermission()
            }) {
                Text(L("onboarding.enableNotifications"))
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
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
            
            Text(L("onboarding.pledgeTitle"))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Self.onboardingPrimaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.paywallCTAGreen)
                    Text(L("onboarding.pledgeFeed"))
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(Self.onboardingPrimaryText)
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.paywallCTAGreen)
                    Text(L("onboarding.pledgeDrinks"))
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(Self.onboardingPrimaryText)
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.paywallCTAGreen)
                    Text(L("onboarding.pledgeHappy"))
                        .font(.system(size: 18, weight: .medium, design: .rounded))
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
                    currentStep = .coinPaywall
                }
            }) {
                Text(L("onboarding.acceptAndGo"))
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppColors.paywallCTAGreen)
                    )
            }
            .padding(.horizontal, Self.onboardingCTAHorizontalPadding)
            .padding(.bottom, Self.onboardingCTABottomPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Coin Paywall (post-pledge)
    /// Match other onboarding steps: scroll the hero + tiers; pin CTA + links to the bottom with the same insets as `Continue` / `Accept and Go`.
    private var coinPaywallView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    Spacer()
                        .frame(height: Self.onboardingTopInset)
                    Text(L("onboarding.coinPaywallTitle"))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Self.onboardingPrimaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Text(L("onboarding.coinPaywallItemsHint"))
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Self.onboardingSecondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                    paywallHatShowcaseStrip
                    if let item = paywallPreviewedAccessory {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(localizedAccessoryName(id: item.id))
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(Self.onboardingPrimaryText)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 8)
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(formattedCoinCount(item.cost))
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                Text(L("common.coins"))
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                            }
                            .foregroundStyle(Self.onboardingPrimaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 4)
                    }
                    if #available(iOS 17.0, *) {
                        Capybara3DView(
                            emotion: gameManager.gameState.capybaraEmotion,
                            equippedAccessories: gameManager.gameState.equippedAccessories,
                            previewingAccessoryId: paywallPreviewHatId,
                            onPet: { },
                            initialRotation: nil
                        )
                        .frame(height: Self.onboardingCapybaraHeight)
                        .scaleEffect(0.38)
                        .frame(height: Self.onboardingCapybaraHeight)
                        .clipped()
                        .allowsHitTesting(false)
                    } else {
                        Text(paywallShowcaseHats.isEmpty ? "🐹" : (paywallShowcaseHats[paywallShowcaseHatIndex % paywallShowcaseHats.count].emoji))
                            .font(.system(size: 80))
                            .frame(height: Self.onboardingCapybaraHeight)
                    }
                    VStack(spacing: 8) {
                        ForEach(CoinPaywallPlan.displayOrder) { plan in
                            coinPaywallOptionButton(plan: plan)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
                }
                .onAppear {
                    paywallShowcaseHatIndex = 0
                }
                .onReceive(Timer.publish(every: Self.paywallHatCycleSeconds, on: .main, in: .common).autoconnect()) { _ in
                    let n = paywallShowcaseHats.count
                    guard n > 0 else { return }
                    paywallShowcaseHatIndex = (paywallShowcaseHatIndex + 1) % n
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack(spacing: 8) {
                Button(action: { Task { await purchaseSelectedPlan() } }) {
                    Group {
                        if isPurchasing {
                            Text(L("onboarding.coinPaywallPurchasing"))
                        } else {
                            Text(ctaLabelForSelectedPlan())
                        }
                    }
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(AppColors.paywallCTAGreen)
                            CoinPaywallCTADiagonalShine()
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    )
                }
                .disabled(isPurchasing)
                .opacity(isPurchasing ? 0.7 : 1.0)
                Button(action: { Task { await restorePurchases() } }) {
                    Text(L("onboarding.restorePurchases"))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.paywallCTAGreen)
                }
                .disabled(isPurchasing)
            }
            .padding(.horizontal, Self.onboardingCTAHorizontalPadding)
            .padding(.bottom, Self.onboardingCTABottomPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await subscriptionManager.loadProducts()
        }
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
                .frame(height: 56)
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
    
    private func coinPaywallOptionButton(plan: CoinPaywallPlan) -> some View {
        let selected = selectedCoinPlan == plan
        let price = plan.hardcodedPaywallPrice
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCoinPlan = plan
            }
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formattedCoinCount(plan.coinsPerPeriod))
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(Self.onboardingPrimaryText)
                    Text(L(plan.leftCoinsOnlySubtitleKey))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Self.onboardingSecondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(price)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(Self.onboardingPrimaryText)
                    Text(L(plan.listPeriodKey))
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Self.onboardingSecondaryText)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Self.onboardingCardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selected ? AppColors.paywallCTAGreen : Self.onboardingCardStroke, lineWidth: selected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private func formattedCoinCount(_ value: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale.current
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
    private func ctaLabelForSelectedPlan() -> String {
        let coins = formattedCoinCount(selectedCoinPlan.coinsPerPeriod)
        let freq = L(selectedCoinPlan.ctaFrequencyKey)
        return String(format: L("onboarding.coinPaywallCTAFormat"), coins, freq)
    }
    
    @MainActor
    private func purchaseSelectedPlan() async {
        isPurchasing = true
        paywallErrorMessage = nil
        defer { isPurchasing = false }
        do {
            try await subscriptionManager.purchaseSubscription(productId: selectedCoinPlan.productId)
            gameManager.upgradeSubscription(to: selectedCoinPlan.tier)
            completeOnboardingAndDismiss()
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
                completeOnboardingAndDismiss()
            }
        } catch {
            paywallErrorMessage = error.localizedDescription
        }
    }
    
    private func completeOnboardingAndDismiss() {
        gameManager.gameState.hasCompletedPaywall = true
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
    private let period: TimeInterval = 2.5

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let h = max(geo.size.height, 1)
                let t = context.date.timeIntervalSinceReferenceDate
                let p = t.truncatingRemainder(dividingBy: period) / period
                let bandW = w * 0.5
                // p 0...1: band travels left → right, slightly past edges for a smooth loop
                let x = -bandW * 0.35 + p * (w + bandW * 0.7)
                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0.0), location: 0.0),
                        .init(color: .white.opacity(0.0), location: 0.38),
                        .init(color: .white.opacity(0.7), location: 0.5),
                        .init(color: .white.opacity(0.0), location: 0.62),
                        .init(color: .white.opacity(0.0), location: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: bandW, height: h * 1.5)
                .rotationEffect(.degrees(20))
                .offset(x: x, y: 0)
                .blendMode(.softLight)
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
        .environmentObject(GameManager())
}

import SwiftUI
import UserNotifications

// MARK: - Onboarding View
struct OnboardingView: View {
    @EnvironmentObject var gameManager: GameManager
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Binding var isPresented: Bool
    
    @State private var currentStep: OnboardingStep = .language
    @State private var capybaraName: String = ""
    
    enum OnboardingStep {
        case language
        case welcome
        case notifications
        case pledge
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
            }
        }
        .preferredColorScheme(.light)
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
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppColors.paywallCTABorder, lineWidth: 2)
                            )
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
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppColors.paywallCTABorder, lineWidth: 2)
                            )
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
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppColors.paywallCTABorder, lineWidth: 2)
                            )
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
                completeOnboardingAndDismiss()
            }) {
                Text(L("onboarding.acceptAndGo"))
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppColors.paywallCTAGreen)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppColors.paywallCTABorder, lineWidth: 2)
                            )
                    )
            }
            .padding(.horizontal, Self.onboardingCTAHorizontalPadding)
            .padding(.bottom, Self.onboardingCTABottomPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

#Preview {
    OnboardingView(isPresented: .constant(true))
        .environmentObject(GameManager())
}

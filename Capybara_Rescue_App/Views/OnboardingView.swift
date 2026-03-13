import SwiftUI
import UserNotifications

// MARK: - Onboarding View
struct OnboardingView: View {
    @EnvironmentObject var gameManager: GameManager
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Binding var isPresented: Bool
    
    @State private var currentStep: OnboardingStep = .language
    @State private var capybaraName: String = ""
    @FocusState private var isNameFieldFocused: Bool
    
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
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 40)
                
                Image(systemName: "globe")
                    .font(.system(size: 64))
                    .foregroundStyle(AppColors.accent)
                
                Text(L("onboarding.languageTitle"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Self.onboardingPrimaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Text(L("onboarding.languageSubtitle"))
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(Self.onboardingSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                VStack(spacing: 0) {
                    ForEach(LocalizationManager.supportedLanguages, id: \.code) { lang in
                        Button(action: {
                            localizationManager.currentLanguage = lang.code
                        }) {
                            HStack {
                                Text(lang.displayName)
                                    .font(.system(size: 18, weight: .medium, design: .rounded))
                                    .foregroundStyle(Self.onboardingPrimaryText)
                                Spacer()
                                if localizationManager.currentLanguage == lang.code {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(AppColors.accent)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Self.onboardingCardFill)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Self.onboardingCardStroke, lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
                
                Spacer()
                    .frame(height: 32)
                
                Button(action: {
                    withAnimation {
                        currentStep = .welcome
                    }
                }) {
                    Text(L("common.next"))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AppColors.accent)
                        )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Welcome View
    private var welcomeView: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Top spacing
                Spacer()
                    .frame(height: 40)
                
                // Capybara emoji or icon
                Image("iconcapybara")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                
                Text("Thank you for rescuing a capybara!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Self.onboardingPrimaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("What would you like to call your capybara?")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(Self.onboardingSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Name input
                ZStack {
                    // Tappable background area
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Self.onboardingCardFill)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Self.onboardingCardStroke, lineWidth: 1)
                        )
                        .frame(minHeight: 60)
                        .onTapGesture {
                            // Focus the text field when tapping anywhere on the background
                            isNameFieldFocused = true
                        }
                    
                    // Text field
                    TextField("Enter name", text: $capybaraName)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(Self.onboardingPrimaryText)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                        .autocapitalization(.words)
                        .autocorrectionDisabled()
                        .focused($isNameFieldFocused)
                }
                .padding(.horizontal, 32)
                .onAppear {
                    // Auto-focus when view appears to make keyboard appear immediately
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isNameFieldFocused = true
                    }
                }
                
                // Spacing before button
                Spacer()
                    .frame(height: 40)
                
                // Continue button
                Button(action: {
                    if !capybaraName.trimmingCharacters(in: .whitespaces).isEmpty {
                        gameManager.renameCapybara(to: capybaraName.trimmingCharacters(in: .whitespaces))
                        withAnimation {
                            currentStep = .notifications
                        }
                    }
                }) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AppColors.accent)
                        )
                }
                .disabled(capybaraName.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(capybaraName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Notifications View
    private var notificationsView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "bell.fill")
                .font(.system(size: 80))
                .foregroundStyle(AppColors.accent)
            
            Text("Stay Connected")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Self.onboardingPrimaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Text("Enable notifications to get notifications, including reminders to feed and care for your capybara!")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(Self.onboardingSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
            
            // Enable notifications button
            Button(action: {
                requestNotificationPermission()
            }) {
                Text("Enable Notifications")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppColors.accent)
                    )
            }
            .padding(.horizontal, 32)
            
            // Skip button
            Button(action: {
                withAnimation {
                    currentStep = .pledge
                }
            }) {
                Text("Skip")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Self.onboardingSecondaryText)
            }
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Pledge View
    private var pledgeView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Text("📜")
                .font(.system(size: 80))
            
            Text("I pledge to take care of my capybara")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Self.onboardingPrimaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.accent)
                    Text("By feeding it")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(Self.onboardingPrimaryText)
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.accent)
                    Text("By giving it drinks")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(Self.onboardingPrimaryText)
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.accent)
                    Text("By making it feel good")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(Self.onboardingPrimaryText)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Accept button
            Button(action: {
                // Complete onboarding and go straight to tutorial
                gameManager.gameState.hasCompletedOnboarding = true
                withAnimation {
                    isPresented = false
                }
            }) {
                Text("Accept and Go")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppColors.accent)
                    )
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Helper Functions
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
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

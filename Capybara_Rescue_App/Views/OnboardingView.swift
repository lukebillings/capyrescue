import SwiftUI
import UserNotifications

// MARK: - Onboarding View
struct OnboardingView: View {
    @EnvironmentObject var gameManager: GameManager
    @Binding var isPresented: Bool
    
    @State private var currentStep: OnboardingStep = .welcome
    @State private var capybaraName: String = ""
    @State private var showingAd = false
    @State private var adProgress: CGFloat = 0
    @FocusState private var isNameFieldFocused: Bool
    
    enum OnboardingStep {
        case welcome
        case notifications
        case pledge
        case ad
    }
    
    var body: some View {
        ZStack {
            // Background
            AppColors.background
                .ignoresSafeArea()
            
            if showingAd {
                adView
            } else {
                switch currentStep {
                case .welcome:
                    welcomeView
                case .notifications:
                    notificationsView
                case .pledge:
                    pledgeView
                case .ad:
                    adView
                }
            }
        }
    }
    
    // MARK: - Welcome View
    private var welcomeView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Capybara emoji or icon
            Image("iconcapybara")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
            
            Text("Thank you for rescuing a capybara!")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Text("What would you like to call your capybara?")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            // Name input
            TextField("Enter name", text: $capybaraName)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 32)
                .autocapitalization(.words)
                .autocorrectionDisabled()
                .focused($isNameFieldFocused)
            
            Spacer()
            
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
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Text("Enable notifications to get reminders to feed and care for your capybara!")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
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
                    .foregroundStyle(.white.opacity(0.6))
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
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.accent)
                    Text("By feeding it")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.accent)
                    Text("By giving it drinks")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.accent)
                    Text("By making it feel good")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Accept button
            Button(action: {
                withAnimation {
                    currentStep = .ad
                    showingAd = true
                }
            }) {
                VStack(spacing: 8) {
                    Text("Accept and Go")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                    
                    Text("(Ad will play)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.black.opacity(0.7))
                }
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
    
    // MARK: - Ad View
    private var adView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Text("📺")
                .font(.system(size: 80))
            
            Text("Watching Ad...")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            // Progress circle
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: adProgress)
                    .stroke(AppColors.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int((1 - adProgress) * 10))")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            
            Spacer()
        }
        .onAppear {
            startAdTimer()
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
    
    private func startAdTimer() {
        adProgress = 0
        
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            Task { @MainActor in
                adProgress += 0.01
                
                if adProgress >= 1.0 {
                    timer.invalidate()
                    // Complete onboarding
                    UserDefaults.standard.set(true, forKey: "has_completed_onboarding")
                    gameManager.watchAd() // Give coins for watching ad
                    withAnimation {
                        isPresented = false
                    }
                }
            }
        }
        timer.fire()
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
        .environmentObject(GameManager())
}

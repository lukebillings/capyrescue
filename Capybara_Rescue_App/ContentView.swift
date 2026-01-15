import SwiftUI
import UserNotifications

// MARK: - Main Content View
struct ContentView: View {
    @EnvironmentObject var gameManager: GameManager
    @ObservedObject private var consentManager = ConsentManager.shared
    
    @State private var selectedTab: MenuTab = .food
    @State private var showRenameSheet = false
    @State private var showShopSheet = false
    @State private var showAchievementsSheet = false
    @State private var showPanel = false // Hide panel by default - show only menu bar
    @State private var capybaraPosition: CGPoint = .zero
    @State private var showOnboarding = false
    @State private var showNotificationPermission = false
    @State private var currentTutorialStep: TutorialStep? = nil
    @State private var showAdRemovalPromo = false
    @State private var shouldApplyInitialRotation = false

    private let capybaraVisualOffsetY: CGFloat = -40
    
    // Device-specific key for notification permission request (not synced)
    private let hasRequestedNotificationsOnThisDeviceKey = "has_requested_notifications_on_this_device"
    
    private func checkTutorialStatus() {
        let hasCompletedOnboarding = gameManager.gameState.hasCompletedOnboarding
        let hasCompletedTutorial = gameManager.gameState.hasCompletedTutorial
        if hasCompletedOnboarding && !hasCompletedTutorial && currentTutorialStep == nil {
            currentTutorialStep = .food
        }
    }
    
    private func checkOnboardingStatus() {
        showOnboarding = !gameManager.gameState.hasCompletedOnboarding
    }
    
    private func checkNotificationPermissionStatus() {
        // Check if onboarding is complete (synced) but notifications haven't been requested on THIS device
        let hasCompletedOnboarding = gameManager.gameState.hasCompletedOnboarding
        let hasRequestedOnThisDevice = UserDefaults.standard.bool(forKey: hasRequestedNotificationsOnThisDeviceKey)
        
        // Check current notification authorization status
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                // Show notification permission screen if:
                // 1. Onboarding is complete (user has used app before on another device)
                // 2. Notifications haven't been requested on THIS device yet
                // 3. Permission status is not determined (not yet asked)
                if hasCompletedOnboarding && !hasRequestedOnThisDevice && settings.authorizationStatus == .notDetermined {
                    showNotificationPermission = true
                }
            }
        }
    }
    
    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView(isPresented: $showOnboarding)
                    .environmentObject(gameManager)
                    .onChange(of: showOnboarding) { oldValue, newValue in
                        if !newValue {
                            // Onboarding completed, apply initial rotation and check if tutorial should show
                            shouldApplyInitialRotation = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                checkTutorialStatus()
                            }
                            // Reset after a short delay so it only applies once
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                shouldApplyInitialRotation = false
                            }
                        }
                    }
            } else if showNotificationPermission {
                NotificationPermissionView(isPresented: $showNotificationPermission)
                    .environmentObject(gameManager)
            } else {
                mainContentView
                    .onAppear {
                        checkTutorialStatus()
                        // Track app open and check if we should show ad removal promo
                        gameManager.incrementAppOpenCount()
                        if gameManager.shouldShowAdRemovalPromo() {
                            // Small delay to ensure UI is ready
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                showAdRemovalPromo = true
                            }
                        }
                    }
            }
        }
        .onAppear {
            checkOnboardingStatus()
            checkNotificationPermissionStatus()
        }
        .onChange(of: gameManager.gameState.hasCompletedOnboarding) { oldValue, newValue in
            checkOnboardingStatus()
            // Check notification permission when onboarding status changes
            if newValue {
                checkNotificationPermissionStatus()
            }
        }
    }
    
    private var mainContentView: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                AnimatedBackground()
                    .ignoresSafeArea()
                
                // Main content
                VStack(spacing: 0) {
                    // Banner Ad at the top (only show if consent allows and user hasn't removed ads)
                    if consentManager.canRequestAds && !gameManager.gameState.hasRemovedBannerAds {
                        BannerAdView(adUnitID: "ca-app-pub-3940256099942544/2435281174")
                            .frame(height: 50)
                    }
                    
                    // Combined header: Profile, Name, Badges, Coins, Get More
                    HStack(spacing: 6) {
                        // Capybara image in circle
                        Image("iconcapybara")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.3), lineWidth: 2)
                            )
                        
                        // Name (tappable to rename)
                        Button(action: {
                            HapticManager.shared.buttonPress()
                            showRenameSheet = true
                        }) {
                            Text(gameManager.gameState.capybaraName)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, .white.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Achievements button
                        Button(action: {
                            HapticManager.shared.buttonPress()
                            showAchievementsSheet = true
                        }) {
                            Image(systemName: "medal.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .tutorialHighlight(key: "achievements_button")
                        
                        Spacer()
                        
                        // Coin icon and amount
                        HStack(spacing: 2) {
                            // Coin icon
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 28, height: 28)
                                    .shadow(color: Color(hex: "FFD700").opacity(0.5), radius: 6, x: 0, y: 2)
                                
                                Text("₵")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color(hex: "8B4513"))
                            }
                            
                            Text("\(gameManager.gameState.capycoins)")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .padding(.leading, -8)
                        
                        // Get More button
                        Button(action: {
                            HapticManager.shared.buttonPress()
                            showShopSheet = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                
                                Text("Get More")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "FFD700"), Color(hex: "FF8C00")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .shadow(color: Color(hex: "FFD700").opacity(0.4), radius: 6, x: 0, y: 3)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.leading, max(geometry.safeAreaInsets.leading, 0) + 20)
                    .padding(.trailing, max(geometry.safeAreaInsets.trailing, 0) + 20)
                    .padding(.vertical, 10)
                    .background(
                        GlassBackground()
                    )
                    .padding(.top, 8)
                    
                    // Stats display
                    StatsDisplayView(
                        food: gameManager.gameState.food,
                        drink: gameManager.gameState.drink,
                        happiness: gameManager.gameState.happiness
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    
                    Spacer()
                    
                    // Capybara in the center (3D) - moved up higher
                    Capybara3DView(
                        emotion: gameManager.gameState.capybaraEmotion,
                        equippedAccessories: gameManager.gameState.equippedAccessories,
                        previewingAccessoryId: gameManager.previewingAccessoryId,
                        onPet: {
                            gameManager.petCapybara()
                        },
                        initialRotation: shouldApplyInitialRotation ? 45 : nil
                    )
                    .frame(height: 320) // Increased height to show full capybara including head
                    .offset(y: capybaraVisualOffsetY) // Move up higher on the page
                    .tutorialHighlight(key: "capybara_tap")
                    .background(
                        GeometryReader { capyGeometry in
                            Color.clear.preference(
                                key: CapybaraFramePreferenceKey.self,
                                value: capyGeometry.frame(in: .global)
                            )
                        }
                    )
                    
                    // Spacer - always present to maintain capybara position
                    Spacer()
                }
                
                // Panel area - show specific panel as overlay
                if showPanel {
                    VStack {
                        Spacer()
                        panelContent
                            .frame(minHeight: 50, maxHeight: 180) // Fixed height for panels
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom + 4 : 8)
                    }
                    .zIndex(99) // Below master panel overlay but above main content
                }
                
                // Master panel at bottom - replaces menu bar
                VStack {
                    Spacer(minLength: 0)
                    
                    if !showPanel {
                        // Show master panel at bottom
                        MasterPanel(onCategorySelected: { tab in
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                selectedTab = tab
                                if tab == .shop {
                                    showPanel = false
                                    showShopSheet = true
                                } else {
                                    showPanel = true
                                }
                            }
                        })
                        .padding(.leading, max(geometry.safeAreaInsets.leading, 0) + 20)
                        .padding(.trailing, max(geometry.safeAreaInsets.trailing, 0) + 20)
                        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom : 4)
                    }
                }
                .zIndex(100) // Ensure master panel is always on top
                
                // Thrown item animation overlay    
                FoodThrowingOverlay(
                    item: gameManager.thrownItem,
                    capybaraPosition: capybaraPosition,
                    onAnimationComplete: {}
                )
                
                // Love hearts overlay (when happiness >= 80)
                LoveHeartsOverlay(
                    isActive: gameManager.gameState.happiness >= 80,
                    capybaraPosition: capybaraPosition
                )
                
                // Unhappy emojis overlay (when happiness < 50)
                UnhappyEmojisOverlay(
                    isActive: gameManager.gameState.happiness < 50,
                    capybaraPosition: capybaraPosition
                )
                
                // Speech bubble overlay (when food or drink < 80)
                CapybaraSpeechBubbleOverlay(
                    food: gameManager.gameState.food,
                    drink: gameManager.gameState.drink,
                    capybaraPosition: capybaraPosition
                )
                
                // Run away overlay
                if gameManager.gameState.hasRunAway {
                    RunAwayView(onRestart: {
                        gameManager.resetGame()
                    })
                    .transition(.opacity)
                }
                
                // Tutorial overlay
                if currentTutorialStep != nil {
                    TutorialOverlay(currentStep: $currentTutorialStep)
                        .zIndex(200) // Above everything else
                }
                
                // Toast overlay
                if let toastMessage = gameManager.toastMessage {
                    VStack {
                        Spacer()
                        ToastView(message: toastMessage)
                            .padding(.bottom, 100)
                    }
                    .zIndex(201) // Above everything including tutorial
                }
                
                // Ad removal promo popup
                if showAdRemovalPromo {
                    RemoveBannerAdPromoView(isPresented: $showAdRemovalPromo)
                        .zIndex(202) // Above everything
                }
            }
            .onPreferenceChange(CapybaraFramePreferenceKey.self) { frame in
                guard frame != .zero else { return }
                capybaraPosition = CGPoint(
                    x: frame.midX,
                    y: frame.midY
                )
            }
        }
        .sheet(isPresented: $showRenameSheet) {
            RenameSheet(
                isPresented: $showRenameSheet,
                name: $gameManager.gameState.capybaraName,
                onSave: { newName in
                    gameManager.renameCapybara(to: newName)
                }
            )
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showShopSheet) {
            ShopSheetView()
                .environmentObject(gameManager)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showAchievementsSheet) {
            AchievementsView()
                .environmentObject(gameManager)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        // Master panel shows by default (showPanel = false)
    }
    
    @ViewBuilder
    private var panelContent: some View {
        switch selectedTab {
        case .food:
            FoodPanel(
                onFoodSelected: { item in
                    if gameManager.feedCapybara(with: item) {
                        gameManager.throwItem(emoji: item.emoji, isFood: true)
                    }
                },
                onBack: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showPanel = false // Go back to master panel
                    }
                }
            )
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            
        case .drink:
            DrinkPanel(
                onDrinkSelected: { item in
                    if gameManager.giveWater(with: item) {
                        gameManager.throwItem(emoji: item.emoji, isFood: false)
                    }
                },
                onBack: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showPanel = false // Go back to master panel
                    }
                }
            )
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            
        case .items:
            ItemsPanel(
                onBack: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showPanel = false // Go back to master panel
                    }
                },
                onOpenShop: {
                    showPanel = false
                    showShopSheet = true
                }
            )
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            
        case .shop:
            EmptyView()
        }
    }
}

// MARK: - Preferences
private struct CapybaraFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// MARK: - Shop Sheet View
struct ShopSheetView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ShopPanel()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticManager.shared.buttonPress()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
        }
    }
}

// MARK: - Animated Background
struct AnimatedBackground: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(hex: "0f0c29"),
                    Color(hex: "302b63"),
                    Color(hex: "24243e")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Animated orbs
            GeometryReader { geometry in
                ZStack {
                    // Large orb 1
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.purple.opacity(0.3),
                                    Color.purple.opacity(0)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 200
                            )
                        )
                        .frame(width: 400, height: 400)
                        .offset(
                            x: sin(phase) * 30 - 100,
                            y: cos(phase * 0.7) * 40 - 200
                        )
                    
                    // Large orb 2
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.blue.opacity(0.2),
                                    Color.blue.opacity(0)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 250
                            )
                        )
                        .frame(width: 500, height: 500)
                        .offset(
                            x: cos(phase * 0.8) * 40 + 100,
                            y: sin(phase * 0.6) * 50 + 200
                        )
                    
                    // Small accent orb
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "FFD700").opacity(0.15),
                                    Color(hex: "FFD700").opacity(0)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .offset(
                            x: sin(phase * 1.2) * 50,
                            y: cos(phase) * 30 + 100
                        )
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .onAppear {
            withAnimation(
                .linear(duration: 10)
                .repeatForever(autoreverses: false)
            ) {
                phase = .pi * 2
            }
        }
    }
}

// MARK: - Toast View
struct ToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.red.opacity(0.9), Color.orange.opacity(0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            )
            .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Notification Permission View (for new devices)
struct NotificationPermissionView: View {
    @EnvironmentObject var gameManager: GameManager
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // Background
            AppColors.background
                .ignoresSafeArea()
            
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
                    // Mark as requested on this device (even if skipped)
                    UserDefaults.standard.set(true, forKey: "has_requested_notifications_on_this_device")
                    withAnimation {
                        isPresented = false
                    }
                }) {
                    Text("Skip")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                // Mark as requested on this device
                UserDefaults.standard.set(true, forKey: "has_requested_notifications_on_this_device")
                withAnimation {
                    isPresented = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(GameManager())
}


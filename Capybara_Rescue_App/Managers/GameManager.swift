import Foundation
import SwiftUI
import Combine
import UserNotifications

// MARK: - Game Manager
@MainActor
class GameManager: ObservableObject {
    @Published var gameState: GameState {
        didSet {
            if !isSaving {
                saveGameState()
            }
            // Check for threshold crossings and send notifications
            // Compare each stat individually since struct assignment creates new instance
            if oldValue.food != gameState.food {
                checkThresholdCrossing(statType: "food", oldValue: oldValue.food, newValue: gameState.food)
            }
            if oldValue.drink != gameState.drink {
                checkThresholdCrossing(statType: "drink", oldValue: oldValue.drink, newValue: gameState.drink)
            }
            if oldValue.happiness != gameState.happiness {
                checkThresholdCrossing(statType: "petting", oldValue: oldValue.happiness, newValue: gameState.happiness)
            }
        }
    }
    
    @Published var thrownItem: ThrownItem?
    @Published var showRunAwayAlert: Bool = false
    @Published var previewingAccessoryId: String? = nil // For previewing items before purchase
    
    private var decayTimer: Timer?
    private let userDefaultsKey = "capybara_rescue_game_state"
    private var isSaving = false
    
    struct ThrownItem: Identifiable {
        let id = UUID()
        let emoji: String
        let isFood: Bool
    }
    
    init() {
        // Load saved state or use default
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedState = try? JSONDecoder().decode(GameState.self, from: data) {
            self.gameState = savedState
        } else {
            self.gameState = GameState.defaultState
        }
        
        // Apply time-based decay from last session
        applyOfflineDecay()
        
        // Check and update login streak
        checkDailyLogin()
        
        // Check notification permissions (will request if not determined)
        checkNotificationPermissions()
        
        // Check current stats and send notifications if needed
        checkCurrentStatsForNotifications()
        
        // Start decay timer
        startDecayTimer()
    }
    
    // MARK: - Achievement System
    func checkDailyLogin() {
        let calendar = Calendar.current
        let now = Date()
        
        // Check if we have a last login date
        if let lastLogin = gameState.lastLoginDate {
            // Check if it's a new day
            if calendar.isDateInToday(lastLogin) {
                // Already logged in today, do nothing
                return
            }
            
            // Check if last login was yesterday
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
               calendar.isDate(lastLogin, inSameDayAs: yesterday) {
                // Logged in yesterday, continue streak
                gameState.loginStreak += 1
            } else {
                // Streak broken (more than 1 day gap), reset to 1
                gameState.loginStreak = 1
            }
        } else {
            // First login ever
            gameState.loginStreak = 1
        }
        
        // Update last login date
        gameState.lastLoginDate = now
        
        // Check for achievements
        checkAchievements()
    }
    
    private func checkAchievements() {
        let streak = gameState.loginStreak
        
        // Check each achievement threshold
        if streak >= 1 && !gameState.earnedAchievements.contains("daily_login") {
            gameState.earnedAchievements.insert("daily_login")
        }
        if streak >= 3 && !gameState.earnedAchievements.contains("streak_3") {
            gameState.earnedAchievements.insert("streak_3")
        }
        if streak >= 7 && !gameState.earnedAchievements.contains("streak_7") {
            gameState.earnedAchievements.insert("streak_7")
        }
        if streak >= 30 && !gameState.earnedAchievements.contains("streak_30") {
            gameState.earnedAchievements.insert("streak_30")
        }
        if streak >= 100 && !gameState.earnedAchievements.contains("streak_100") {
            gameState.earnedAchievements.insert("streak_100")
        }
        if streak >= 365 && !gameState.earnedAchievements.contains("streak_365") {
            gameState.earnedAchievements.insert("streak_365")
        }
    }
    
    // MARK: - Persistence
    private func saveGameState() {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        
        // Update lastUpdateTime (isSaving flag prevents recursive call)
        gameState.lastUpdateTime = Date()
        
        if let data = try? JSONEncoder().encode(gameState) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    // MARK: - Decay System
    private func applyOfflineDecay() {
        // Calculate decay based on 10-minute intervals
        let minutesSinceLastUpdate = Date().timeIntervalSince(gameState.lastUpdateTime) / 60
        let tenMinuteIntervals = Int(minutesSinceLastUpdate / 10)
        let decayAmount = tenMinuteIntervals // 1 point per 10 minutes
        
        if decayAmount > 0 {
            gameState.food = max(0, gameState.food - decayAmount)
            gameState.drink = max(0, gameState.drink - decayAmount)
            gameState.happiness = max(0, gameState.happiness - decayAmount)
            
            checkRunAway()
        }
    }
    
    private func startDecayTimer() {
        // Decay stats every 10 minutes (600 seconds)
        decayTimer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.applyDecay()
            }
        }
    }
    
    private func applyDecay() {
        gameState.food = max(0, gameState.food - 1)
        gameState.drink = max(0, gameState.drink - 1)
        gameState.happiness = max(0, gameState.happiness - 1)
        
        checkRunAway()
    }
    
    private func checkRunAway() {
        if gameState.food == 0 && gameState.drink == 0 && gameState.happiness == 0 {
            gameState.hasRunAway = true
            showRunAwayAlert = true
        }
    }
    
    // MARK: - Actions
    func feedCapybara(with item: FoodItem) -> Bool {
        guard canAfford(item.cost) else { return false }
        
        gameState.capycoins -= item.cost
        
        gameState.food = min(100, gameState.food + item.foodValue)
        return true
    }
    
    func giveWater(with item: DrinkItem) -> Bool {
        guard canAfford(item.cost) else { return false }
        
        gameState.capycoins -= item.cost
        
        gameState.drink = min(100, gameState.drink + item.drinkValue)
        return true
    }
    
    func petCapybara() {
        gameState.happiness = min(100, gameState.happiness + 1)
    }
    
    func purchaseAccessory(_ item: AccessoryItem) -> Bool {
        guard canAfford(item.cost) else { return false }
        guard !gameState.ownedAccessories.contains(item.id) else { return false }
        
        gameState.capycoins -= item.cost
        
        gameState.ownedAccessories.append(item.id)
        return true
    }
    
    func equipAccessory(_ itemId: String) {
        if gameState.equippedAccessories.contains(itemId) {
            gameState.equippedAccessories.removeAll { $0 == itemId }
        } else {
            gameState.equippedAccessories.append(itemId)
        }
    }
    
    func previewAccessory(_ itemId: String) {
        previewingAccessoryId = itemId
    }
    
    func clearPreview() {
        previewingAccessoryId = nil
    }
    
    func canAfford(_ cost: Int) -> Bool {
        return gameState.capycoins >= cost
    }
    
    // MARK: - Coins & Purchases
    func watchAd() {
        // Simulate watching a 10-second ad
        gameState.capycoins += 10
    }
    
    func purchaseCoinPack(_ pack: CoinPack) {
        // In a real app, this would integrate with StoreKit
        // For now, we'll just add the coins directly
        gameState.capycoins += pack.coins
    }
    
    func renameCapybara(to newName: String) {
        gameState.capybaraName = newName
    }
    
    // MARK: - Reset
    func resetGame() {
        gameState = GameState.defaultState
        showRunAwayAlert = false
    }
    
    func throwItem(emoji: String, isFood: Bool) {
        thrownItem = ThrownItem(emoji: emoji, isFood: isFood)
        
        // Clear after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.thrownItem = nil
        }
    }
    
    // MARK: - Notification Permissions
    private func checkNotificationPermissions() {
        // Only check the status, don't request authorization automatically
        // Authorization should only be requested when user taps the button in onboarding
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
                    print("⚠️ Notification permissions not determined. Will request in onboarding.")
                case .denied:
                    print("❌ Notification permissions denied. User needs to enable in Settings.")
                case .authorized:
                    print("✅ Notification permissions authorized")
                case .provisional:
                    print("⚠️ Notification permissions provisional")
                case .ephemeral:
                    print("⚠️ Notification permissions ephemeral")
                @unknown default:
                    print("⚠️ Unknown notification permission status")
                }
            }
        }
    }
    
    // MARK: - Notifications
    private func checkCurrentStatsForNotifications() {
        // Check if stats are already below thresholds and send notifications
        if gameState.food < 80 {
            sendNotification(statType: "food", urgent: gameState.food < 50)
        }
        if gameState.drink < 80 {
            sendNotification(statType: "drink", urgent: gameState.drink < 50)
        }
        if gameState.happiness < 80 {
            sendNotification(statType: "petting", urgent: gameState.happiness < 50)
        }
    }
    
    private func checkThresholdCrossing(statType: String, oldValue: Int, newValue: Int) {
        // Check if we crossed the 80 threshold (going down)
        if oldValue >= 80 && newValue < 80 {
            sendNotification(statType: statType, urgent: false)
        }
        
        // Check if we crossed the 50 threshold (going down)
        if oldValue >= 50 && newValue < 50 {
            sendNotification(statType: statType, urgent: true)
        }
    }
    
    private func sendNotification(statType: String, urgent: Bool) {
        // Capture the name before the async closure
        let name = gameState.capybaraName
        
        // Check notification authorization
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                guard settings.authorizationStatus == .authorized else {
                    print("❌ Notifications not authorized. Status: \(settings.authorizationStatus.rawValue)")
                    print("   Please enable notifications in Settings → Capybara Rescue App → Notifications")
                    return
                }
                
                let message: String
                
                switch statType {
                case "food":
                    message = urgent ? "\(name) really needs some food" : "\(name) needs some food"
                case "drink":
                    message = urgent ? "\(name) really needs some drink" : "\(name) needs some drink"
                case "petting":
                    message = urgent ? "\(name) really needs some petting" : "\(name) needs some petting"
                default:
                    return
                }
                
                let content = UNMutableNotificationContent()
                content.title = "Capybara Alert"
                content.body = message
                content.sound = .default
                content.badge = 1
                content.categoryIdentifier = "CAPYBARA_ALERT"
                
                // Create a unique identifier for this notification
                let identifier = "\(statType)_\(urgent ? "urgent" : "normal")_\(Date().timeIntervalSince1970)"
                
                // Use a date trigger with a very short delay (1 second) to ensure it fires
                // Minimum time interval is 1 second for UNTimeIntervalNotificationTrigger
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("❌ Failed to send notification: \(error.localizedDescription)")
                    } else {
                        print("✅ Notification scheduled: \(message)")
                        print("   Identifier: \(identifier)")
                    }
                }
            }
        }
    }
    
    // MARK: - Test Notification (for debugging)
    func testNotification() {
        sendNotification(statType: "drink", urgent: false)
    }
}


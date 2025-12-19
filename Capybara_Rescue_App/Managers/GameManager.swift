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
            // Note: Notifications are now handled by scheduleFutureNotifications()
            // which schedules them in advance based on stat decay rates
        }
    }
    
    @Published var thrownItem: ThrownItem?
    @Published var showRunAwayAlert: Bool = false
    @Published var previewingAccessoryId: String? = nil // For previewing items before purchase
    @Published var toastMessage: String? = nil // For showing toast messages to user
    
    private var decayTimer: Timer?
    private let storageKey = "capybara_rescue_game_state"
    private var isSaving = false
    private let cloudStore = NSUbiquitousKeyValueStore.default
    
    struct ThrownItem: Identifiable {
        let id = UUID()
        let emoji: String
        let isFood: Bool
    }
    
    init() {
        // Initialize gameState first (required before calling any methods)
        if let data = cloudStore.data(forKey: storageKey),
           let savedState = try? JSONDecoder().decode(GameState.self, from: data) {
            self.gameState = savedState
            print("✅ Loaded game state from iCloud")
        } else {
            self.gameState = GameState.defaultState
            print("ℹ️ Using default game state (first launch or no iCloud data)")
        }
        
        // Set up iCloud sync notification observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudStoreChange(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloudStore
        )
        
        // Migrate old UserDefaults values if needed (for backward compatibility)
        migrateFromUserDefaults()
        
        // Apply time-based decay from last session
        applyOfflineDecay()
        
        // Check and update login streak
        checkDailyLogin()
        
        // Check notification permissions (will request if not determined)
        checkNotificationPermissions()
        
        // Clear badge when app opens (user has seen the app)
        clearBadge()
        
        // Schedule future notifications for when app is closed
        scheduleFutureNotifications()
        
        // Start decay timer
        startDecayTimer()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - iCloud Sync
    @objc private func handleCloudStoreChange(_ notification: Notification) {
        // Handle external changes from iCloud sync
        guard let userInfo = notification.userInfo,
              let reason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else {
            return
        }
        
        // Only reload if the change came from another device
        if reason == NSUbiquitousKeyValueStoreServerChange ||
           reason == NSUbiquitousKeyValueStoreInitialSyncChange {
            print("☁️ iCloud sync detected - reloading game state")
            loadGameState()
        }
    }
    
    private func loadGameState() {
        if let data = cloudStore.data(forKey: storageKey),
           let savedState = try? JSONDecoder().decode(GameState.self, from: data) {
            self.gameState = savedState
            print("✅ Loaded game state from iCloud")
        } else {
            self.gameState = GameState.defaultState
            print("ℹ️ Using default game state (first launch or no iCloud data)")
        }
    }
    
    private func migrateFromUserDefaults() {
        // Migrate tutorial/onboarding completion from old UserDefaults to GameState
        // This ensures backward compatibility for existing users
        if !gameState.hasCompletedOnboarding {
            let oldValue = UserDefaults.standard.bool(forKey: "has_completed_onboarding")
            if oldValue {
                gameState.hasCompletedOnboarding = true
                print("🔄 Migrated onboarding completion from UserDefaults")
            }
        }
        
        if !gameState.hasCompletedTutorial {
            let oldValue = UserDefaults.standard.bool(forKey: "has_completed_tutorial")
            if oldValue {
                gameState.hasCompletedTutorial = true
                print("🔄 Migrated tutorial completion from UserDefaults")
            }
        }
        
        // Save migrated state if we made changes
        if gameState.hasCompletedOnboarding || gameState.hasCompletedTutorial {
            saveGameState()
        }
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
        
        // Check stats streak (all stats > 50)
        checkStatsStreak()
        
        // Check for achievements
        checkAchievements()
    }
    
    private func checkStatsStreak() {
        let calendar = Calendar.current
        let now = Date()
        
        // Check if all stats are above 50
        let allStatsAbove50 = gameState.food > 50 && gameState.drink > 50 && gameState.happiness > 50
        
        if allStatsAbove50 {
            // Check if we've already checked today
            if let lastCheck = gameState.lastStatsCheckDate {
                if calendar.isDateInToday(lastCheck) {
                    // Already checked today, do nothing
                    return
                }
                
                // Check if last check was yesterday
                if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
                   calendar.isDate(lastCheck, inSameDayAs: yesterday) {
                    // Checked yesterday and all stats were > 50, continue streak
                    gameState.statsStreak += 1
                } else {
                    // Gap in checking, reset streak to 1 (today is day 1)
                    gameState.statsStreak = 1
                }
            } else {
                // First time checking - don't set streak to 1 yet
                // The streak will become 1 on the next day if stats are still above 50
                // This prevents awarding the 1-day achievement immediately on first launch
                gameState.statsStreak = 0
            }
            
            // Update last check date
            gameState.lastStatsCheckDate = now
        } else {
            // Stats not all above 50, reset streak
            gameState.statsStreak = 0
            gameState.lastStatsCheckDate = now
        }
    }
    
    private func checkAchievements() {
        let streak = gameState.statsStreak
        
        // Achievement rewards: 3 days = 600, 7 days = 700, 30 days = 800, 100 days = 900, 365 days = 1000
        let achievementRewards: [Int: (String, Int)] = [
            3: ("streak_3", 600),
            7: ("streak_7", 700),
            30: ("streak_30", 800),
            100: ("streak_100", 900),
            365: ("streak_365", 1000)
        ]
        
        // Check each achievement threshold
        // IMPORTANT: Achievements can only be earned once. If a user earns a 30-day achievement,
        // breaks their streak, and then reaches 30 days again, they will NOT receive the coins again
        // because the achievement is already in earnedAchievements.
        for (days, (achievementId, coins)) in achievementRewards.sorted(by: { $0.key < $1.key }) {
            // Only award if streak meets threshold AND achievement hasn't been earned before
            if streak >= days && !gameState.earnedAchievements.contains(achievementId) {
                gameState.earnedAchievements.insert(achievementId)
                gameState.capycoins += coins
            }
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
            cloudStore.set(data, forKey: storageKey)
            cloudStore.synchronize() // Explicitly sync to iCloud
            print("💾 Saved game state to iCloud")
        }
    }
    
    // MARK: - Decay System
    private func applyOfflineDecay() {
        // Calculate decay based on 1-hour intervals
        let hoursSinceLastUpdate = Date().timeIntervalSince(gameState.lastUpdateTime) / 3600
        let hourIntervals = Int(hoursSinceLastUpdate)
        let decayAmount = hourIntervals // 1 point per hour
        
        if decayAmount > 0 {
            gameState.food = max(0, gameState.food - decayAmount)
            gameState.drink = max(0, gameState.drink - decayAmount)
            gameState.happiness = max(0, gameState.happiness - decayAmount)
            
            checkRunAway()
        }
    }
    
    private func startDecayTimer() {
        // Decay stats every 1 hour (3600 seconds)
        decayTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
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
        
        // Reschedule future notifications based on new stat values
        scheduleFutureNotifications()
    }
    
    private func checkRunAway() {
        if gameState.food == 0 && gameState.drink == 0 && gameState.happiness == 0 {
            gameState.hasRunAway = true
            showRunAwayAlert = true
        }
    }
    
    // MARK: - Actions
    func feedCapybara(with item: FoodItem) -> Bool {
        // Check if food is already at max
        guard gameState.food < 100 else {
            showToast("CAPYBARA IS FULL 😊")
            return false
        }
        
        guard canAfford(item.cost) else { return false }
        
        gameState.capycoins -= item.cost
        
        gameState.food = min(100, gameState.food + item.foodValue)
        
        // Reschedule notifications based on new stat value
        scheduleFutureNotifications()
        
        return true
    }
    
    func giveWater(with item: DrinkItem) -> Bool {
        // Check if drink is already at max
        guard gameState.drink < 100 else {
            showToast("CAPYBARA HAS HAD ENOUGH TO DRINK 😊")
            return false
        }
        
        guard canAfford(item.cost) else { return false }
        
        gameState.capycoins -= item.cost
        
        gameState.drink = min(100, gameState.drink + item.drinkValue)
        
        // Reschedule notifications based on new stat value
        scheduleFutureNotifications()
        
        return true
    }
    
    func petCapybara() {
        gameState.happiness = min(100, gameState.happiness + 1)
        
        // Reschedule notifications based on new stat value
        scheduleFutureNotifications()
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
    
    func purchaseRemoveBannerAds() {
        // In a real app, this would integrate with StoreKit
        // For now, we'll just set the flag directly
        gameState.hasRemovedBannerAds = true
        showToast("Banner ads removed! 🎉")
    }
    
    func incrementAppOpenCount() {
        gameState.appOpenCount += 1
    }
    
    func shouldShowAdRemovalPromo() -> Bool {
        // Show every 4th time the app is opened, but only if:
        // 1. User hasn't already purchased ad removal
        // 2. App has been opened at least a few times (4, 8, 12, etc.)
        guard !gameState.hasRemovedBannerAds else { return false }
        return gameState.appOpenCount > 0 && gameState.appOpenCount % 4 == 0
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
    
    func showToast(_ message: String) {
        toastMessage = message
        
        // Clear after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.toastMessage = nil
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
    
    // MARK: - Badge Management
    private func clearBadge() {
        // Clear badge count
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("❌ Failed to clear badge: \(error.localizedDescription)")
            } else {
                print("✅ Badge cleared")
            }
        }
        
        // Also remove all delivered notifications from notification center
        // This ensures when user opens app, old notifications are cleared
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        print("✅ Cleared all delivered notifications")
    }
    
    // MARK: - Schedule Future Notifications
    func scheduleFutureNotifications() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            
            // Cancel all pending notifications first
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            
            DispatchQueue.main.async {
                let name = self.gameState.capybaraName
                let currentFood = self.gameState.food
                let currentDrink = self.gameState.drink
                let currentHappiness = self.gameState.happiness
                
                // Track which notifications we're scheduling to set badge correctly
                var scheduledNotifications: [(hours: Int, title: String, body: String, identifier: String)] = []
                
                // Calculate when each stat will hit 80 and 50 thresholds
                // Stats decay by 1 per hour
                // Only schedule notifications for future threshold crossings
                
                // Schedule food notifications
                if currentFood >= 80 {
                    let hoursUntil79 = currentFood - 79
                    scheduledNotifications.append((hoursUntil79, "Food Alert", "\(name) needs some food", "food_80"))
                } else if currentFood >= 50 {
                    let hoursUntil49 = currentFood - 49
                    scheduledNotifications.append((hoursUntil49, "Food Alert!", "\(name) really needs some food!", "food_50"))
                }
                
                // Schedule drink notifications
                if currentDrink >= 80 {
                    let hoursUntil79 = currentDrink - 79
                    scheduledNotifications.append((hoursUntil79, "Drink Alert", "\(name) needs some drink", "drink_80"))
                } else if currentDrink >= 50 {
                    let hoursUntil49 = currentDrink - 49
                    scheduledNotifications.append((hoursUntil49, "Drink Alert!", "\(name) really needs some drink!", "drink_50"))
                }
                
                // Schedule happiness notifications
                if currentHappiness >= 80 {
                    let hoursUntil79 = currentHappiness - 79
                    scheduledNotifications.append((hoursUntil79, "Happiness Alert", "\(name) needs some petting", "happiness_80"))
                } else if currentHappiness >= 50 {
                    let hoursUntil49 = currentHappiness - 49
                    scheduledNotifications.append((hoursUntil49, "Happiness Alert!", "\(name) really needs some petting!", "happiness_50"))
                }
                
                // Now schedule all notifications with badges based on their index
                for (index, notification) in scheduledNotifications.enumerated() {
                    self.scheduleNotificationAt(
                        hours: notification.hours,
                        title: notification.title,
                        body: notification.body,
                        identifier: notification.identifier,
                        badgeNumber: index + 1
                    )
                }
            }
        }
    }
    
    private func scheduleNotificationAt(hours: Int, title: String, body: String, identifier: String, badgeNumber: Int) {
        guard hours > 0 else { return }
        
        // Query current delivered notifications to calculate proper badge
        UNUserNotificationCenter.current().getDeliveredNotifications { deliveredNotifications in
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            // Set badge to current delivered count + this notification
            content.badge = NSNumber(value: deliveredNotifications.count + 1)
            
            // Schedule notification for the calculated hours from now
            let timeInterval = TimeInterval(hours * 3600) // Convert hours to seconds
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Failed to schedule notification: \(error.localizedDescription)")
                } else {
                    print("✅ Scheduled notification '\(identifier)' for \(hours) hours from now")
                }
            }
        }
    }
    
    // MARK: - Test Notification (for debugging)
    func testNotification() {
        let name = gameState.capybaraName
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                guard settings.authorizationStatus == .authorized else {
                    print("❌ Notifications not authorized. Status: \(settings.authorizationStatus.rawValue)")
                    self.showToast("Notifications not enabled!")
                    return
                }
                
                let content = UNMutableNotificationContent()
                content.title = "Test Notification 🔔"
                content.body = "This is a test! If you see this when the app is closed, notifications are working! \(name) says hi!"
                content.sound = .default
                content.badge = 1
                
                // Schedule for 5 seconds from now - gives you time to close the app
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5.0, repeats: false)
                let request = UNNotificationRequest(identifier: "test_notification", content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("❌ Failed to schedule test notification: \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            self.showToast("Failed to schedule notification")
                        }
                    } else {
                        print("✅ Test notification scheduled for 5 seconds from now")
                        DispatchQueue.main.async {
                            self.showToast("Notification scheduled! Close app to test.")
                        }
                    }
                }
            }
        }
    }
}


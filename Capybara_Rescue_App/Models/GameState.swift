import Foundation

// MARK: - Game State Model
struct GameState: Codable {
    var capybaraName: String
    var food: Int
    var drink: Int
    var happiness: Int
    var capycoins: Int
    var lastUpdateTime: Date
    var hasRunAway: Bool
    var ownedAccessories: [String]
    var equippedAccessories: [String]
    var subscriptionEndDate: Date?
    var lastLoginDate: Date?
    var loginStreak: Int
    var earnedAchievements: Set<String>
    var statsStreak: Int // Consecutive days with all stats (food, drink, happiness) > 50
    var lastStatsCheckDate: Date? // Last date we checked if all stats were > 50
    var appOpenCount: Int // Track how many times app has been opened
    var hasRemovedBannerAds: Bool // Track if user purchased ad removal
    var hasCompletedOnboarding: Bool // Track if user completed onboarding
    var hasCompletedTutorial: Bool // Track if user completed tutorial
    var hasCompletedPaywall: Bool // Track if user has seen/completed the initial paywall
    var subscriptionTier: String? // Track subscription tier (free, monthly, annual)
    var lastSubscriptionCheckDate: Date? // Track when we last checked subscription status
    var hasSeenCNY2026Popup: Bool // Track if user has seen Chinese New Year 2026 popup
    var lastWeeklyCoinsGrantDate: Date? // For Pro Weekly: last time we granted the 500 coins/week
    var lastMonthlyCoinsGrantDate: Date? // For Pro Monthly: last time we granted the 10,000 coins/month
    var lastCatchTheOrangeCompletedDate: Date? // Last calendar day user completed Catch the Orange (once per day reward)
    /// Counters for repeatable achievements (e.g. "feed" -> total feeds, "pet" -> total pets).
    var achievementCounts: [String: Int]
    /// For repeatable achievements, last milestone we granted (e.g. "feed_10" -> 30 means granted at 10, 20, 30).
    var achievementRepeatLastGranted: [String: Int]
    
    enum CodingKeys: String, CodingKey {
        case capybaraName, food, drink, happiness, capycoins, lastUpdateTime, hasRunAway
        case ownedAccessories, equippedAccessories, subscriptionEndDate
        case lastLoginDate, loginStreak, earnedAchievements, statsStreak, lastStatsCheckDate
        case appOpenCount, hasRemovedBannerAds, hasCompletedOnboarding, hasCompletedTutorial
        case hasCompletedPaywall, subscriptionTier, lastSubscriptionCheckDate, hasSeenCNY2026Popup
        case lastWeeklyCoinsGrantDate, lastMonthlyCoinsGrantDate, lastCatchTheOrangeCompletedDate
        case achievementCounts, achievementRepeatLastGranted
    }
    
    // Custom decoding for backward compatibility
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        capybaraName = try container.decode(String.self, forKey: .capybaraName)
        food = try container.decode(Int.self, forKey: .food)
        drink = try container.decode(Int.self, forKey: .drink)
        happiness = try container.decode(Int.self, forKey: .happiness)
        capycoins = try container.decode(Int.self, forKey: .capycoins)
        lastUpdateTime = try container.decode(Date.self, forKey: .lastUpdateTime)
        hasRunAway = try container.decode(Bool.self, forKey: .hasRunAway)
        ownedAccessories = try container.decode([String].self, forKey: .ownedAccessories)
        equippedAccessories = try container.decode([String].self, forKey: .equippedAccessories)
        subscriptionEndDate = try container.decodeIfPresent(Date.self, forKey: .subscriptionEndDate)
        lastLoginDate = try container.decodeIfPresent(Date.self, forKey: .lastLoginDate)
        loginStreak = try container.decodeIfPresent(Int.self, forKey: .loginStreak) ?? 0
        statsStreak = try container.decodeIfPresent(Int.self, forKey: .statsStreak) ?? 0
        lastStatsCheckDate = try container.decodeIfPresent(Date.self, forKey: .lastStatsCheckDate)
        appOpenCount = try container.decodeIfPresent(Int.self, forKey: .appOpenCount) ?? 0
        hasRemovedBannerAds = try container.decodeIfPresent(Bool.self, forKey: .hasRemovedBannerAds) ?? false
        hasCompletedOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? false
        hasCompletedTutorial = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedTutorial) ?? false
        hasCompletedPaywall = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedPaywall) ?? false
        subscriptionTier = try container.decodeIfPresent(String.self, forKey: .subscriptionTier)
        lastSubscriptionCheckDate = try container.decodeIfPresent(Date.self, forKey: .lastSubscriptionCheckDate)
        hasSeenCNY2026Popup = try container.decodeIfPresent(Bool.self, forKey: .hasSeenCNY2026Popup) ?? false
        lastWeeklyCoinsGrantDate = try container.decodeIfPresent(Date.self, forKey: .lastWeeklyCoinsGrantDate)
        lastMonthlyCoinsGrantDate = try container.decodeIfPresent(Date.self, forKey: .lastMonthlyCoinsGrantDate)
        lastCatchTheOrangeCompletedDate = try container.decodeIfPresent(Date.self, forKey: .lastCatchTheOrangeCompletedDate)
        achievementCounts = try container.decodeIfPresent([String: Int].self, forKey: .achievementCounts) ?? [:]
        achievementRepeatLastGranted = try container.decodeIfPresent([String: Int].self, forKey: .achievementRepeatLastGranted) ?? [:]
        // Backward compatibility: try earnedAchievements first, then fall back to earnedMedals
        if let achievements = try container.decodeIfPresent(Set<String>.self, forKey: .earnedAchievements) {
            earnedAchievements = achievements
        } else {
            // Try to decode from old "earnedMedals" key for backward compatibility
            let allKeys = container.allKeys
            if let medalsKey = allKeys.first(where: { $0.stringValue == "earnedMedals" }) {
                earnedAchievements = try container.decodeIfPresent(Set<String>.self, forKey: medalsKey) ?? []
            } else {
                earnedAchievements = []
            }
        }
    }
    
    // Custom encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(capybaraName, forKey: .capybaraName)
        try container.encode(food, forKey: .food)
        try container.encode(drink, forKey: .drink)
        try container.encode(happiness, forKey: .happiness)
        try container.encode(capycoins, forKey: .capycoins)
        try container.encode(lastUpdateTime, forKey: .lastUpdateTime)
        try container.encode(hasRunAway, forKey: .hasRunAway)
        try container.encode(ownedAccessories, forKey: .ownedAccessories)
        try container.encode(equippedAccessories, forKey: .equippedAccessories)
        try container.encodeIfPresent(subscriptionEndDate, forKey: .subscriptionEndDate)
        try container.encodeIfPresent(lastLoginDate, forKey: .lastLoginDate)
        try container.encode(loginStreak, forKey: .loginStreak)
        try container.encode(earnedAchievements, forKey: .earnedAchievements)
        try container.encode(statsStreak, forKey: .statsStreak)
        try container.encodeIfPresent(lastStatsCheckDate, forKey: .lastStatsCheckDate)
        try container.encode(appOpenCount, forKey: .appOpenCount)
        try container.encode(hasRemovedBannerAds, forKey: .hasRemovedBannerAds)
        try container.encode(hasCompletedOnboarding, forKey: .hasCompletedOnboarding)
        try container.encode(hasCompletedTutorial, forKey: .hasCompletedTutorial)
        try container.encode(hasCompletedPaywall, forKey: .hasCompletedPaywall)
        try container.encodeIfPresent(subscriptionTier, forKey: .subscriptionTier)
        try container.encodeIfPresent(lastSubscriptionCheckDate, forKey: .lastSubscriptionCheckDate)
        try container.encode(hasSeenCNY2026Popup, forKey: .hasSeenCNY2026Popup)
        try container.encodeIfPresent(lastWeeklyCoinsGrantDate, forKey: .lastWeeklyCoinsGrantDate)
        try container.encodeIfPresent(lastMonthlyCoinsGrantDate, forKey: .lastMonthlyCoinsGrantDate)
        try container.encodeIfPresent(lastCatchTheOrangeCompletedDate, forKey: .lastCatchTheOrangeCompletedDate)
        try container.encode(achievementCounts, forKey: .achievementCounts)
        try container.encode(achievementRepeatLastGranted, forKey: .achievementRepeatLastGranted)
    }
    
    // Manual initializer for default state
    init(
        capybaraName: String,
        food: Int,
        drink: Int,
        happiness: Int,
        capycoins: Int,
        lastUpdateTime: Date,
        hasRunAway: Bool,
        ownedAccessories: [String],
        equippedAccessories: [String],
        subscriptionEndDate: Date?,
        lastLoginDate: Date?,
        loginStreak: Int,
        earnedAchievements: Set<String>,
        statsStreak: Int,
        lastStatsCheckDate: Date?,
        appOpenCount: Int,
        hasRemovedBannerAds: Bool,
        hasCompletedOnboarding: Bool,
        hasCompletedTutorial: Bool,
        hasCompletedPaywall: Bool,
        subscriptionTier: String?,
        lastSubscriptionCheckDate: Date?,
        hasSeenCNY2026Popup: Bool,
        lastWeeklyCoinsGrantDate: Date?,
        lastMonthlyCoinsGrantDate: Date?,
        lastCatchTheOrangeCompletedDate: Date?,
        achievementCounts: [String: Int] = [:],
        achievementRepeatLastGranted: [String: Int] = [:]
    ) {
        self.capybaraName = capybaraName
        self.food = food
        self.drink = drink
        self.happiness = happiness
        self.capycoins = capycoins
        self.lastUpdateTime = lastUpdateTime
        self.hasRunAway = hasRunAway
        self.ownedAccessories = ownedAccessories
        self.equippedAccessories = equippedAccessories
        self.subscriptionEndDate = subscriptionEndDate
        self.lastLoginDate = lastLoginDate
        self.loginStreak = loginStreak
        self.earnedAchievements = earnedAchievements
        self.statsStreak = statsStreak
        self.lastStatsCheckDate = lastStatsCheckDate
        self.appOpenCount = appOpenCount
        self.hasRemovedBannerAds = hasRemovedBannerAds
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.hasCompletedTutorial = hasCompletedTutorial
        self.hasCompletedPaywall = hasCompletedPaywall
        self.subscriptionTier = subscriptionTier
        self.lastSubscriptionCheckDate = lastSubscriptionCheckDate
        self.hasSeenCNY2026Popup = hasSeenCNY2026Popup
        self.lastWeeklyCoinsGrantDate = lastWeeklyCoinsGrantDate
        self.lastMonthlyCoinsGrantDate = lastMonthlyCoinsGrantDate
        self.lastCatchTheOrangeCompletedDate = lastCatchTheOrangeCompletedDate
        self.achievementCounts = achievementCounts
        self.achievementRepeatLastGranted = achievementRepeatLastGranted
    }
    
    static let defaultState = GameState(
        capybaraName: "Cappuccino",
        food: 60,
        drink: 60,
        happiness: 60,
        capycoins: 0,
        lastUpdateTime: Date(),
        hasRunAway: false,
        ownedAccessories: [],
        equippedAccessories: [],
        subscriptionEndDate: nil as Date?,
        lastLoginDate: nil as Date?,
        loginStreak: 0,
        earnedAchievements: [],
        statsStreak: 0,
        lastStatsCheckDate: nil as Date?,
        appOpenCount: 0,
        hasRemovedBannerAds: false,
        hasCompletedOnboarding: false,
        hasCompletedTutorial: false,
        hasCompletedPaywall: false,
        subscriptionTier: nil,
        lastSubscriptionCheckDate: nil,
        hasSeenCNY2026Popup: false,
        lastWeeklyCoinsGrantDate: nil,
        lastMonthlyCoinsGrantDate: nil,
        lastCatchTheOrangeCompletedDate: nil
    )
    
    var hasActiveSubscription: Bool {
        guard let endDate = subscriptionEndDate else { return false }
        return endDate > Date()
    }
    
    var capybaraEmotion: CapybaraEmotion {
        if happiness >= 80 {
            return .happy
        } else if happiness >= 50 {
            return .neutral
        } else {
            return .sad
        }
    }
}

// MARK: - Capybara Emotion
enum CapybaraEmotion: String, Codable {
    case happy
    case neutral
    case sad
}

// MARK: - Food Item
struct FoodItem: Identifiable, Equatable {
    let id = UUID()
    let emoji: String
    let name: String
    let foodValue: Int
    let cost: Int
    
    static let allItems: [FoodItem] = [
        FoodItem(emoji: "🌿", name: "Grass", foodValue: 1, cost: 1),
        FoodItem(emoji: "🥬", name: "Lettuce", foodValue: 4, cost: 2),
        FoodItem(emoji: "🥕", name: "Carrot", foodValue: 9, cost: 3),
        FoodItem(emoji: "🍎", name: "Apple", foodValue: 16, cost: 4),
        FoodItem(emoji: "🍉", name: "Watermelon", foodValue: 25, cost: 5),
        FoodItem(emoji: "🌽", name: "Corn", foodValue: 36, cost: 6),
        FoodItem(emoji: "🥒", name: "Cucumber", foodValue: 49, cost: 7),
        FoodItem(emoji: "🍇", name: "Grapes", foodValue: 64, cost: 8),
        FoodItem(emoji: "🥠", name: "Fortune Cookie", foodValue: 81, cost: 9)
    ]
}

// MARK: - Drink Item
struct DrinkItem: Identifiable, Equatable {
    let id = UUID()
    let emoji: String
    let name: String
    let drinkValue: Int
    let cost: Int
    
    static let allItems: [DrinkItem] = [
        DrinkItem(emoji: "💧", name: "Water", drinkValue: 1, cost: 1),
        DrinkItem(emoji: "🥛", name: "Milk", drinkValue: 4, cost: 2),
        DrinkItem(emoji: "🧃", name: "Juice Box", drinkValue: 9, cost: 3),
        DrinkItem(emoji: "🥥", name: "Coconut Water", drinkValue: 16, cost: 4),
        DrinkItem(emoji: "🍵", name: "Matcha Tea", drinkValue: 25, cost: 5),
        DrinkItem(emoji: "🧋", name: "Bubble Tea", drinkValue: 36, cost: 6),
        DrinkItem(emoji: "🍹", name: "Fruit Smoothie", drinkValue: 49, cost: 7),
        DrinkItem(emoji: "🫖", name: "Jasmine Tea", drinkValue: 64, cost: 8)
    ]
}

// MARK: - Accessory Item
struct AccessoryItem: Identifiable, Equatable {
    let id: String
    let emoji: String
    let name: String
    let category: AccessoryCategory
    let cost: Int
    let modelFileName: String? // USDZ filename for 3D accessories
    let isProOnly: Bool // Pro subscription required
    
    enum AccessoryCategory: String, CaseIterable, Codable {
        case gardenItems = ""
    }
    
    // Check if this item is a hat (only one hat can be equipped at a time)
    var isHat: Bool {
        guard !id.isEmpty else { return false }
        guard modelFileName != nil else { return false }
        
        let hatIds: Set<String> = [
            "baseballcap",
            "cowboyhat",
            "tophat",
            "wizardhat",
            "piratehat",
            "propellerhat",
            "sombrerohat",
            "froghat",
            "foxhat",
            "santahat",
            "cone",
            "pizzahat",
            "redlantern"
        ]
        
        return hatIds.contains(id)
    }
    
    private static let _allItems: [AccessoryItem] = [
        // Regular Hats
        AccessoryItem(id: "baseballcap", emoji: "🧢", name: "Baseball cap", category: .gardenItems, cost: 300, modelFileName: "Baseball cap", isProOnly: false),
        AccessoryItem(id: "cowboyhat", emoji: "🤠", name: "Cowboy hat", category: .gardenItems, cost: 1200, modelFileName: "Cowboy Hat 2", isProOnly: false),
        AccessoryItem(id: "tophat", emoji: "🎩", name: "Top hat", category: .gardenItems, cost: 3000, modelFileName: "Tophat", isProOnly: false),
        AccessoryItem(id: "wizardhat", emoji: "🧙", name: "Wizard hat", category: .gardenItems, cost: 7500, modelFileName: "Wizard hat", isProOnly: false),
        AccessoryItem(id: "piratehat", emoji: "🏴‍☠️", name: "Pirate hat", category: .gardenItems, cost: 12000, modelFileName: "Pirate hat", isProOnly: false),
        AccessoryItem(id: "propellerhat", emoji: "🪁", name: "Propeller hat", category: .gardenItems, cost: 19500, modelFileName: "Propeller hat", isProOnly: false),
        AccessoryItem(id: "sombrerohat", emoji: "🪶", name: "Sombrero", category: .gardenItems, cost: 30000, modelFileName: "Sombrero2hat", isProOnly: false),
        AccessoryItem(id: "froghat", emoji: "🐸", name: "Frog Hat", category: .gardenItems, cost: 60000, modelFileName: "Frog Hat", isProOnly: false),
        AccessoryItem(id: "foxhat", emoji: "🦊", name: "Fox Hat", category: .gardenItems, cost: 45000, modelFileName: "Fox Hat", isProOnly: false),
        AccessoryItem(id: "santahat", emoji: "🎅", name: "Santa Hat", category: .gardenItems, cost: 75000, modelFileName: "Santahat", isProOnly: false),
        // Premium Hats (formerly Pro-only, now purchasable with coins)
        AccessoryItem(id: "cone", emoji: "🚦", name: "Cone", category: .gardenItems, cost: 90000, modelFileName: "Cone", isProOnly: false),
        AccessoryItem(id: "pizzahat", emoji: "🍕", name: "Pizza Hat", category: .gardenItems, cost: 105000, modelFileName: "Pizza Hat", isProOnly: false),
        AccessoryItem(id: "redlantern", emoji: "🏮", name: "Red Lantern", category: .gardenItems, cost: 120000, modelFileName: "red-lantern", isProOnly: false),
    ]
    
    static var allItems: [AccessoryItem] {
        return _allItems
    }
}

// MARK: - Coin Pack
struct CoinPack: Identifiable {
    let id = UUID()
    let name: String
    let coins: Int
    let productId: String
    let price: String
    let description: String
    let badge: String? // Optional badge like "BEST VALUE" or "POPULAR"
    
    static let packs: [CoinPack] = [
        CoinPack(
            name: "Ultra Pack",
            coins: 25000,
            productId: "coins_25000",
            price: "£99.99",
            description: "Maximum coins for serious players",
            badge: nil
        ),
        CoinPack(
            name: "Mega Pack",
            coins: 10000,
            productId: "coins_10000",
            price: "£49.99",
            description: "Best value - save 33%",
            badge: nil
        ),
        CoinPack(
            name: "Super Pack",
            coins: 1500,
            productId: "coins_1500",
            price: "£9.99",
            description: "Great value for regular players",
            badge: nil
        ),
        CoinPack(
            name: "Starter Pack",
            coins: 500,
            productId: "coins_500",
            price: "£4.99",
            description: "Perfect for trying out new items",
            badge: nil
        ),
        CoinPack(
            name: "Mini Pack",
            coins: 50,
            productId: "coins_50",
            price: "£0.99",
            description: "Small pack to get started",
            badge: nil
        )
    ]
    
    // Calculate coins per pound for value comparison
    var coinsPerPound: Double {
        let priceValue = Double(price.replacingOccurrences(of: "£", with: "")) ?? 1.0
        return Double(coins) / priceValue
    }
    
    // Calculate savings percentage compared to starter pack
    var savingsComparedToStarter: String? {
        guard let starterPack = CoinPack.packs.last else { return nil } // Starter pack is now last
        guard coins > starterPack.coins else { return nil }
        
        let starterPrice = Double(starterPack.price.replacingOccurrences(of: "£", with: "")) ?? 0
        let currentPrice = Double(price.replacingOccurrences(of: "£", with: "")) ?? 0
        
        // Calculate equivalent cost if buying multiple starter packs
        let packsEquivalent = Double(coins) / Double(starterPack.coins)
        let equivalentCost = starterPrice * packsEquivalent
        let savings = equivalentCost - currentPrice
        
        guard savings > 0, equivalentCost > 0 else { return nil }
        
        // Calculate percentage savings
        let percentage = (savings / equivalentCost) * 100
        let roundedPercentage = Int(percentage.rounded())
        
        return "Save \(roundedPercentage)%"
    }
}

// MARK: - Menu Tab
enum MenuTab: String, CaseIterable {
    case food = "Food"
    case drink = "Drink"
    case items = "Items"
    case shop = "Shop"
    
    var localizedTitle: String {
        switch self {
        case .food: return L("menu.food")
        case .drink: return L("menu.drink")
        case .items: return L("menu.items")
        case .shop: return L("menu.shop")
        }
    }
    
    var localizedSubtitle: String {
        switch self {
        case .food: return L("menu.foodSubtitle")
        case .drink: return L("menu.drinkSubtitle")
        case .items: return L("menu.itemsSubtitle")
        case .shop: return L("menu.shopSubtitle")
        }
    }
    
    var icon: String {
        switch self {
        case .food: return "leaf.fill"
        case .drink: return "drop.fill"
        case .items: return "tshirt.fill"
        case .shop: return "cart.fill"
        }
    }
}

// MARK: - Date Extension for Chinese New Year Event
extension Date {
    // Check if it's during the CNY event (for popup, background, badges)
    static func isChineseNewYearEvent2026() -> Bool {
        let now = Date()
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "GMT")!
        
        // Start: Friday 13 February 2026 — 10:00 AM GMT
        var startComponents = DateComponents()
        startComponents.year = 2026
        startComponents.month = 2
        startComponents.day = 13
        startComponents.hour = 10
        startComponents.minute = 0
        startComponents.timeZone = TimeZone(identifier: "GMT")
        
        // End: Tuesday 24 February 2026 — 10:00 AM GMT
        var endComponents = DateComponents()
        endComponents.year = 2026
        endComponents.month = 2
        endComponents.day = 24
        endComponents.hour = 10
        endComponents.minute = 0
        endComponents.timeZone = TimeZone(identifier: "GMT")
        
        guard let startDate = calendar.date(from: startComponents),
              let endDate = calendar.date(from: endComponents) else {
            return false
        }
        
        return now >= startDate && now < endDate
    }
    
    // Check if CNY items should be visible (from Feb 13 onwards, forever)
    static func shouldShowCNYItems2026() -> Bool {
        let now = Date()
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "GMT")!
        
        // Items appear starting Friday 13 February 2026 — 10:00 AM GMT
        var startComponents = DateComponents()
        startComponents.year = 2026
        startComponents.month = 2
        startComponents.day = 13
        startComponents.hour = 10
        startComponents.minute = 0
        startComponents.timeZone = TimeZone(identifier: "GMT")
        
        guard let startDate = calendar.date(from: startComponents) else {
            return false
        }
        
        // Show items from start date onwards (no end date)
        return now >= startDate
    }
}
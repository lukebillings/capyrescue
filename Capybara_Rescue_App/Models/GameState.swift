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
    var earnedMedals: Set<String>
    
    enum CodingKeys: String, CodingKey {
        case capybaraName, food, drink, happiness, capycoins, lastUpdateTime, hasRunAway
        case ownedAccessories, equippedAccessories, subscriptionEndDate
        case lastLoginDate, loginStreak, earnedMedals
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
        earnedMedals = try container.decodeIfPresent(Set<String>.self, forKey: .earnedMedals) ?? []
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
        try container.encode(earnedMedals, forKey: .earnedMedals)
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
        earnedMedals: Set<String>
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
        self.earnedMedals = earnedMedals
    }
    
    static let defaultState = GameState(
        capybaraName: "Cappuccino",
        food: 50,
        drink: 50,
        happiness: 50,
        capycoins: 100,
        lastUpdateTime: Date(),
        hasRunAway: false,
        ownedAccessories: [],
        equippedAccessories: [],
        subscriptionEndDate: nil as Date?,
        lastLoginDate: nil as Date?,
        loginStreak: 0,
        earnedMedals: []
    )
    
    var hasActiveSubscription: Bool {
        guard let endDate = subscriptionEndDate else { return false }
        return endDate > Date()
    }
    
    var capybaraEmotion: CapybaraEmotion {
        if happiness > 80 {
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
        FoodItem(emoji: "🍇", name: "Grapes", foodValue: 64, cost: 8)
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
        DrinkItem(emoji: "🍹", name: "Fruit Smoothie", drinkValue: 49, cost: 7)
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
    
    enum AccessoryCategory: String, CaseIterable, Codable {
        case gardenItems = ""
    }
    
    static let allItems: [AccessoryItem] = [
        // Garden Items
        AccessoryItem(id: "tophat", emoji: "🎩", name: "Top Hat", category: .gardenItems, cost: 400, modelFileName: "Tophat"), // Loads Tophat.usdz
        AccessoryItem(id: "santahat", emoji: "🎅", name: "Santa Hat", category: .gardenItems, cost: 10000, modelFileName: "Santahat"), // Loads Santahat.usdz
        AccessoryItem(id: "sombrerohat", emoji: "🪶", name: "Sombrero", category: .gardenItems, cost: 4000, modelFileName: "Sombrero2hat"), // Loads Sombrero2hat.usdz
    ]
}

// MARK: - Coin Pack
struct CoinPack: Identifiable {
    let id = UUID()
    let name: String
    let coins: Int
    let price: String
    let description: String
    let badge: String? // Optional badge like "BEST VALUE" or "POPULAR"
    
    static let packs: [CoinPack] = [
        CoinPack(
            name: "Ultra Pack",
            coins: 10000,
            price: "£100",
            description: "Maximum coins for serious players",
            badge: nil
        ),
        CoinPack(
            name: "Mega Pack",
            coins: 4000,
            price: "£50",
            description: "Best value - save 33%",
            badge: nil
        ),
        CoinPack(
            name: "Super Pack",
            coins: 400,
            price: "£10",
            description: "Great value for regular players",
            badge: nil
        ),
        CoinPack(
            name: "Starter Pack",
            coins: 100,
            price: "£5",
            description: "Perfect for trying out new items",
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
    
    var icon: String {
        switch self {
        case .food: return "leaf.fill"
        case .drink: return "drop.fill"
        case .items: return "tshirt.fill"
        case .shop: return "cart.fill"
        }
    }
}


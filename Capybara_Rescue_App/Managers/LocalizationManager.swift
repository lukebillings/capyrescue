import SwiftUI

// MARK: - Localization Manager
/// Manages app language and provides translated strings.
/// When adding new user-facing text, add the key to ALL files in Localizable/ (see LOCALIZATION.md).
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    private let defaults = UserDefaults.standard
    private let languageKey = "app_language_code"
    
    /// Supported language codes (English + 10 languages)
    static let supportedLanguages: [(code: String, displayName: String)] = [
        ("en", "English"),
        ("tr", "Türkçe"),
        ("es-MX", "Español (México)"),
        ("pt-BR", "Português (Brasil)"),
        ("zh-Hant", "繁體中文"),
        ("ja", "日本語"),
        ("hi", "हिन्दी"),
        ("ar", "العربية"),
        ("id", "Bahasa Indonesia"),
        ("ko", "한국어"),
        ("ms", "Bahasa Melayu")
    ]
    
    @Published var currentLanguage: String {
        didSet {
            defaults.set(currentLanguage, forKey: languageKey)
            loadTranslations()
        }
    }
    
    private var translations: [String: String] = [:]
    private var fallbackTranslations: [String: String] = [:]
    
    private init() {
        self.currentLanguage = defaults.string(forKey: languageKey) ?? "en"
        loadTranslations()
    }
    
    private func loadTranslations() {
        translations = loadLanguage(currentLanguage) ?? [:]
        if currentLanguage != "en" {
            fallbackTranslations = loadLanguage("en") ?? [:]
        } else {
            fallbackTranslations = [:]
        }
    }
    
    private func loadLanguage(_ code: String) -> [String: String]? {
        let candidateURLs: [URL?] = [
            // Preferred: json files inside a "Localizable" folder in the bundle.
            Bundle.main.url(forResource: code, withExtension: "json", subdirectory: "Localizable"),
            // Common in Xcode targets: json files copied to the bundle root.
            Bundle.main.url(forResource: code, withExtension: "json")
        ]
        
        for candidateURL in candidateURLs {
            guard let url = candidateURL,
                  let data = try? Data(contentsOf: url),
                  let dict = try? JSONDecoder().decode([String: String].self, from: data) else {
                continue
            }
            return dict
        }
        
        // Last-resort lookup if the file ended up nested unexpectedly in bundle resources.
        guard let resourceURL = Bundle.main.resourceURL else { return nil }
        let fallbackURL = resourceURL.appendingPathComponent("Localizable/\(code).json")
        guard let data = try? Data(contentsOf: fallbackURL),
              let dict = try? JSONDecoder().decode([String: String].self, from: data) else {
            return nil
        }
        
        return dict
    }
    
    /// Returns localized string for key. Falls back to English if missing.
    func string(for key: String) -> String {
        if let value = translations[key], !value.isEmpty {
            return value
        }
        if let fallback = fallbackTranslations[key], !fallback.isEmpty {
            return fallback
        }
        return key
    }
}

// MARK: - L() Helper
/// Use L("key") for localized strings. Add new keys to all Localizable/*.json files.
func L(_ key: String) -> String {
    LocalizationManager.shared.string(for: key)
}

// MARK: - Item Name Localization
/// Maps FoodItem name to localization key (e.g. "Grass" -> "food.grass")
func localizedFoodName(_ name: String) -> String {
    let key: String
    switch name {
    case "Grass": key = "food.grass"
    case "Lettuce": key = "food.lettuce"
    case "Carrot": key = "food.carrot"
    case "Apple": key = "food.apple"
    case "Watermelon": key = "food.watermelon"
    case "Corn": key = "food.corn"
    case "Cucumber": key = "food.cucumber"
    case "Grapes": key = "food.grapes"
    case "Fortune Cookie": key = "food.fortunecookie"
    default: return name
    }
    return L(key)
}

/// Maps DrinkItem name to localization key
func localizedDrinkName(_ name: String) -> String {
    let key: String
    switch name {
    case "Water": key = "drink.water"
    case "Milk": key = "drink.milk"
    case "Juice Box": key = "drink.juicebox"
    case "Coconut Water": key = "drink.coconutwater"
    case "Matcha Tea": key = "drink.matchatea"
    case "Bubble Tea": key = "drink.bubbletea"
    case "Fruit Smoothie": key = "drink.fruitsmoothie"
    case "Jasmine Tea": key = "drink.jasminetea"
    default: return name
    }
    return L(key)
}

/// Maps AccessoryItem id to localization key (e.g. "baseballcap" -> "item.baseballcap")
func localizedAccessoryName(id: String) -> String {
    let key = id == "sombrerohat" ? "item.sombrero" : "item.\(id)"
    return L(key)
}

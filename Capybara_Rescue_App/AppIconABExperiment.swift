import UIKit

/// Persists a 50/50 assignment and applies the matching home-screen icon (primary `AppIcon` vs alternate `AppIcon2`).
enum AppIconABExperiment {
    static let userDefaultsKey = "capyrescue.appIconABVariant"
    /// Alternate icon set name in Assets.xcassets; must match `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES`.
    static let alternateIconAssetName = "AppIcon2"

    enum Variant: String {
        case primary
        case alternate
    }

    /// Resolved variant for this install; assign once on first access.
    static var assignedVariant: Variant {
        let defaults = UserDefaults.standard
        if let raw = defaults.string(forKey: userDefaultsKey),
           let variant = Variant(rawValue: raw) {
            return variant
        }
        let variant: Variant = Bool.random() ? .alternate : .primary
        defaults.set(variant.rawValue, forKey: userDefaultsKey)
        return variant
    }

    /// Call once from `application(_:didFinishLaunchingWithOptions:)` on the main thread.
    static func applyAssignedVariantIfNeeded() {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        let name: String? = assignedVariant == .alternate ? alternateIconAssetName : nil
        UIApplication.shared.setAlternateIconName(name, completionHandler: nil)
    }
}

import Foundation

/// Central switch for enabling/disabling AdMob at runtime.
///
/// Default behavior:
/// - Debug builds: disabled (so local testing isn't blocked by AdMob loading)
/// - Release builds: enabled
enum AdsConfig {
    #if DEBUG
    static let adsEnabled = false
    #else
    static let adsEnabled = true
    #endif
}


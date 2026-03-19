import Foundation

/// Central switch for enabling/disabling AdMob at runtime.
///
/// Default behavior:
/// - Debug builds: enabled (uses Google-provided *test* ad unit IDs)
/// - Release builds: enabled
enum AdsConfig {
    /// Returns true when running inside SwiftUI Preview / Xcode Canvas.
    ///
    /// Canvas runs code in a special preview environment; we never want AdMob to load there.
    static var isRunningForPreviews: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    /// Ads are disabled - no banner or rewarded ads in the app.
    static var adsEnabled: Bool { false }

    static var bannerAdsEnabled: Bool { false }

    /// Use Google-provided test ad unit IDs in Debug builds.
    ///
    /// This avoids generating invalid traffic while testing locally.
    static var useTestAdUnits: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}


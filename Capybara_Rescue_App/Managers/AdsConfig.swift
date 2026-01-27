import Foundation

/// Central switch for enabling/disabling AdMob at runtime.
///
/// Default behavior:
/// - Debug builds: disabled (so local testing isn't blocked by AdMob loading)
/// - Release builds: enabled
enum AdsConfig {
    /// Returns true when running inside SwiftUI Preview / Xcode Canvas.
    ///
    /// Canvas runs code in a special preview environment; we never want AdMob to load there.
    static var isRunningForPreviews: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    static var adsEnabled: Bool {
        // Never allow ads in SwiftUI Canvas/Previews (even if you enable ads for debugging).
        if isRunningForPreviews { return false }
        
        // Globally disabled per current build requirements.
        // Flip this back to `true` when you want AdMob active again.
        return false
    }

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


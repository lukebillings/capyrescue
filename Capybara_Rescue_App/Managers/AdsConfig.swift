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

        #if DEBUG
        return false
        #else
        return true
        #endif
    }
}


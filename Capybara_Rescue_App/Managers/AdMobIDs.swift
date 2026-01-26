import Foundation

/// Central place for AdMob identifiers.
///
/// - Note:
///   - **App ID** uses `~` and belongs in `Info.plist` under `GADApplicationIdentifier`.
///   - **Ad Unit IDs** use `/` and are used in code for banner/rewarded/interstitial loads.
struct AdMobIDs {
    /// Google-provided *test* banner ad unit ID.
    private static let testBanner = "ca-app-pub-3940256099942544/2435281174"
    /// Google-provided *test* rewarded ad unit ID.
    private static let testRewarded = "ca-app-pub-3940256099942544/1712485313"

    /// Your production banner ad unit ID from AdMob (must contain `/`).
    ///
    /// Replace this when you create the real ad unit in AdMob.
    private static let productionBanner: String? = "ca-app-pub-4955072757491395/4324533943"

    /// Your production rewarded ad unit ID from AdMob (must contain `/`).
    ///
    /// Replace this when you create the real ad unit in AdMob.
    private static let productionRewarded: String? = "ca-app-pub-4955072757491395/8048350052"

    static var bannerTop: String {
        let id: String
        if AdsConfig.useTestAdUnits {
            id = testBanner
        } else {
            id = productionBanner ?? testBanner
        }
        assert(id.contains("/"), "Banner Ad Unit ID must contain '/'. Did you paste the App ID (~) by mistake?")
        return id
    }

    static var rewardedFreeCoins: String {
        let id: String
        if AdsConfig.useTestAdUnits {
            id = testRewarded
        } else {
            id = productionRewarded ?? testRewarded
        }
        assert(id.contains("/"), "Rewarded Ad Unit ID must contain '/'. Did you paste the App ID (~) by mistake?")
        return id
    }

    // MARK: - Test devices (development only)
    //
    // To prevent AdMob counting your own testing as real traffic, add your device as a test device.
    // 1) Run the app on your iPhone from Xcode.
    // 2) In the Xcode console, Google Mobile Ads will print a message containing your test device ID.
    // 3) Paste that ID below.
    //
    // Example: ["abcdef0123456789abcdef0123456789"]
    static let testDeviceIdentifiers: [String] = []
}


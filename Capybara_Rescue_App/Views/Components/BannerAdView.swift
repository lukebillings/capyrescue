import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    typealias UIViewType = BannerView
    let adUnitID: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: AdSizeBanner)
        guard AdsConfig.bannerAdsEnabled else {
            // Ads disabled (e.g. during local testing) — don't configure/load AdMob.
            return bannerView
        }
        bannerView.adUnitID = adUnitID
        bannerView.delegate = context.coordinator
        context.coordinator.bannerView = bannerView
        
        // Try to set root view controller immediately
        setRootViewController(for: bannerView)
        
        // Try to load ad after a short delay to ensure SDK is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.attemptLoadAd(for: bannerView, coordinator: context.coordinator)
        }
        
        return bannerView
    }
    
    func updateUIView(_ uiView: BannerView, context: Context) {
        guard AdsConfig.bannerAdsEnabled else { return }
        // Set root view controller if not already set
        if uiView.rootViewController == nil {
            setRootViewController(for: uiView)
        }
        
        // Try to load ad if conditions are met
        attemptLoadAd(for: uiView, coordinator: context.coordinator)
    }
    
    private func attemptLoadAd(for bannerView: BannerView, coordinator: Coordinator) {
        guard AdsConfig.bannerAdsEnabled else { return }
        // Ensure root view controller is set
        if bannerView.rootViewController == nil {
            setRootViewController(for: bannerView)
        }
        
        // Load ad if we have root view controller and haven't loaded yet
        if bannerView.rootViewController != nil && !coordinator.hasLoaded {
            print("🔄 Loading banner ad with ID: \(adUnitID)")
            let request = Request()
            bannerView.load(request)
            coordinator.hasLoaded = true
        } else if bannerView.rootViewController == nil {
            print("⚠️ Root view controller not available for banner ad")
        } else if coordinator.hasLoaded {
            print("ℹ️ Banner ad already loaded")
        }
    }
    
    private func setRootViewController(for bannerView: BannerView) {
        guard bannerView.rootViewController == nil else { return }
        
        // Safely get root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            print("⚠️ No window scene available")
            return
        }
        
        // Try key window first, then any window
        if let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            bannerView.rootViewController = rootViewController
            print("✅ Set root view controller from key window")
        } else if let rootViewController = windowScene.windows.first?.rootViewController {
            bannerView.rootViewController = rootViewController
            print("✅ Set root view controller from first window")
        } else {
            print("⚠️ No root view controller found")
        }
    }
    
    class Coordinator: NSObject, BannerViewDelegate {
        weak var bannerView: BannerView?
        var hasLoaded = false
        
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("✅ Banner ad loaded successfully")
        }
        
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("❌ Banner ad failed to load: \(error.localizedDescription)")
            // Reset hasLoaded so we can try again
            hasLoaded = false
        }
    }
}

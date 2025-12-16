import Foundation
import SwiftUI
import GoogleMobileAds

@MainActor
class RewardedAdViewModel: NSObject, ObservableObject, FullScreenContentDelegate {
    @Published var isLoading = false
    @Published var isAdReady = false
    @Published var isShowingAd = false
    
    private var rewardedAd: RewardedAd?
    private let adUnitID = "ca-app-pub-3940256099942544/1712485313"
    
    var onRewardEarned: (() -> Void)?
    
    override init() {
        super.init()
        loadAd()
    }
    
    func loadAd() {
        guard !isLoading else { return }
        
        isLoading = true
        isAdReady = false
        
        Task {
            do {
                rewardedAd = try await RewardedAd.load(
                    with: adUnitID,
                    request: Request()
                )
                rewardedAd?.fullScreenContentDelegate = self
                isLoading = false
                isAdReady = true
                print("✅ Rewarded ad loaded successfully")
            } catch {
                isLoading = false
                isAdReady = false
                print("❌ Rewarded ad failed to load: \(error.localizedDescription)")
            }
        }
    }
    
    func showAd(from rootViewController: UIViewController? = nil) {
        guard let rewardedAd = rewardedAd else {
            print("⚠️ Rewarded ad not ready")
            // Try to reload if ad is not ready
            loadAd()
            return
        }
        
        guard !isShowingAd else {
            print("⚠️ Ad is already showing")
            return
        }
        
        // Get root view controller if not provided
        let viewController = rootViewController ?? getRootViewController()
        guard let viewController = viewController else {
            print("❌ Could not get root view controller")
            return
        }
        
        isShowingAd = true
        
        rewardedAd.present(from: viewController) { [weak self] in
            guard let self = self else { return }
            
            let reward = rewardedAd.adReward
            print("✅ Reward earned: \(reward.amount) \(reward.type)")
            
            // Call the reward handler
            self.onRewardEarned?()
            
            // Clear the ad after use (ads are one-time use)
            self.rewardedAd = nil
            self.isAdReady = false
            
            // Reload a new ad for next time
            self.loadAd()
        }
    }
    
    // MARK: - FullScreenContentDelegate
    
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        print("📊 Rewarded ad impression recorded")
    }
    
    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        print("👆 Rewarded ad clicked")
    }
    
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("▶️ Rewarded ad will present")
    }
    
    func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("⏸️ Rewarded ad will dismiss")
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("✅ Rewarded ad dismissed")
        isShowingAd = false
    }
    
    func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        print("❌ Rewarded ad failed to present: \(error.localizedDescription)")
        isShowingAd = false
        // Try to reload
        loadAd()
    }
    
    // MARK: - Helper
    
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return nil
        }
        
        // Try key window first, then any window
        if let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            var topController = rootViewController
            while let presented = topController.presentedViewController {
                topController = presented
            }
            return topController
        } else if let rootViewController = windowScene.windows.first?.rootViewController {
            var topController = rootViewController
            while let presented = topController.presentedViewController {
                topController = presented
            }
            return topController
        }
        
        return nil
    }
}









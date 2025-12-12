import Foundation
import UIKit
import GoogleMobileAds
import UserMessagingPlatform

class ConsentManager: ObservableObject {
    @Published var canRequestAds = false
    @Published var isLoading = true
    
    static let shared = ConsentManager()
    
    private init() {}
    
    /// Request consent information and present consent form if needed
    func requestConsentInfoUpdate(from viewController: UIViewController? = nil) {
        // Set debug geography if needed for testing (remove in production)
        // let debugSettings = DebugSettings()
        // debugSettings.geography = .EEA
        // let parameters = RequestParameters()
        // parameters.debugSettings = debugSettings
        
        let parameters = RequestParameters()
        
        // Request consent information update
        ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                // Handle error
                print("Error requesting consent info: \(error.localizedDescription)")
                // Even if there's an error, we can still show ads (non-personalized)
                self.canRequestAds = true
                self.isLoading = false
                return
            }
            
            // Check if consent form is available and present it if needed
            DispatchQueue.main.async {
                self.loadConsentFormIfNeeded(from: viewController)
            }
        }
    }
    
    /// Load and present consent form if required
    private func loadConsentFormIfNeeded(from viewController: UIViewController? = nil) {
        guard ConsentInformation.shared.formStatus == .available else {
            // Form not available, we can request ads
            self.canRequestAds = true
            self.isLoading = false
            return
        }
        
        // Load consent form
        ConsentForm.load { [weak self] form, loadError in
            guard let self = self else { return }
            
            if let loadError = loadError {
                // Handle error loading form
                print("Error loading consent form: \(loadError.localizedDescription)")
                self.canRequestAds = true
                self.isLoading = false
                return
            }
            
            guard let form = form else {
                self.canRequestAds = true
                self.isLoading = false
                return
            }
            
            // Present consent form if needed
            if ConsentInformation.shared.consentStatus == .required {
                guard let viewController = viewController ?? self.getRootViewController() else {
                    self.canRequestAds = true
                    self.isLoading = false
                    return
                }
                
                form.present(from: viewController) { [weak self] dismissError in
                    guard let self = self else { return }
                    
                    if let dismissError = dismissError {
                        print("Error presenting consent form: \(dismissError.localizedDescription)")
                    }
                    
                    // Load next form if available (for privacy options)
                    self.loadConsentFormIfNeeded(from: viewController)
                }
            } else {
                // Consent already obtained or not required
                self.canRequestAds = true
                self.isLoading = false
            }
        }
    }
    
    /// Check if consent is obtained and we can show personalized ads
    var canShowPersonalizedAds: Bool {
        return ConsentInformation.shared.consentStatus == .obtained
    }
    
    /// Reset consent for testing purposes
    func resetConsent() {
        ConsentInformation.shared.reset()
        canRequestAds = false
    }
    
    /// Get root view controller for presenting forms
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return nil
        }
        
        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }
        
        return topController
    }
}







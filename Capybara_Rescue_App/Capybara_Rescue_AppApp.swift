import SwiftUI
import UserNotifications
import GoogleMobileAds

// MARK: - Notification Delegate
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    // Show notifications even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification banner, sound, and badge even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}

@main
struct CapybaraRescueUniverseApp: App {
    @StateObject private var gameManager = GameManager()
    @StateObject private var consentManager = ConsentManager.shared
    private let notificationDelegate = NotificationDelegate()
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Set up notification delegate to show notifications in foreground
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }
    
    var body: some Scene {
        WindowGroup {
            AppStartupView(consentManager: consentManager)
                .environmentObject(gameManager)
                .environmentObject(SettingsManager.shared)
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        gameManager.handleAppBecameActive()
                    }
                }
        }
    }
}

// MARK: - App Startup View (handles consent before showing main content)
struct AppStartupView: View {
    @EnvironmentObject var gameManager: GameManager
    @ObservedObject var consentManager: ConsentManager
    @ObservedObject private var settingsManager = SettingsManager.shared
    @State private var hasRequestedConsent = false
    @StateObject private var trackingManager = TrackingManager.shared
    @State private var hasStartedMobileAds = false
    
    var body: some View {
        Group {
            if !AdsConfig.adsEnabled {
                // Ads disabled (e.g. local testing) — skip consent/ad startup entirely.
                ContentView()
            } else {
                ZStack {
                    if consentManager.isLoading {
                        // Show loading screen while consent is being handled
                        Color(hex: "FFF8E7")
                            .ignoresSafeArea()
                            .overlay {
                                VStack(spacing: 20) {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                        .tint(.gray)
                                    Text("Loading...")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                            }
                    } else {
                        // Show main content after consent is handled
                        ContentView()
                    }
                }
            }
        }
        .preferredColorScheme(settingsManager.darkMode ? .dark : .light)
        .onAppear {
            // Request consent info update on first launch
            guard AdsConfig.adsEnabled else { return }
            if !hasRequestedConsent {
                hasRequestedConsent = true
                // Small delay to ensure view hierarchy is ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    consentManager.requestConsentInfoUpdate()
                }
            }
        }
        .task(id: consentManager.isLoading) {
            // Start ads only after:
            // - Consent flow finishes (loading ends)
            // - ATT prompt is requested (if needed)
            // This ensures the ATT prompt is discoverable during review and occurs
            // before ad-related tracking signals (e.g., IDFA) could be accessed.
            guard AdsConfig.adsEnabled else { return }
            guard !consentManager.isLoading else { return }
            guard consentManager.canRequestAds else { return }
            guard !hasStartedMobileAds else { return }

            await trackingManager.requestTrackingAuthorizationIfNeeded()
            
            // Configure test devices before starting/loading ads.
            // - Simulator uses the special `"SIMULATOR"` identifier (works across SDK versions)
            // - Physical devices: add the hashed ID printed by the SDK to `AdMobIDs.testDeviceIdentifiers`
            let configuredTestDevices = Array(Set(AdMobIDs.testDeviceIdentifiers + ["SIMULATOR"]))
            if !configuredTestDevices.isEmpty {
                MobileAds.shared.requestConfiguration.testDeviceIdentifiers = configuredTestDevices
            }
            await MobileAds.shared.start()
            hasStartedMobileAds = true
        }
    }
}


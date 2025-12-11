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
    
    init() {
        // Set up notification delegate to show notifications in foreground
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }
    
    var body: some Scene {
        WindowGroup {
            AppStartupView(consentManager: consentManager)
                .environmentObject(gameManager)
                .preferredColorScheme(ColorScheme.dark)
        }
    }
}

// MARK: - App Startup View (handles consent before showing main content)
struct AppStartupView: View {
    @EnvironmentObject var gameManager: GameManager
    @ObservedObject var consentManager: ConsentManager
    @State private var hasRequestedConsent = false
    
    var body: some View {
        ZStack {
            if consentManager.isLoading {
                // Show loading screen while consent is being handled
                Color(hex: "0f0c29")
                    .ignoresSafeArea()
                    .overlay {
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            Text("Loading...")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
            } else {
                // Show main content after consent is handled
                ContentView()
                    .onAppear {
                        // Initialize Google Mobile Ads SDK after consent is obtained
                        if consentManager.canRequestAds {
                            MobileAds.shared.start()
                        }
                    }
            }
        }
        .onAppear {
            // Request consent info update on first launch
            if !hasRequestedConsent {
                hasRequestedConsent = true
                // Small delay to ensure view hierarchy is ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    consentManager.requestConsentInfoUpdate()
                }
            }
        }
    }
}


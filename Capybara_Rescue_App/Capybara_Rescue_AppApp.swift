import SwiftUI
import UIKit
import UserNotifications

// MARK: - Deep link / notification routing
extension Notification.Name {
    /// Posted when the user should land on the Items tab (e.g. hat promo notification tap).
    static let capybaraOpenItems = Notification.Name("capybaraOpenItems")
}

private enum PendingNotificationDeepLink {
    static let openItemsKey = "pending_open_items"
}

// MARK: - App lifecycle + notifications
final class CapybaraRescueAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        AppIconABExperiment.applyAssignedVariantIfNeeded()
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let action = userInfo["action"] as? String, action == "openItems" {
            UserDefaults.standard.set(true, forKey: PendingNotificationDeepLink.openItemsKey)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .capybaraOpenItems, object: nil)
            }
        }
        completionHandler()
    }
}

@main
struct CapybaraRescueUniverseApp: App {
    @UIApplicationDelegateAdaptor(CapybaraRescueAppDelegate.self) private var appDelegate
    @StateObject private var gameManager = GameManager()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            RootView()
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

// MARK: - Root View
private struct RootView: View {
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        ContentView()
            .preferredColorScheme(.light)
            .onAppear {
                // Prepare haptic generators on main thread so feedback works reliably
                HapticManager.shared.prepareGenerators()
            }
    }
}

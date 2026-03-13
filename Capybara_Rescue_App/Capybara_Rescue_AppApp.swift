import SwiftUI
import UserNotifications

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
    private let notificationDelegate = NotificationDelegate()
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Set up notification delegate to show notifications in foreground
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }
    
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

// MARK: - Root View (applies settings like dark mode)
private struct RootView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        ContentView()
            .preferredColorScheme(settingsManager.darkMode ? .dark : .light)
    }
}

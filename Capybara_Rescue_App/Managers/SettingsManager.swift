import SwiftUI
import UserNotifications

// MARK: - Settings Manager
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let darkMode = "settings_darkMode"
        static let soundEnabled = "settings_soundEnabled"
        static let musicEnabled = "settings_musicEnabled"
        static let notificationsEnabled = "settings_notificationsEnabled"
        static let hapticEnabled = "settings_hapticEnabled"
    }
    
    @Published var darkMode: Bool {
        didSet { defaults.set(darkMode, forKey: Keys.darkMode) }
    }
    
    @Published var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Keys.soundEnabled) }
    }
    
    @Published var musicEnabled: Bool {
        didSet { defaults.set(musicEnabled, forKey: Keys.musicEnabled) }
    }
    
    @Published var notificationsEnabled: Bool {
        didSet {
            defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled)
            if !notificationsEnabled {
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            }
        }
    }
    
    @Published var hapticEnabled: Bool {
        didSet { defaults.set(hapticEnabled, forKey: Keys.hapticEnabled) }
    }
    
    private init() {
        self.darkMode = defaults.object(forKey: Keys.darkMode) as? Bool ?? false
        self.soundEnabled = defaults.object(forKey: Keys.soundEnabled) as? Bool ?? true
        self.musicEnabled = defaults.object(forKey: Keys.musicEnabled) as? Bool ?? true
        self.notificationsEnabled = defaults.object(forKey: Keys.notificationsEnabled) as? Bool ?? true
        self.hapticEnabled = defaults.object(forKey: Keys.hapticEnabled) as? Bool ?? true
    }
    
    var preferredColorScheme: ColorScheme? {
        darkMode ? .dark : .light
    }
}

import UIKit
import AudioToolbox

// MARK: - Sound Manager
/// Plays sound effects. Respects SettingsManager.soundEnabled.
class SoundManager {
    static let shared = SoundManager()
    
    private init() {}
    
    var isEnabled: Bool {
        SettingsManager.shared.soundEnabled
    }
    
    /// Plays a celebratory sound when a stat reaches 100 (confetti moment).
    /// Uses system sound 1025 (new mail) - a pleasant celebratory ding.
    func playStat100Celebration() {
        guard isEnabled else { return }
        DispatchQueue.main.async {
            AudioServicesPlaySystemSound(1025) // New mail - celebratory ding
        }
    }
    
    /// Plays when capybara eats food (item consumed).
    func playEatingSound() {
        guard isEnabled else { return }
        DispatchQueue.main.async {
            AudioServicesPlaySystemSound(1008) // Mail alert - crisp tone
        }
    }
    
    /// Plays when capybara drinks (item consumed).
    func playDrinkingSound() {
        guard isEnabled else { return }
        DispatchQueue.main.async {
            AudioServicesPlaySystemSound(1104) // Lock - satisfying sip/glass
        }
    }
}

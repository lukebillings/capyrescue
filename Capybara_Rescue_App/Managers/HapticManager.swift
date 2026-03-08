import UIKit

// MARK: - Haptic Feedback Manager
class HapticManager {
    static let shared = HapticManager()
    
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    private init() {
        // Pre-warm the generators for faster response
        prepareGenerators()
    }
    
    func prepareGenerators() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    var isEnabled: Bool {
        SettingsManager.shared.hapticEnabled
    }
    
    // MARK: - Menu Navigation
    func menuTabChanged() {
        guard isEnabled else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.selectionGenerator.selectionChanged()
            self.selectionGenerator.prepare()
        }
    }
    
    // MARK: - Petting Capybara
    func petCapybara() {
        guard isEnabled else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.lightGenerator.impactOccurred(intensity: 0.6)
            self.lightGenerator.prepare()
        }
    }
    
    // MARK: - Throwing Food/Drink
    func throwItem() {
        guard isEnabled else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.mediumGenerator.impactOccurred(intensity: 0.8)
            self.mediumGenerator.prepare()
        }
    }
    
    // MARK: - Item Consumed
    func itemConsumed() {
        guard isEnabled else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.heavyGenerator.impactOccurred(intensity: 0.5)
            self.heavyGenerator.prepare()
        }
    }
    
    // MARK: - Purchase Success
    func purchaseSuccess() {
        guard isEnabled else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.notificationGenerator.notificationOccurred(.success)
            self.notificationGenerator.prepare()
        }
    }
    
    // MARK: - Purchase Failed (not enough coins)
    func purchaseFailed() {
        guard isEnabled else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.notificationGenerator.notificationOccurred(.error)
            self.notificationGenerator.prepare()
        }
    }
    
    // MARK: - Button Press
    func buttonPress() {
        guard isEnabled else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.lightGenerator.impactOccurred(intensity: 0.4)
            self.lightGenerator.prepare()
        }
    }
    
    // MARK: - Selection
    func selection() {
        guard isEnabled else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.selectionGenerator.selectionChanged()
            self.selectionGenerator.prepare()
        }
    }
}


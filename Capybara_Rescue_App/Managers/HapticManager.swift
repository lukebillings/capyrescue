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
    
    // MARK: - Menu Navigation
    func menuTabChanged() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.selectionGenerator.selectionChanged()
            self.selectionGenerator.prepare()
        }
    }
    
    // MARK: - Petting Capybara
    func petCapybara() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.lightGenerator.impactOccurred(intensity: 0.6)
            self.lightGenerator.prepare()
        }
    }
    
    // MARK: - Throwing Food/Drink
    func throwItem() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.mediumGenerator.impactOccurred(intensity: 0.8)
            self.mediumGenerator.prepare()
        }
    }
    
    // MARK: - Item Consumed
    func itemConsumed() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.heavyGenerator.impactOccurred(intensity: 0.5)
            self.heavyGenerator.prepare()
        }
    }
    
    // MARK: - Purchase Success
    func purchaseSuccess() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.notificationGenerator.notificationOccurred(.success)
            self.notificationGenerator.prepare()
        }
    }
    
    // MARK: - Purchase Failed (not enough coins)
    func purchaseFailed() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.notificationGenerator.notificationOccurred(.error)
            self.notificationGenerator.prepare()
        }
    }
    
    // MARK: - Button Press
    func buttonPress() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.lightGenerator.impactOccurred(intensity: 0.4)
            self.lightGenerator.prepare()
        }
    }
    
    // MARK: - Selection
    func selection() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.selectionGenerator.selectionChanged()
            self.selectionGenerator.prepare()
        }
    }
}


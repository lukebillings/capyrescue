import SwiftUI

// MARK: - Capybara View with 2D/3D Toggle
// This is an example of how to switch between 2D and 3D views
// You can add a toggle in settings or use this directly

struct CapybaraViewWithToggle: View {
    let emotion: CapybaraEmotion
    let equippedAccessories: [String]
    let previewingAccessoryId: String?
    let onPet: () -> Void
    
    @AppStorage("use3DCapybara") private var use3D = false
    
    var body: some View {
        Group {
            if use3D {
                Capybara3DView(
                    emotion: emotion,
                    equippedAccessories: equippedAccessories,
                    previewingAccessoryId: previewingAccessoryId,
                    onPet: onPet
                )
            } else {
                CapybaraView(
                    emotion: emotion,
                    equippedAccessories: equippedAccessories,
                    onPet: onPet
                )
            }
        }
    }
}

// MARK: - Simple Direct Switch
// To use 3D view directly, just replace CapybaraView with Capybara3DView in ContentView:
/*
// In ContentView.swift, line ~54, change:
CapybaraView(
    emotion: gameManager.gameState.capybaraEmotion,
    equippedAccessories: gameManager.gameState.equippedAccessories,
    onPet: {
        gameManager.petCapybara()
    }
)

// To:
Capybara3DView(
    emotion: gameManager.gameState.capybaraEmotion,
    equippedAccessories: gameManager.gameState.equippedAccessories,
    onPet: {
        gameManager.petCapybara()
    }
)
*/


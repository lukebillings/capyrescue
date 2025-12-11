import SwiftUI

// MARK: - Drink Panel
struct DrinkPanel: View {
    @EnvironmentObject var gameManager: GameManager
    let onDrinkSelected: (DrinkItem) -> Void
    let onBack: (() -> Void)?
    
    init(onDrinkSelected: @escaping (DrinkItem) -> Void, onBack: (() -> Void)? = nil) {
        self.onDrinkSelected = onDrinkSelected
        self.onBack = onBack
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with back button
            HStack {
                if let onBack = onBack {
                    Button(action: {
                        HapticManager.shared.buttonPress()
                        onBack()
                    }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                PanelHeader(
                    title: "Hydrate Your Capybara",
                    subtitle: "Keep them refreshed! 💧",
                    color: AppColors.drinkBlue
                )
                
                Spacer()
                
                // Spacer for symmetry
                if onBack != nil {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.clear)
                }
            }
            .padding(.horizontal, 16)
            
            // One-time use note
            Text("Note: Each item is one-time use")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, 16)
                .padding(.top, -8)
            
            // Drink items - horizontal scrolling row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(DrinkItem.allItems) { item in
                        DrinkItemButton(
                            item: item,
                            canAfford: gameManager.canAfford(item.cost)
                        ) {
                            handleDrinkSelection(item)
                        }
                        .frame(width: 100) // Fixed width for horizontal scroll
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8) // Add vertical padding to prevent cutoff
            }
            .frame(maxHeight: .infinity) // Allow scroll view to take available space
        }
        .padding(.top, 20)
        .padding(.bottom, 8) // Add bottom padding
    }
    
    private func handleDrinkSelection(_ item: DrinkItem) {
        if gameManager.canAfford(item.cost) {
            HapticManager.shared.throwItem()
            onDrinkSelected(item)
        } else {
            HapticManager.shared.purchaseFailed()
        }
    }
}

// MARK: - Drink Item Button
struct DrinkItemButton: View {
    let item: DrinkItem
    let canAfford: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Emoji
                Text(item.emoji)
                    .font(.system(size: 48)) // Increased size
                    .frame(width: 70, height: 70) // Larger frame
                    .background(
                        Circle()
                            .fill(canAfford ? AppColors.drinkBlue.opacity(0.2) : Color.gray.opacity(0.2))
                    )
                    .overlay(
                        Circle()
                            .stroke(canAfford ? AppColors.drinkBlue.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
                    )
                
                // Name
                Text(item.name)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(canAfford ? .white : .white.opacity(0.6))
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                
                // Cost
                HStack(spacing: 3) {
                    Text("₵")
                        .font(.system(size: 12, weight: .bold))
                    Text("\(item.cost)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundStyle(canAfford ? AppColors.accent : .white.opacity(0.5))
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                
                // Drink value indicator
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 10))
                    Text("+\(item.drinkValue)")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(AppColors.drinkBlue.opacity(canAfford ? 1 : 0.6))
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(canAfford ? 0.08 : 0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(canAfford ? 0.15 : 0.05), lineWidth: 1)
                    )
            )
            .opacity(canAfford ? 1 : 0.6)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!canAfford)
    }
}

#Preview {
    ZStack {
        AppColors.background
            .ignoresSafeArea()
        
        DrinkPanel(onDrinkSelected: { _ in })
            .environmentObject(GameManager())
    }
}


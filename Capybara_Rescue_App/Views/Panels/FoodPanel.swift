import SwiftUI

// MARK: - Food Panel
struct FoodPanel: View {
    @EnvironmentObject var gameManager: GameManager
    let onFoodSelected: (FoodItem) -> Void
    let onBack: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    
    init(onFoodSelected: @escaping (FoodItem) -> Void, onBack: (() -> Void)? = nil) {
        self.onFoodSelected = onFoodSelected
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
                    title: "Feed Your Capybara",
                    subtitle: "Choose a tasty treat! 🌿",
                    color: AppColors.foodGreen
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
            
            // Food items - horizontal scrolling row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(FoodItem.allItems) { item in
                        FoodItemButton(
                            item: item,
                            canAfford: gameManager.canAfford(item.cost)
                        ) {
                            handleFoodSelection(item)
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
    
    private func handleFoodSelection(_ item: FoodItem) {
        if gameManager.canAfford(item.cost) {
            HapticManager.shared.throwItem()
            onFoodSelected(item)
        } else {
            HapticManager.shared.purchaseFailed()
        }
    }
}

// MARK: - Food Item Button
struct FoodItemButton: View {
    let item: FoodItem
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
                            .fill(canAfford ? AppColors.foodGreen.opacity(0.2) : Color.gray.opacity(0.2))
                    )
                    .overlay(
                        Circle()
                            .stroke(canAfford ? AppColors.foodGreen.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
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
                
                // Food value indicator
                HStack(spacing: 2) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 10))
                    Text("+\(item.foodValue)")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(AppColors.foodGreen.opacity(canAfford ? 1 : 0.6))
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

// MARK: - Panel Header
struct PanelHeader: View {
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Text(subtitle)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(color.opacity(0.8))
        }
        .padding(.bottom, 8)
    }
}

#Preview {
    ZStack {
        AppColors.background
            .ignoresSafeArea()
        
        FoodPanel(onFoodSelected: { _ in })
            .environmentObject(GameManager())
    }
}


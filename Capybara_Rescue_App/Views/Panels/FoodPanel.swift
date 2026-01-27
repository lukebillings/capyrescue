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
        GeometryReader { geometry in
            VStack(spacing: 12) {
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
                    .padding(.vertical, 8)
                }
                .frame(height: max(120, min(geometry.size.height * 0.65, 140))) // Adaptive height
                
                // Header with back button - moved below items
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
                    
                    VStack(spacing: 4) {
                        Text("Feed Your Capybara")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Text("Foods are one time use")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    
                    Spacer()
                    
                    // Spacer for symmetry
                    if onBack != nil {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.clear)
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 60) // Fixed height for header to prevent cutoff
            }
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
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
            VStack(spacing: 6) {
                // Emoji
                Text(item.emoji)
                    .font(.system(size: 48)) // Increased size
                    .frame(width: 70, height: 70) // Larger frame
                
                // Name
                Text(item.name)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(canAfford ? .white : .white.opacity(0.6))
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                
                // Cost and Food value on same line
                HStack(spacing: 8) {
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


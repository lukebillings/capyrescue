import SwiftUI

// MARK: - Drink Panel
struct DrinkPanel: View {
    @EnvironmentObject var gameManager: GameManager
    let onDrinkSelected: (DrinkItem) -> Void
    let onBack: (() -> Void)?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    init(onDrinkSelected: @escaping (DrinkItem) -> Void, onBack: (() -> Void)? = nil) {
        self.onDrinkSelected = onDrinkSelected
        self.onBack = onBack
    }
    
    var body: some View {
        Group {
            // Keep iPhone (compact width) submenu layout unchanged.
            if horizontalSizeClass == .compact {
                VStack(spacing: 16) {
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
                    .frame(maxHeight: .infinity) // Fill space so header sits lower
                    
                    // Header with back button - below items
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
                            Text("Hydrate Your Capybara")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            
                            Text("Drinks are one time use")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundStyle(.white.opacity(0.6))
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
                }
                .padding(.top, 80)
                .padding(.bottom, 36)
            } else {
                // iPad / iPad mini: keep adaptive sizing to avoid row/header clipping.
                GeometryReader { geometry in
                    VStack(spacing: 12) {
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
                                Text("Hydrate Your Capybara")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                
                                Text("Drinks are one time use")
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
        }
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
                
                // Cost and Drink value on same line
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


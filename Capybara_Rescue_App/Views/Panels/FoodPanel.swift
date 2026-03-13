import SwiftUI

// MARK: - Food Panel
struct FoodPanel: View {
    @EnvironmentObject var gameManager: GameManager
    @ObservedObject private var localizationManager = LocalizationManager.shared
    let onFoodSelected: (FoodItem) -> Void
    let onBack: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    init(onFoodSelected: @escaping (FoodItem) -> Void, onBack: (() -> Void)? = nil) {
        self.onFoodSelected = onFoodSelected
        self.onBack = onBack
    }
    
    // Filter items - show CNY items from Feb 13 onwards
    private var availableFoodItems: [FoodItem] {
        FoodItem.allItems.filter { item in
            // Fortune Cookie appears from Feb 13 onwards (stays forever)
            if item.name == "Fortune Cookie" {
                return Date.shouldShowCNYItems2026()
            }
            return true
        }
    }
    
    var body: some View {
        Group {
            // Keep iPhone (compact width) submenu layout unchanged.
            if horizontalSizeClass == .compact {
                VStack(spacing: 6) {
                    Spacer(minLength: 0)
                    
                    HStack(alignment: .center, spacing: 12) {
                        if let onBack = onBack {
                            Button(action: {
                                HapticManager.shared.buttonPress()
                                onBack()
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Circle().fill(Color(hex: "1a5f1a")))
                            }
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(availableFoodItems) { item in
                                    FoodItemButton(
                                        item: item,
                                        canAfford: gameManager.canAfford(item.cost)
                                    ) {
                                        handleFoodSelection(item)
                                    }
                                    .frame(width: 72)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                        }
                        .frame(height: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .padding(.top, 240)
                .padding(.bottom, 12)
            } else {
                // iPad / iPad mini: keep adaptive sizing to avoid row/header clipping.
                GeometryReader { geometry in
                    VStack(spacing: 6) {
                        Spacer(minLength: 0)
                        
                        HStack(alignment: .center, spacing: 12) {
                            if let onBack = onBack {
                                Button(action: {
                                    HapticManager.shared.buttonPress()
                                    onBack()
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .frame(width: 36, height: 36)
                                        .background(Circle().fill(Color(hex: "1a5f1a")))
                                }
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(availableFoodItems) { item in
                                        FoodItemButton(
                                            item: item,
                                            canAfford: gameManager.canAfford(item.cost)
                                        ) {
                                            handleFoodSelection(item)
                                        }
                                        .frame(width: 72)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                            }
                            .frame(height: 100)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .frame(height: 52)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                }
            }
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
    
    private var nameForegroundStyle: Color {
        canAfford ? Color.primary : Color.primary.opacity(0.7)
    }
    
    private var costForegroundStyle: Color {
        canAfford ? Color(hex: "1a5f1a") : Color.primary.opacity(0.7)
    }
    
    private var showCNYBadge: Bool {
        item.name == "Fortune Cookie" && Date.isChineseNewYearEvent2026()
    }
    
    var body: some View {
        Button(action: action) {
            foodItemContent
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!canAfford)
        .overlay(goldRingOverlay)
    }
    
    private var foodItemContent: some View {
        VStack(spacing: 4) {
            Text(item.emoji)
                .font(.system(size: 28))
                .frame(width: 44, height: 44)
            
            Text(localizedFoodName(item.name))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(nameForegroundStyle)
                .lineLimit(1)
            
            HStack(spacing: 6) {
                HStack(spacing: 2) {
                    Text("₵")
                        .font(.system(size: 10, weight: .bold))
                    Text("\(item.cost)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                .foregroundStyle(costForegroundStyle)
                
                HStack(spacing: 2) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 8))
                    Text("+\(item.foodValue)")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(AppColors.foodGreen.opacity(canAfford ? 1 : 0.6))
            }
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .opacity(canAfford ? 1 : 0.6)
        .overlay(cnyBadgeOverlay)
    }
    
    @ViewBuilder
    private var cnyBadgeOverlay: some View {
        if showCNYBadge {
            VStack {
                HStack {
                    Spacer()
                    Text(L("common.new"))
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(Color(hex: "8B0000"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .offset(x: -5, y: 5)
                }
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private var goldRingOverlay: some View {
        if showCNYBadge {
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        }
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
                .foregroundStyle(.primary)
            
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


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
                VStack(spacing: 16) {
                    // Food items - horizontal scrolling row
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(availableFoodItems) { item in
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
                                    .foregroundStyle(.primary.opacity(0.8))
                            }
                            .padding(.leading, 8)
                        }
                        
                        Spacer()
                        
                        Text(L("panel.feedTitle"))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        
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
                .padding(.bottom, 20)
            } else {
                // iPad / iPad mini: keep adaptive sizing to avoid row/header clipping.
                GeometryReader { geometry in
                    VStack(spacing: 12) {
                        // Food items - horizontal scrolling row
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(availableFoodItems) { item in
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
                                        .foregroundStyle(.primary.opacity(0.8))
                                }
                                .padding(.leading, 8)
                            }
                            
                            Spacer()
                            
                            Text(L("panel.feedTitle"))
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            
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
    
    private var backgroundFillOpacity: Double {
        canAfford ? 0.08 : 0.03
    }
    
    private var strokeOpacity: Double {
        canAfford ? 0.15 : 0.05
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
        VStack(spacing: 6) {
            Text(item.emoji)
                .font(.system(size: 48))
                .frame(width: 70, height: 70)
            
            Text(localizedFoodName(item.name))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(nameForegroundStyle)
                .lineLimit(1)
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            
            HStack(spacing: 8) {
                HStack(spacing: 3) {
                    Text("₵")
                        .font(.system(size: 12, weight: .bold))
                    Text("\(item.cost)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundStyle(costForegroundStyle)
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                
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
        .background(buttonBackground)
        .opacity(canAfford ? 1 : 0.6)
        .overlay(cnyBadgeOverlay)
    }
    
    private var buttonBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.white.opacity(backgroundFillOpacity))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(strokeOpacity), lineWidth: 1)
            )
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
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
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


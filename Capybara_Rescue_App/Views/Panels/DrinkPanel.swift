import SwiftUI

// MARK: - Drink Panel
struct DrinkPanel: View {
    @EnvironmentObject var gameManager: GameManager
    @ObservedObject private var localizationManager = LocalizationManager.shared
    let onDrinkSelected: (DrinkItem) -> Void
    let onBack: (() -> Void)?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    init(onDrinkSelected: @escaping (DrinkItem) -> Void, onBack: (() -> Void)? = nil) {
        self.onDrinkSelected = onDrinkSelected
        self.onBack = onBack
    }
    
    // Filter items - show CNY items from Feb 13 onwards
    private var availableDrinkItems: [DrinkItem] {
        DrinkItem.allItems.filter { item in
            // Jasmine Tea appears from Feb 13 onwards (stays forever)
            if item.name == "Jasmine Tea" {
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
                                ForEach(availableDrinkItems) { item in
                                    DrinkItemButton(
                                        item: item,
                                        canAfford: gameManager.canAfford(item.cost)
                                    ) {
                                        handleDrinkSelection(item)
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
                                    ForEach(availableDrinkItems) { item in
                                        DrinkItemButton(
                                            item: item,
                                            canAfford: gameManager.canAfford(item.cost)
                                        ) {
                                            handleDrinkSelection(item)
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
    
    private var nameForegroundStyle: Color {
        canAfford ? Color.primary : Color.primary.opacity(0.7)
    }
    
    private var costForegroundStyle: Color {
        canAfford ? Color(hex: "1a5f1a") : Color.primary.opacity(0.7)
    }
    
    private var showCNYBadge: Bool {
        item.name == "Jasmine Tea" && Date.isChineseNewYearEvent2026()
    }
    
    var body: some View {
        Button(action: action) {
            drinkItemContent
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!canAfford)
        .overlay(goldRingOverlay)
    }
    
    private var drinkItemContent: some View {
        VStack(spacing: 4) {
            Text(item.emoji)
                .font(.system(size: 28))
                .frame(width: 44, height: 44)
            
            Text(localizedDrinkName(item.name))
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
                    Image(systemName: "drop.fill")
                        .font(.system(size: 8))
                    Text("+\(item.drinkValue)")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(AppColors.drinkBlue.opacity(canAfford ? 1 : 0.6))
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
                    Text("NEW!")
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

#Preview {
    ZStack {
        AppColors.background
            .ignoresSafeArea()
        
        DrinkPanel(onDrinkSelected: { _ in })
            .environmentObject(GameManager())
    }
}


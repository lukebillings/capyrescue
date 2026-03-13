import SwiftUI

// MARK: - Master Panel
struct MasterPanel: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    let onCategorySelected: (MenuTab) -> Void
    
    var body: some View {
        // Category row - horizontal layout at bottom
        HStack(spacing: 12) {
            // Food
            CategoryCard(
                icon: "leaf.fill",
                title: L("menu.food"),
                color: AppColors.foodGreen,
                emoji: "🌿",
                tutorialKey: "food_button"
            ) {
                onCategorySelected(.food)
            }
            
            // Drink
            CategoryCard(
                icon: "drop.fill",
                title: L("menu.drink"),
                color: AppColors.drinkBlue,
                emoji: "💧",
                tutorialKey: "drink_button"
            ) {
                onCategorySelected(.drink)
            }
            
            // Items
            CategoryCard(
                icon: "tshirt.fill",
                title: L("menu.items"),
                color: .purple,
                emoji: "👕",
                tutorialKey: "items_button"
            ) {
                onCategorySelected(.items)
            }
        }
        .padding(.bottom, 0)
        .padding(.top, 0)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Category Card (modern iOS style: SF Symbol, material-style background)
struct CategoryCard: View {
    let icon: String
    let title: String
    let color: Color
    let emoji: String
    let tutorialKey: String?
    let isShopButton: Bool
    let action: () -> Void
    
    init(icon: String, title: String, color: Color, emoji: String, tutorialKey: String? = nil, isShopButton: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.color = color
        self.emoji = emoji
        self.tutorialKey = tutorialKey
        self.isShopButton = isShopButton
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isShopButton ? Color(hex: "8B4513") : color)
                    .frame(height: 44)
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                    // Lightening overlay so cards match top box (not darker)
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.06),
                                    Color.white.opacity(0.02)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.35),
                                    Color.white.opacity(0.12),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: .black.opacity(0.22), radius: 20, x: 0, y: 10)
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .tutorialHighlight(key: tutorialKey ?? "")
    }
}

#Preview {
    ZStack {
        AppColors.background
            .ignoresSafeArea()
        
        MasterPanel(onCategorySelected: { tab in
            print("Selected: \(tab)")
        })
    }
}


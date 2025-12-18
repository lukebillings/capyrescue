import SwiftUI

// MARK: - Master Panel
struct MasterPanel: View {
    let onCategorySelected: (MenuTab) -> Void
    
    var body: some View {
        // Category row - horizontal layout at bottom
        HStack(spacing: 12) {
            // Food
            CategoryCard(
                icon: "leaf.fill",
                title: "Food",
                subtitle: "Feed your capybara",
                color: AppColors.foodGreen,
                emoji: "🌿",
                tutorialKey: "food_button"
            ) {
                onCategorySelected(.food)
            }
            
            // Drink
            CategoryCard(
                icon: "drop.fill",
                title: "Drink",
                subtitle: "Keep them hydrated",
                color: AppColors.drinkBlue,
                emoji: "💧",
                tutorialKey: "drink_button"
            ) {
                onCategorySelected(.drink)
            }
            
            // Items
            CategoryCard(
                icon: "tshirt.fill",
                title: "Items",
                subtitle: "Accessories & more",
                color: .purple,
                emoji: "👕",
                tutorialKey: "items_button"
            ) {
                onCategorySelected(.items)
            }
            
            // Shop
            CategoryCard(
                icon: "cart.fill",
                title: "Shop",
                subtitle: "Get more coins",
                color: AppColors.accent,
                emoji: "🛒",
                tutorialKey: "shop_button"
            ) {
                onCategorySelected(.shop)
            }
        }
        .padding(.bottom, 0)
        .padding(.top, 0)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let emoji: String
    let tutorialKey: String?
    let action: () -> Void
    
    init(icon: String, title: String, subtitle: String, color: Color, emoji: String, tutorialKey: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.color = color
        self.emoji = emoji
        self.tutorialKey = tutorialKey
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Large emoji - smaller size
                Text(emoji)
                    .font(.system(size: 40))
                    .frame(height: 50)
                
                // Title
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                // Subtitle
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12) // Reduced vertical padding
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        // Use gold gradient for Shop button, subtle gradient for others
                        isShopButton ? 
                            LinearGradient(
                                colors: [
                                    Color(hex: "FFD700"),
                                    Color(hex: "FF8C00")
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [
                                    color.opacity(0.15),
                                    color.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isShopButton ? 
                                    Color(hex: "FFD700").opacity(0.5) :
                                    color.opacity(0.3),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(
                color: isShopButton ? Color(hex: "FFD700").opacity(0.4) : .clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .tutorialHighlight(key: tutorialKey ?? "")
    }
    
    // Check if this is the Shop button by comparing color to accent
    private var isShopButton: Bool {
        // Compare the color to AppColors.accent (gold)
        // Since we can't directly compare Color values, we check if title is "Shop"
        return title == "Shop"
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


import SwiftUI

// MARK: - Liquid Glass Menu Bar
struct LiquidMenuBar: View {
    @Binding var selectedTab: MenuTab
    let onTabSelected: (MenuTab) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(MenuTab.allCases, id: \.self) { tab in
                MenuTabButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    action: {
                        if selectedTab != tab {
                            HapticManager.shared.menuTabChanged()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = tab
                            }
                            onTabSelected(tab)
                        }
                    }
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            LiquidGlassBackground()
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - Menu Tab Button
struct MenuTabButton: View {
    let tab: MenuTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    // Selection indicator
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        tabColor.opacity(0.6),
                                        tabColor.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                            .blur(radius: 8)
                    }
                    
                    // Icon container
                    Circle()
                        .fill(isSelected ? tabColor.opacity(0.2) : .clear)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: isSelected ? .bold : .medium))
                                .foregroundStyle(isSelected ? tabColor : .white.opacity(0.6))
                        )
                }
                
                Text(tab.rawValue)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium, design: .rounded))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var tabColor: Color {
        switch tab {
        case .food: return AppColors.foodGreen
        case .drink: return AppColors.drinkBlue
        case .items: return .purple
        case .shop: return AppColors.accent
        }
    }
}

// MARK: - Liquid Glass Background
struct LiquidGlassBackground: View {
    var body: some View {
        ZStack {
            // Base blur
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
            
            // Gradient overlay for depth
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.05),
                            Color.white.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Top highlight
            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.05),
                            Color.white.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            
            // Inner glow
            RoundedRectangle(cornerRadius: 26)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                .padding(2)
        }
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    ZStack {
        AppColors.background
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            LiquidMenuBar(selectedTab: .constant(.food), onTabSelected: { _ in })
        }
        .padding(.bottom, 30)
    }
}


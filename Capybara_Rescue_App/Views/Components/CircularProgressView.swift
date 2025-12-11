import SwiftUI

// MARK: - Circular Progress View
struct CircularProgressView: View {
    let title: String
    let value: Int
    let maxValue: Int
    let color: Color
    let icon: String
    
    private var progress: Double {
        Double(value) / Double(maxValue)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(
                        color.opacity(0.2),
                        lineWidth: 8
                    )
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [color, color.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(
                            lineWidth: 8,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress)
                
                // Inner glass effect
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(12)
                
                // Icon and value
                VStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(color)
                    
                    Text("\(value)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 80, height: 80)
            
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
        }
        .tutorialHighlight(key: tutorialKey)
    }
    
    private var tutorialKey: String {
        switch title.lowercased() {
        case "food": return "food_stat"
        case "drink": return "drink_stat"
        case "happy": return "happy_stat"
        default: return ""
        }
    }
}

// MARK: - Stats Display View
struct StatsDisplayView: View {
    let food: Int
    let drink: Int
    let happiness: Int
    
    var body: some View {
        HStack(spacing: 30) {
            CircularProgressView(
                title: "Food",
                value: food,
                maxValue: 100,
                color: .green,
                icon: "leaf.fill"
            )
            
            CircularProgressView(
                title: "Drink",
                value: drink,
                maxValue: 100,
                color: .cyan,
                icon: "drop.fill"
            )
            
            CircularProgressView(
                title: "Happy",
                value: happiness,
                maxValue: 100,
                color: .pink,
                icon: "heart.fill"
            )
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 32)
        .background(
            GlassBackground()
        )
    }
}

// MARK: - Glass Background
struct GlassBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        
        StatsDisplayView(food: 75, drink: 50, happiness: 90)
    }
}


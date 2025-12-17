import SwiftUI

// MARK: - Achievements View
struct AchievementsView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.dismiss) private var dismiss
    
    struct Achievement: Identifiable {
        let id: String
        let name: String
        let description: String
        let emoji: String
        let requirement: String
        let coinReward: Int
    }
    
    private let allAchievements: [Achievement] = [
        Achievement(id: "streak_3", name: "3 Day Care", description: "Keep all stats above 50 for 3 consecutive days", emoji: "🥈", requirement: "3 day streak", coinReward: 600),
        Achievement(id: "streak_7", name: "7 Day Care", description: "Keep all stats above 50 for 7 consecutive days", emoji: "🥇", requirement: "7 day streak", coinReward: 700),
        Achievement(id: "streak_30", name: "30 Day Care", description: "Keep all stats above 50 for 30 consecutive days", emoji: "🏆", requirement: "30 day streak", coinReward: 800),
        Achievement(id: "streak_100", name: "100 Day Care", description: "Keep all stats above 50 for 100 consecutive days", emoji: "💎", requirement: "100 day streak", coinReward: 900),
        Achievement(id: "streak_365", name: "365 Day Care", description: "Keep all stats above 50 for 365 consecutive days", emoji: "👑", requirement: "365 day streak", coinReward: 1000)
    ]
    
    private var currentStreak: Int {
        gameManager.gameState.statsStreak
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Current streak display
                        VStack(spacing: 12) {
                            Text("Current Care Streak")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                            
                            Text("Keep food, drink, and happiness all above 50")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundStyle(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                            
                            HStack(spacing: 8) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.orange, .red],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                Text("\(currentStreak)")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                
                                Text("days")
                                    .font(.system(size: 20, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        
                        // Achievements list
                        VStack(spacing: 16) {
                            ForEach(allAchievements) { achievement in
                                AchievementRow(
                                    achievement: achievement,
                                    isEarned: gameManager.gameState.earnedAchievements.contains(achievement.id),
                                    currentStreak: currentStreak
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticManager.shared.buttonPress()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
        }
    }
}

// MARK: - Achievement Row
struct AchievementRow: View {
    let achievement: AchievementsView.Achievement
    let isEarned: Bool
    let currentStreak: Int
    
    private var progress: Double {
        switch achievement.id {
        case "streak_3":
            return min(Double(currentStreak) / 3.0, 1.0)
        case "streak_7":
            return min(Double(currentStreak) / 7.0, 1.0)
        case "streak_30":
            return min(Double(currentStreak) / 30.0, 1.0)
        case "streak_100":
            return min(Double(currentStreak) / 100.0, 1.0)
        case "streak_365":
            return min(Double(currentStreak) / 365.0, 1.0)
        default:
            return 0.0
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Achievement emoji
            Text(achievement.emoji)
                .font(.system(size: 48))
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(isEarned ? Color(hex: "FFD700").opacity(0.2) : Color.white.opacity(0.05))
                        .overlay(
                            Circle()
                                .stroke(isEarned ? Color(hex: "FFD700").opacity(0.5) : Color.white.opacity(0.1), lineWidth: 2)
                        )
                )
                .opacity(isEarned ? 1.0 : 0.5)
            
            // Achievement info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(achievement.name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(isEarned ? .white : .white.opacity(0.6))
                    
                    if isEarned {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.green)
                    }
                }
                
                Text(achievement.description)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                
                // Coin reward - always shown
                HStack(spacing: 4) {
                    Text("₵")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "FFD700"))
                    Text("\(achievement.coinReward) coins")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "FFD700"))
                    Text(isEarned ? "rewarded" : "reward")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }
                
                // Progress bar
                if !isEarned {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.white.opacity(0.1))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * progress, height: 6)
                        }
                    }
                    .frame(height: 6)
                    
                    Text("\(Int(progress * 100))% complete")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isEarned ? Color(hex: "FFD700").opacity(0.1) : .white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isEarned ? Color(hex: "FFD700").opacity(0.3) : .white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

#Preview {
    AchievementsView()
        .environmentObject(GameManager())
}









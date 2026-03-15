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
        let coinReward: Int
        let section: String
        let countKey: String?
        let milestone: Int?
        
        var isRepeatable: Bool { countKey != nil && milestone != nil }
        
        init(id: String, name: String, description: String, emoji: String, coinReward: Int, section: String, countKey: String? = nil, milestone: Int? = nil) {
            self.id = id
            self.name = name
            self.description = description
            self.emoji = emoji
            self.coinReward = coinReward
            self.section = section
            self.countKey = countKey
            self.milestone = milestone
        }
    }
    
    private static let sectionOrder = ["Reach 100", "Do it again", "Care streak"]
    
    private let allAchievements: [Achievement] = [
        Achievement(id: "first_100_food", name: "Food at 100", description: "Food stat to 100", emoji: "🥗", coinReward: 2000, section: "Reach 100"),
        Achievement(id: "first_100_drink", name: "Drink at 100", description: "Drink stat to 100", emoji: "💧", coinReward: 2000, section: "Reach 100"),
        Achievement(id: "first_100_happy", name: "Happy at 100", description: "Happiness to 100", emoji: "😊", coinReward: 2000, section: "Reach 100"),
        Achievement(id: "first_all_100", name: "All at 100", description: "Food, drink & happiness all 100", emoji: "🌟", coinReward: 5000, section: "Reach 100"),
        Achievement(id: "feed_10", name: "Feed 10 times", description: "Every 10 feeds", emoji: "🥬", coinReward: 500, section: "Do it again", countKey: "feed", milestone: 10),
        Achievement(id: "pet_50", name: "Pet 50 times", description: "Every 50 pets", emoji: "❤️", coinReward: 750, section: "Do it again", countKey: "pet", milestone: 50),
        Achievement(id: "streak_3", name: "3 day streak", description: "Stats above 50 for 3 days", emoji: "🥈", coinReward: 6000, section: "Care streak"),
        Achievement(id: "streak_7", name: "7 day streak", description: "Stats above 50 for 7 days", emoji: "🥇", coinReward: 7000, section: "Care streak"),
        Achievement(id: "streak_30", name: "30 day streak", description: "Stats above 50 for 30 days", emoji: "🏆", coinReward: 8000, section: "Care streak"),
        Achievement(id: "streak_100", name: "100 day streak", description: "Stats above 50 for 100 days", emoji: "💎", coinReward: 9000, section: "Care streak"),
        Achievement(id: "streak_365", name: "365 day streak", description: "Stats above 50 for 365 days", emoji: "👑", coinReward: 10000, section: "Care streak")
    ]
    
    private var achievementsBySection: [(String, [Achievement])] {
        Self.sectionOrder.compactMap { sectionTitle in
            let list = allAchievements.filter { $0.section == sectionTitle }
            return list.isEmpty ? nil : (sectionTitle, list)
        }
    }
    
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
                                .foregroundStyle(Color.primary.opacity(0.8))
                            
                            Text("Keep food, drink and happiness all above 50 each day")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundStyle(Color.primary.opacity(0.8))
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
                                    .foregroundStyle(.primary)
                                
                                Text("days")
                                    .font(.system(size: 20, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.primary.opacity(0.8))
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
                        
                        // Achievements by section
                        ForEach(achievementsBySection, id: \.0) { sectionTitle, sectionAchievements in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(sectionTitle)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.primary.opacity(0.9))
                                    .padding(.horizontal, 4)
                                
                                VStack(spacing: 16) {
                                    ForEach(sectionAchievements) { achievement in
                                        AchievementRow(
                                            achievement: achievement,
                                            gameState: gameManager.gameState,
                                            currentStreak: currentStreak
                                        )
                                    }
                                }
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
                            .foregroundStyle(Color.primary.opacity(0.7))
                    }
                }
            }
        }
    }
}

// MARK: - Achievement Row
struct AchievementRow: View {
    let achievement: AchievementsView.Achievement
    let gameState: GameState
    let currentStreak: Int
    
    private var isEarned: Bool {
        gameState.earnedAchievements.contains(achievement.id)
    }
    
    private var repeatableCompletedCount: Int {
        guard achievement.isRepeatable, let key = achievement.countKey, let milestone = achievement.milestone else { return 0 }
        let last = gameState.achievementRepeatLastGranted[achievement.id] ?? 0
        return last / milestone
    }
    
    private var repeatableCurrentCount: Int {
        guard let key = achievement.countKey else { return 0 }
        return gameState.achievementCounts[key] ?? 0
    }
    
    private var progress: Double {
        switch achievement.id {
        case "streak_3": return min(Double(currentStreak) / 3.0, 1.0)
        case "streak_7": return min(Double(currentStreak) / 7.0, 1.0)
        case "streak_30": return min(Double(currentStreak) / 30.0, 1.0)
        case "streak_100": return min(Double(currentStreak) / 100.0, 1.0)
        case "streak_365": return min(Double(currentStreak) / 365.0, 1.0)
        case "first_100_food": return gameState.food >= 100 ? 1.0 : Double(gameState.food) / 100.0
        case "first_100_drink": return gameState.drink >= 100 ? 1.0 : Double(gameState.drink) / 100.0
        case "first_100_happy": return gameState.happiness >= 100 ? 1.0 : Double(gameState.happiness) / 100.0
        case "first_all_100":
            let all = gameState.food == 100 && gameState.drink == 100 && gameState.happiness == 100
            return all ? 1.0 : (Double(gameState.food + gameState.drink + gameState.happiness) / 300.0)
        case "feed_10":
            guard let m = achievement.milestone else { return 0 }
            let c = repeatableCurrentCount
            let towardNext = c % m
            return Double(towardNext) / Double(m)
        case "pet_50":
            guard let m = achievement.milestone else { return 0 }
            let c = repeatableCurrentCount
            let towardNext = c % m
            return Double(towardNext) / Double(m)
        default: return 0.0
        }
    }
    
    private var rewardSubtitle: String {
        if achievement.isRepeatable {
            let completed = repeatableCompletedCount
            if completed > 0 {
                return "Done \(completed)×"
            }
            return "Repeatable"
        }
        if isEarned { return "Earned" }
        return "Complete to earn"
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Coins: circular gold coin with white ¢, number with "coins" underneath
            HStack(alignment: .top, spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .shadow(color: Color(hex: "FFD700").opacity(0.4), radius: 4, x: 0, y: 2)
                    Text("₵")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(achievement.coinReward)")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(L("common.coins"))
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.primary.opacity(0.8))
                }
            }
            .frame(minWidth: 64, alignment: .leading)
            
            Text(achievement.emoji)
                .font(.system(size: 40))
                .frame(width: 52, height: 52)
                .background(
                    Circle()
                        .fill(isEarned || repeatableCompletedCount > 0 ? Color(hex: "FFD700").opacity(0.2) : Color.white.opacity(0.05))
                        .overlay(
                            Circle()
                                .stroke(isEarned || repeatableCompletedCount > 0 ? Color(hex: "FFD700").opacity(0.5) : Color.white.opacity(0.1), lineWidth: 2)
                        )
                )
                .opacity(isEarned || repeatableCompletedCount > 0 ? 1.0 : 0.5)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(achievement.name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(isEarned || repeatableCompletedCount > 0 ? Color.primary : Color.primary.opacity(0.8))
                    
                    if isEarned && !achievement.isRepeatable {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.green)
                    }
                    if achievement.isRepeatable && repeatableCompletedCount > 0 {
                        Text("×\(repeatableCompletedCount)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "1a5f1a"))
                    }
                }
                
                Text(rewardSubtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.primary.opacity(0.8))
                
                if !isEarned || (achievement.isRepeatable && (repeatableCurrentCount % (achievement.milestone ?? 1)) != 0) {
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
                    
                    if achievement.isRepeatable, let m = achievement.milestone {
                        let c = repeatableCurrentCount
                        let next = ((c / m) + 1) * m
                        Text("\(c) / \(next)")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.primary.opacity(0.8))
                    } else {
                        Text("\(Int(progress * 100))% complete")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.primary.opacity(0.8))
                    }
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isEarned || repeatableCompletedCount > 0 ? Color(hex: "FFD700").opacity(0.1) : .white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isEarned || repeatableCompletedCount > 0 ? Color(hex: "FFD700").opacity(0.3) : .white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

#Preview {
    AchievementsView()
        .environmentObject(GameManager())
}









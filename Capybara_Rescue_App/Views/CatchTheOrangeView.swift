import SwiftUI

// MARK: - Catch the Orange Mini-Game
/// Daily mini-game: tap falling oranges. Collect 20 to earn coins (once per day).
struct CatchTheOrangeView: View {
    @EnvironmentObject var gameManager: GameManager
    @Binding var isPresented: Bool
    
    private let targetCount = 20
    private let fruitSize: CGFloat = 56
    
    /// Distraction fruit emojis (tap these = wrong).
    private static let distractionEmojis = ["🍎", "🍌", "🍇", "🍉", "🍒", "🍑", "🍐", "🥝"]
    
    @State private var caughtCount = 0
    @State private var fallingItems: [FallingFruit] = []
    @State private var spawnTimer: Timer?
    @State private var gameTimer: Timer?
    @State private var showSuccess = false
    @State private var showFail = false
    
    private var canDismiss: Bool {
        showSuccess || showFail || caughtCount >= targetCount
    }
    
    var body: some View {
        ZStack {
            Color(hex: "FFF8E7")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        HapticManager.shared.buttonPress()
                        stopGame()
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color(hex: "1a1a2e").opacity(0.6))
                    }
                    Spacer()
                    Text("\(caughtCount) / \(targetCount)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "1a1a2e"))
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                // Game area - fruit falls here (oranges to catch, others distract)
                GeometryReader { geo in
                    ZStack(alignment: .top) {
                        ForEach(fallingItems) { item in
                            FallingFruitView(
                                item: item,
                                size: fruitSize,
                                screenHeight: geo.size.height
                            )
                            .onTapGesture {
                                handleTap(item, in: geo.size)
                            }
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Success overlay
            if showSuccess {
                successOverlay
            }
            // Fail overlay (wrong fruit tapped)
            if showFail {
                failOverlay
            }
        }
        .onAppear {
            startGame()
        }
        .onDisappear {
            stopGame()
        }
    }
    
    private static let cream = Color(hex: "FFF8E7")
    private static let primaryText = Color(hex: "1a1a2e")
    private static let secondaryText = Color(hex: "5A5A5A")
    private static let settingsGreen = Color(hex: "1a5f1a")
    
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("🍊")
                    .font(.system(size: 64))
                Text(L("orange.successTitle"))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Self.primaryText)
                    .multilineTextAlignment(.center)
                Text(L("orange.successBody"))
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(Self.secondaryText)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    HapticManager.shared.buttonPress()
                    gameManager.completeCatchTheOrangeGame()
                    isPresented = false
                }) {
                    Text(L("common.gotIt"))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Self.settingsGreen)
                        )
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Self.cream)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Self.primaryText.opacity(0.12), lineWidth: 1)
                    )
            )
            .padding(40)
        }
    }
    
    private var failOverlay: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("🍎")
                    .font(.system(size: 64))
                Text("Wrong fruit!")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Self.primaryText)
                    .multilineTextAlignment(.center)
                Text("Only tap the oranges. Try again!")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(Self.secondaryText)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    HapticManager.shared.buttonPress()
                    showFail = false
                    isPresented = false
                }) {
                    Text(L("common.gotIt"))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Self.settingsGreen)
                        )
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Self.cream)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Self.primaryText.opacity(0.12), lineWidth: 1)
                    )
            )
            .padding(40)
        }
    }
    
    private func startGame() {
        caughtCount = 0
        fallingItems = []
        showSuccess = false
        showFail = false
        
        spawnTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
            spawnFruit()
        }
        spawnTimer?.tolerance = 0.1
        RunLoop.main.add(spawnTimer!, forMode: .common)
        spawnFruit()
    }
    
    private func spawnFruit() {
        guard !showSuccess, !showFail, caughtCount < targetCount else { return }
        
        let screenWidth = UIScreen.main.bounds.width
        let x = CGFloat.random(in: (fruitSize / 2 + 20)...(screenWidth - fruitSize / 2 - 20))
        let fallDuration = Double.random(in: 2.5...5.5)
        let isOrange = Bool.random()
        
        let item = FallingFruit(
            id: UUID(),
            x: x,
            startTime: Date(),
            fallDuration: fallDuration,
            isTarget: isOrange,
            distractionEmoji: isOrange ? nil : Self.distractionEmojis.randomElement()
        )
        fallingItems.append(item)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + fallDuration + 1.0) {
            fallingItems.removeAll { $0.id == item.id }
        }
    }
    
    private func handleTap(_ item: FallingFruit, in size: CGSize) {
        guard !showSuccess, !showFail else { return }
        
        fallingItems.removeAll { $0.id == item.id }
        
        if item.isTarget {
            HapticManager.shared.buttonPress()
            caughtCount += 1
            if caughtCount >= targetCount {
                stopGame()
                showSuccess = true
            }
        } else {
            HapticManager.shared.purchaseFailed()
            stopGame()
            showFail = true
        }
    }
    
    private func stopGame() {
        spawnTimer?.invalidate()
        spawnTimer = nil
        gameTimer?.invalidate()
        gameTimer = nil
    }
}

// MARK: - Falling Fruit Model
private struct FallingFruit: Identifiable {
    let id: UUID
    let x: CGFloat
    let startTime: Date
    let fallDuration: Double
    let isTarget: Bool
    let distractionEmoji: String?
}

// MARK: - Falling Fruit View (variable speed)
private struct FallingFruitView: View {
    let item: FallingFruit
    let size: CGFloat
    let screenHeight: CGFloat
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.03)) { context in
            let elapsed = context.date.timeIntervalSince(item.startTime)
            let progress = min(1.0, elapsed / item.fallDuration)
            let y = -size + CGFloat(progress) * (screenHeight + size * 2)
            
            Group {
                if item.isTarget {
                    OrangeView(size: size)
                } else {
                    DistractionFruitView(emoji: item.distractionEmoji ?? "🍎", size: size)
                }
            }
            .position(x: item.x, y: y)
        }
    }
}

// MARK: - Orange View (tap to catch)
private struct OrangeView: View {
    let size: CGFloat
    
    var body: some View {
        Text("🍊")
            .font(.system(size: size * 0.7))
    }
}

// MARK: - Distraction Fruit View (tap = wrong)
private struct DistractionFruitView: View {
    let emoji: String
    let size: CGFloat
    
    var body: some View {
        Text(emoji)
            .font(.system(size: size * 0.65))
    }
}

#Preview {
    CatchTheOrangeView(isPresented: .constant(true))
        .environmentObject(GameManager())
}

import SwiftUI

// MARK: - Catch the Orange Mini-Game
/// Daily mini-game: tap falling oranges. Collect 20 to earn coins (once per day).
struct CatchTheOrangeView: View {
    @EnvironmentObject var gameManager: GameManager
    @Binding var isPresented: Bool
    
    private let targetCount = 20
    private let orangeSize: CGFloat = 56
    
    @State private var caughtCount = 0
    @State private var oranges: [FallingOrange] = []
    @State private var spawnTimer: Timer?
    @State private var gameTimer: Timer?
    @State private var showSuccess = false
    
    private var canDismiss: Bool {
        showSuccess || caughtCount >= targetCount
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
                
                // Game area - oranges fall here
                GeometryReader { geo in
                    ZStack(alignment: .top) {
                        ForEach(oranges) { orange in
                            FallingOrangeView(
                                orange: orange,
                                size: orangeSize,
                                screenHeight: geo.size.height
                            )
                            .onTapGesture {
                                catchOrange(orange, in: geo.size)
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
        }
        .onAppear {
            startGame()
        }
        .onDisappear {
            stopGame()
        }
    }
    
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("🍊")
                    .font(.system(size: 64))
                Text(L("orange.successTitle"))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text(L("orange.successBody"))
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    HapticManager.shared.buttonPress()
                    gameManager.completeCatchTheOrangeGame()
                    isPresented = false
                }) {
                    Text(L("common.gotIt"))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: "FFD700"))
                        )
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "1a1a2e").opacity(0.95))
            )
            .padding(40)
        }
    }
    
    private func startGame() {
        caughtCount = 0
        oranges = []
        showSuccess = false
        
        // Spawn new oranges every 0.8 seconds
        spawnTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
            spawnOrange()
        }
        spawnTimer?.tolerance = 0.1
        RunLoop.main.add(spawnTimer!, forMode: .common)
        
        // Initial spawn
        spawnOrange()
    }
    
    private func spawnOrange() {
        guard !showSuccess, caughtCount < targetCount else { return }
        
        let screenWidth = UIScreen.main.bounds.width
        let x = CGFloat.random(in: (orangeSize / 2 + 20)...(screenWidth - orangeSize / 2 - 20))
        
        let orange = FallingOrange(
            id: UUID(),
            x: x,
            startTime: Date()
        )
        oranges.append(orange)
        
        // Remove if not caught after 5s (fall duration + buffer)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            oranges.removeAll { $0.id == orange.id }
        }
    }
    
    private func catchOrange(_ orange: FallingOrange, in size: CGSize) {
        guard !showSuccess else { return }
        
        HapticManager.shared.buttonPress()
        oranges.removeAll { $0.id == orange.id }
        caughtCount += 1
        
        if caughtCount >= targetCount {
            stopGame()
            showSuccess = true
        }
    }
    
    private func stopGame() {
        spawnTimer?.invalidate()
        spawnTimer = nil
        gameTimer?.invalidate()
        gameTimer = nil
    }
}

// MARK: - Falling Orange Model
private struct FallingOrange: Identifiable {
    let id: UUID
    let x: CGFloat
    let startTime: Date
}

// MARK: - Falling Orange View (position from timeline)
private struct FallingOrangeView: View {
    let orange: FallingOrange
    let size: CGFloat
    let screenHeight: CGFloat
    
    private let fallDuration: Double = 4.0
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.03)) { context in
            let elapsed = context.date.timeIntervalSince(orange.startTime)
            let progress = min(1.0, elapsed / fallDuration)
            let y = -size + CGFloat(progress) * (screenHeight + size * 2)
            
            OrangeView(size: size)
                .position(x: orange.x, y: y)
        }
    }
}

// MARK: - Orange View (tappable orange)
private struct OrangeView: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "FF8C00"), Color(hex: "FF6600")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(Color(hex: "E65C00").opacity(0.6), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
            
            Text("🍊")
                .font(.system(size: size * 0.7))
        }
    }
}

#Preview {
    CatchTheOrangeView(isPresented: .constant(true))
        .environmentObject(GameManager())
}

import SwiftUI
import Foundation

// MARK: - Thrown Item View
struct ThrownItemView: View {
    let emoji: String
    let startPosition: CGPoint
    let endPosition: CGPoint
    let onComplete: () -> Void
    
    @State private var position: CGPoint
    @State private var scale: CGFloat = 1.5
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1
    
    init(emoji: String, startPosition: CGPoint, endPosition: CGPoint, onComplete: @escaping () -> Void) {
        self.emoji = emoji
        self.startPosition = startPosition
        self.endPosition = endPosition
        self.onComplete = onComplete
        self._position = State(initialValue: startPosition)
    }
    
    var body: some View {
        Text(emoji)
            .font(.system(size: 50))
            .position(position)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .onAppear {
                animateThrow()
            }
    }
    
    private func animateThrow() {
        // Arc animation with physics-like motion
        withAnimation(.easeOut(duration: 0.6)) {
            position = endPosition
            rotation = Double.random(in: -180...180)
        }
        
        withAnimation(.easeIn(duration: 0.3).delay(0.4)) {
            scale = 0.5
            opacity = 0
        }
        
        // Haptic on "catch"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            HapticManager.shared.itemConsumed()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            onComplete()
        }
    }
}

// MARK: - Food Throwing Animation Overlay
struct FoodThrowingOverlay: View {
    let item: GameManager.ThrownItem?
    let capybaraPosition: CGPoint
    let onAnimationComplete: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            if let thrownItem = item {
                ThrownItemView(
                    emoji: thrownItem.emoji,
                    startPosition: CGPoint(
                        x: geometry.size.width / 2,
                        y: geometry.size.height - 150
                    ),
                    endPosition: capybaraPosition,
                    onComplete: onAnimationComplete
                )
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Particle Effect View
struct ParticleEffectView: View {
    let emoji: String
    let position: CGPoint
    
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var velocity: CGPoint
        var scale: CGFloat
        var opacity: Double
    }
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Text(emoji)
                    .font(.system(size: 20))
                    .scaleEffect(particle.scale)
                    .opacity(particle.opacity)
                    .position(particle.position)
            }
        }
        .onAppear {
            createParticles()
            animateParticles()
        }
    }
    
    private func createParticles() {
        for _ in 0..<8 {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 50...100)
            
            particles.append(Particle(
                position: position,
                velocity: CGPoint(
                    x: cos(Double(angle)) * speed,
                    y: sin(Double(angle)) * speed
                ),
                scale: CGFloat.random(in: 0.5...1.0),
                opacity: 1.0
            ))
        }
    }
    
    private func animateParticles() {
        withAnimation(.easeOut(duration: 0.8)) {
            for i in particles.indices {
                particles[i].position.x += particles[i].velocity.x
                particles[i].position.y += particles[i].velocity.y
                particles[i].scale = 0.1
                particles[i].opacity = 0
            }
        }
    }
}

// MARK: - Love Heart View
struct LoveHeartView: View {
    let id: UUID
    let startPosition: CGPoint
    let angle: Double
    let distance: CGFloat
    
    @State private var position: CGPoint
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 1.0
    @State private var rotation: Double = 0
    
    init(id: UUID, startPosition: CGPoint, angle: Double, distance: CGFloat) {
        self.id = id
        self.startPosition = startPosition
        self.angle = angle
        self.distance = distance
        self._position = State(initialValue: startPosition)
    }
    
    var body: some View {
        Text(["💕", "❤️", "💖", "💗", "💝"].randomElement() ?? "💕")
            .font(.system(size: 30))
            .position(position)
            .scaleEffect(scale)
            .opacity(opacity)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                animateHeart()
            }
    }
    
    private func animateHeart() {
        // Calculate end position based on angle and distance
        let endX = startPosition.x + cos(angle) * distance
        let endY = startPosition.y + sin(angle) * distance
        
        // Animate outward
        withAnimation(.easeOut(duration: 1.5)) {
            position = CGPoint(x: endX, y: endY)
            scale = 1.2
            rotation = Double.random(in: -45...45)
        }
        
        // Fade out
        withAnimation(.easeIn(duration: 0.5).delay(1.0)) {
            opacity = 0
            scale = 0.3
        }
    }
}

// MARK: - Love Hearts Overlay
struct LoveHeartsOverlay: View {
    let isActive: Bool
    let capybaraPosition: CGPoint
    
    @State private var hearts: [LoveHeartData] = []
    @State private var heartTimer: Timer?
    
    struct LoveHeartData: Identifiable {
        let id: UUID
        let angle: Double
        let distance: CGFloat
    }
    
    var body: some View {
        ZStack {
            if isActive && capybaraPosition != .zero {
                ForEach(hearts) { heartData in
                    LoveHeartView(
                        id: heartData.id,
                        startPosition: capybaraPosition,
                        angle: heartData.angle,
                        distance: heartData.distance
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { oldValue, newValue in
            if newValue && capybaraPosition != .zero {
                startHeartGeneration()
            } else {
                stopHeartGeneration()
            }
        }
        .onChange(of: capybaraPosition) { oldValue, newValue in
            if isActive && newValue != .zero && oldValue == .zero {
                startHeartGeneration()
            }
        }
        .onAppear {
            if isActive && capybaraPosition != .zero {
                startHeartGeneration()
            }
        }
        .onDisappear {
            stopHeartGeneration()
        }
    }
    
    private func startHeartGeneration() {
        // Clear existing hearts
        hearts.removeAll()
        
        // Generate initial batch of hearts
        generateHeartBatch()
        
        // Create timer to continuously generate hearts (50% less frequent: 0.4 -> 0.8 seconds)
        heartTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
            generateHeartBatch()
        }
    }
    
    private func stopHeartGeneration() {
        heartTimer?.invalidate()
        heartTimer = nil
        // Let existing hearts finish animating, they'll fade out naturally
    }
    
    private func generateHeartBatch() {
        // Generate 1-2 hearts per batch (50% less: reduced from 2-3)
        let heartCount = Int.random(in: 1...2)
        var newHearts: [LoveHeartData] = []
        
        for _ in 0..<heartCount {
            // Angles from -π/2 to -π/6 (upward direction, -90° to -30°)
            // This makes hearts go upward and slightly to the sides, avoiding menu at bottom
            let angle = Double.random(in: -Double.pi/2...(-Double.pi/6))
            let distance = CGFloat.random(in: 80...150)
            
            let heartId = UUID()
            newHearts.append(LoveHeartData(
                id: heartId,
                angle: angle,
                distance: distance
            ))
        }
        
        hearts.append(contentsOf: newHearts)
        
        // Remove hearts after animation completes (after 2 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let idsToRemove = Set(newHearts.map { $0.id })
            hearts.removeAll { idsToRemove.contains($0.id) }
        }
    }
}

// MARK: - Unhappy Emoji View
struct UnhappyEmojiView: View {
    let id: UUID
    let startPosition: CGPoint
    let angle: Double
    let distance: CGFloat
    
    @State private var position: CGPoint
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 1.0
    @State private var rotation: Double = 0
    
    init(id: UUID, startPosition: CGPoint, angle: Double, distance: CGFloat) {
        self.id = id
        self.startPosition = startPosition
        self.angle = angle
        self.distance = distance
        self._position = State(initialValue: startPosition)
    }
    
    var body: some View {
        Text(["😢", "😞", "😟", "😔", "😕", "😰", "😓"].randomElement() ?? "😢")
            .font(.system(size: 30))
            .position(position)
            .scaleEffect(scale)
            .opacity(opacity)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                animateEmoji()
            }
    }
    
    private func animateEmoji() {
        // Calculate end position based on angle and distance
        let endX = startPosition.x + cos(angle) * distance
        let endY = startPosition.y + sin(angle) * distance
        
        // Animate outward
        withAnimation(.easeOut(duration: 1.5)) {
            position = CGPoint(x: endX, y: endY)
            scale = 1.2
            rotation = Double.random(in: -45...45)
        }
        
        // Fade out
        withAnimation(.easeIn(duration: 0.5).delay(1.0)) {
            opacity = 0
            scale = 0.3
        }
    }
}

// MARK: - Unhappy Emojis Overlay
struct UnhappyEmojisOverlay: View {
    let isActive: Bool
    let capybaraPosition: CGPoint
    
    @State private var emojis: [UnhappyEmojiData] = []
    @State private var emojiTimer: Timer?
    
    struct UnhappyEmojiData: Identifiable {
        let id: UUID
        let angle: Double
        let distance: CGFloat
    }
    
    var body: some View {
        ZStack {
            if isActive && capybaraPosition != .zero {
                ForEach(emojis) { emojiData in
                    UnhappyEmojiView(
                        id: emojiData.id,
                        startPosition: capybaraPosition,
                        angle: emojiData.angle,
                        distance: emojiData.distance
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { oldValue, newValue in
            if newValue && capybaraPosition != .zero {
                startEmojiGeneration()
            } else {
                stopEmojiGeneration()
            }
        }
        .onChange(of: capybaraPosition) { oldValue, newValue in
            if isActive && newValue != .zero && oldValue == .zero {
                startEmojiGeneration()
            }
        }
        .onAppear {
            if isActive && capybaraPosition != .zero {
                startEmojiGeneration()
            }
        }
        .onDisappear {
            stopEmojiGeneration()
        }
    }
    
    private func startEmojiGeneration() {
        // Clear existing emojis
        emojis.removeAll()
        
        // Generate initial batch of emojis
        generateEmojiBatch()
        
        // Create timer to continuously generate emojis (50% less frequent: 0.8 seconds)
        emojiTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
            generateEmojiBatch()
        }
    }
    
    private func stopEmojiGeneration() {
        emojiTimer?.invalidate()
        emojiTimer = nil
        // Let existing emojis finish animating, they'll fade out naturally
    }
    
    private func generateEmojiBatch() {
        // Generate 1-2 emojis per batch (same volume as hearts)
        let emojiCount = Int.random(in: 1...2)
        var newEmojis: [UnhappyEmojiData] = []
        
        for _ in 0..<emojiCount {
            // Angles from -π/2 to -π/6 (upward direction, -90° to -30°)
            // This makes emojis go upward and slightly to the sides, same positions as hearts
            let angle = Double.random(in: -Double.pi/2...(-Double.pi/6))
            let distance = CGFloat.random(in: 80...150)
            
            let emojiId = UUID()
            newEmojis.append(UnhappyEmojiData(
                id: emojiId,
                angle: angle,
                distance: distance
            ))
        }
        
        emojis.append(contentsOf: newEmojis)
        
        // Remove emojis after animation completes (after 2 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let idsToRemove = Set(newEmojis.map { $0.id })
            emojis.removeAll { idsToRemove.contains($0.id) }
        }
    }
}

// MARK: - Speech Bubble View
struct SpeechBubbleView: View {
    let icon: String
    let color: Color
    let capybaraPosition: CGPoint
    let isLeft: Bool // true for left side, false for right side
    let screenWidth: CGFloat
    
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    private var bubbleX: CGFloat {
        // Position near screen edges
        if isLeft {
            return 40 // Near left edge
        } else {
            return screenWidth - 40 // Near right edge
        }
    }
    
    private var bubbleY: CGFloat {
        capybaraPosition.y - 250 // Slightly down from before
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main bubble with icon and question mark
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(color)
                    
                    Text("?")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(color)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.95))
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                )
                .position(x: bubbleX, y: bubbleY)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}
// MARK: - Speech Bubble Tail Shape (pointing downward)
struct SpeechBubbleTailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Triangle pointing down
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}


// MARK: - Capybara Speech Bubble Overlay
struct CapybaraSpeechBubbleOverlay: View {
    let food: Int
    let drink: Int
    let capybaraPosition: CGPoint
    
    private var needsFood: Bool {
        food < 80
    }
    
    private var needsDrink: Bool {
        drink < 80
    }
    
    var body: some View {
        GeometryReader { geometry in
            if capybaraPosition != .zero {
                ZStack {
                    // Food bubble on top left
                    if needsFood {
                        SpeechBubbleView(
                            icon: "leaf.fill",
                            color: AppColors.foodGreen,
                            capybaraPosition: capybaraPosition,
                            isLeft: true,
                            screenWidth: geometry.size.width
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Drink bubble on top right
                    if needsDrink {
                        SpeechBubbleView(
                            icon: "drop.fill",
                            color: AppColors.drinkBlue,
                            capybaraPosition: capybaraPosition,
                            isLeft: false,
                            screenWidth: geometry.size.width
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        AppColors.background
            .ignoresSafeArea()
        
        ThrownItemView(
            emoji: "🥕",
            startPosition: CGPoint(x: 200, y: 600),
            endPosition: CGPoint(x: 200, y: 300),
            onComplete: {}
        )
    }
}


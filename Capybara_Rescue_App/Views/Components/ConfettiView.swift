import SwiftUI

// MARK: - Confetti View
/// Raining confetti overlay when food, drink, or happiness reaches 100.
struct ConfettiView: View {
    let isActive: Bool
    let onComplete: () -> Void
    
    @State private var showParticles = false
    
    private let particleCount = 70
    private let duration: Double = 2.5
    
    private static let confettiColors: [Color] = [
        Color(hex: "FFD700"), // Gold
        Color(hex: "FFA500"), // Orange
        Color(hex: "FF69B4"), // Pink
        Color(hex: "00CED1"), // Turquoise
        Color(hex: "98FB98"), // Pale green
        Color(hex: "FF6347"), // Tomato
        Color(hex: "9370DB"), // Purple
        Color.white
    ]
    
    var body: some View {
        if isActive {
            GeometryReader { geometry in
                ZStack {
                    ForEach(0..<particleCount, id: \.self) { index in
                        ConfettiParticleView(
                            color: Self.confettiColors[index % Self.confettiColors.count],
                            screenWidth: geometry.size.width,
                            screenHeight: geometry.size.height,
                            delay: Double(index) / Double(particleCount) * 0.2,
                            duration: duration + Double.random(in: -0.2...0.3),
                            isAnimating: showParticles
                        )
                    }
                }
                .allowsHitTesting(false)
                .onAppear {
                    showParticles = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.3) {
                        onComplete()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Single Confetti Particle
private struct ConfettiParticleView: View {
    let color: Color
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    let delay: Double
    let duration: Double
    let isAnimating: Bool
    
    @State private var yOffset: CGFloat = 0
    @State private var xOffset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1
    
    private let startX: CGFloat
    private let size: CGFloat
    private let isCircle: Bool
    
    init(color: Color, screenWidth: CGFloat, screenHeight: CGFloat, delay: Double, duration: Double, isAnimating: Bool) {
        self.color = color
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        self.delay = delay
        self.duration = duration
        self.isAnimating = isAnimating
        self.startX = CGFloat.random(in: 0...screenWidth)
        self.size = CGFloat.random(in: 6...14)
        self.isCircle = Bool.random()
    }
    
    var body: some View {
        Group {
            if isCircle {
                Circle().fill(color)
            } else {
                RoundedRectangle(cornerRadius: 2).fill(color)
            }
        }
        .frame(width: size, height: isCircle ? size : size * 0.6)
        .position(x: startX + xOffset, y: -10 + yOffset)
        .rotationEffect(.degrees(rotation))
        .opacity(opacity)
        .onChange(of: isAnimating) { _, animating in
            if animating {
                animateFall()
            }
        }
        .onAppear {
            if isAnimating {
                animateFall()
            }
        }
    }
    
    private func animateFall() {
        let fallDistance = screenHeight + 50
        
        withAnimation(.easeIn(duration: duration).delay(delay)) {
            yOffset = fallDistance
            xOffset = 0
            rotation = Double.random(in: 360...720)
            opacity = 0
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "1a1a2e").ignoresSafeArea()
        ConfettiView(isActive: true, onComplete: {})
    }
}

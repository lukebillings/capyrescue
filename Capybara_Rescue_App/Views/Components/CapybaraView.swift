import SwiftUI

// MARK: - Capybara View
struct CapybaraView: View {
    let emotion: CapybaraEmotion
    let equippedAccessories: [String]
    let onPet: () -> Void
    
    @State private var isPressed = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var heartOffset: CGFloat = 0
    @State private var showHeart = false
    
    var body: some View {
        ZStack {
            // Glow effect behind capybara
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            emotionColor.opacity(0.3),
                            emotionColor.opacity(0.1),
                            .clear
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .scaleEffect(pulseScale)
            
            // Main capybara body
            VStack(spacing: 0) {
                // Accessories on top (hats)
                if let hatAccessory = equippedHat {
                    Text(hatAccessory.emoji)
                        .font(.system(size: 50))
                        .offset(y: 20)
                }
                
                ZStack {
                    // Capybara body
                    CapybaraBody(emotion: emotion)
                    
                    // Glasses overlay
                    if let glassesAccessory = equippedGlasses {
                        Text(glassesAccessory.emoji)
                            .font(.system(size: 40))
                            .offset(y: -25)
                    }
                }
                
                // Shoes at bottom
                if let shoesAccessory = equippedShoes {
                    HStack(spacing: 30) {
                        Text(shoesAccessory.emoji)
                            .font(.system(size: 30))
                        Text(shoesAccessory.emoji)
                            .font(.system(size: 30))
                            .scaleEffect(x: -1, y: 1)
                    }
                    .offset(y: -10)
                }
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            
            // Floating heart animation
            if showHeart {
                Text("❤️")
                    .font(.system(size: 40))
                    .offset(y: heartOffset - 100)
                    .opacity(heartOffset < -50 ? 0 : 1)
                    .animation(.easeOut(duration: 0.8), value: heartOffset)
            }
        }
        .onTapGesture {
            handlePet()
        }
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onAppear {
            startPulseAnimation()
        }
    }
    
    private var emotionColor: Color {
        switch emotion {
        case .happy: return .pink
        case .neutral: return .orange
        case .sad: return .blue
        }
    }
    
    private var equippedHat: AccessoryItem? {
        // Find any equipped hat
        AccessoryItem.allItems.first { item in
            equippedAccessories.contains(item.id) && item.isHat
        }
    }
    
    private var equippedGlasses: AccessoryItem? {
        // No longer used - kept for compatibility
        return nil
    }
    
    private var equippedShoes: AccessoryItem? {
        // No longer used - kept for compatibility
        return nil
    }
    
    private func handlePet() {
        HapticManager.shared.petCapybara()
        onPet()
        
        // Show heart animation
        showHeart = true
        heartOffset = 0
        
        withAnimation(.easeOut(duration: 0.8)) {
            heartOffset = -80
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showHeart = false
            heartOffset = 0
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(
            .easeInOut(duration: 2)
            .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.1
        }
    }
}

// MARK: - Capybara Body
struct CapybaraBody: View {
    let emotion: CapybaraEmotion
    
    var body: some View {
        ZStack {
            // Main body
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "8B7355"), Color(hex: "6B5344")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 180, height: 140)
                .offset(y: 30)
            
            // Head
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "9B8465"), Color(hex: "7B6454")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 140, height: 120)
            
            // Snout
            Ellipse()
                .fill(Color(hex: "A99275"))
                .frame(width: 80, height: 50)
                .offset(y: 25)
            
            // Nose
            Ellipse()
                .fill(Color(hex: "3D3D3D"))
                .frame(width: 25, height: 18)
                .offset(y: 15)
            
            // Eyes
            HStack(spacing: 40) {
                Eye(emotion: emotion)
                Eye(emotion: emotion)
            }
            .offset(y: -15)
            
            // Ears
            HStack(spacing: 100) {
                Ear()
                    .rotationEffect(.degrees(-15))
                Ear()
                    .rotationEffect(.degrees(15))
            }
            .offset(y: -50)
            
            // Mouth based on emotion
            EmotionMouth(emotion: emotion)
                .offset(y: 42)
            
            // Blush for happy emotion
            if emotion == .happy {
                HStack(spacing: 70) {
                    Circle()
                        .fill(Color.pink.opacity(0.4))
                        .frame(width: 20, height: 20)
                    Circle()
                        .fill(Color.pink.opacity(0.4))
                        .frame(width: 20, height: 20)
                }
                .offset(y: 5)
            }
            
            // Tear for sad emotion
            if emotion == .sad {
                Circle()
                    .fill(Color.cyan.opacity(0.6))
                    .frame(width: 8, height: 12)
                    .offset(x: -25, y: 0)
            }
        }
    }
}

// MARK: - Eye
struct Eye: View {
    let emotion: CapybaraEmotion
    
    var body: some View {
        ZStack {
            // Eye white
            Ellipse()
                .fill(.white)
                .frame(width: 28, height: eyeHeight)
            
            // Pupil
            if emotion != .happy {
                Circle()
                    .fill(Color(hex: "2D2D2D"))
                    .frame(width: 14, height: 14)
                    .offset(y: emotion == .sad ? 2 : 0)
            }
            
            // Happy eyes are curved lines
            if emotion == .happy {
                HappyEyeCurve()
            }
            
            // Eye shine
            if emotion != .happy {
                Circle()
                    .fill(.white.opacity(0.8))
                    .frame(width: 5, height: 5)
                    .offset(x: -3, y: -3)
            }
        }
    }
    
    private var eyeHeight: CGFloat {
        switch emotion {
        case .happy: return 8
        case .neutral: return 24
        case .sad: return 20
        }
    }
}

// MARK: - Happy Eye Curve
struct HappyEyeCurve: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 5))
            path.addQuadCurve(
                to: CGPoint(x: 20, y: 5),
                control: CGPoint(x: 10, y: -8)
            )
        }
        .stroke(Color(hex: "2D2D2D"), lineWidth: 3)
        .frame(width: 20, height: 10)
    }
}

// MARK: - Emotion Mouth
struct EmotionMouth: View {
    let emotion: CapybaraEmotion
    
    var body: some View {
        switch emotion {
        case .happy:
            // Big smile
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addQuadCurve(
                    to: CGPoint(x: 40, y: 0),
                    control: CGPoint(x: 20, y: 20)
                )
            }
            .stroke(Color(hex: "3D3D3D"), lineWidth: 3)
            .frame(width: 40, height: 20)
            
        case .neutral:
            // Straight line
            Rectangle()
                .fill(Color(hex: "3D3D3D"))
                .frame(width: 25, height: 3)
                .cornerRadius(2)
            
        case .sad:
            // Frown
            Path { path in
                path.move(to: CGPoint(x: 0, y: 10))
                path.addQuadCurve(
                    to: CGPoint(x: 30, y: 10),
                    control: CGPoint(x: 15, y: 0)
                )
            }
            .stroke(Color(hex: "3D3D3D"), lineWidth: 3)
            .frame(width: 30, height: 15)
        }
    }
}

// MARK: - Ear
struct Ear: View {
    var body: some View {
        Ellipse()
            .fill(Color(hex: "7B6454"))
            .frame(width: 25, height: 20)
            .overlay(
                Ellipse()
                    .fill(Color(hex: "A99275"))
                    .frame(width: 15, height: 12)
            )
    }
}

#Preview {
    ZStack {
        AppColors.background
            .ignoresSafeArea()
        
        VStack(spacing: 40) {
            CapybaraView(emotion: .happy, equippedAccessories: ["crown", "sunglasses"], onPet: {})
            CapybaraView(emotion: .neutral, equippedAccessories: [], onPet: {})
            CapybaraView(emotion: .sad, equippedAccessories: [], onPet: {})
        }
        .scaleEffect(0.5)
    }
}


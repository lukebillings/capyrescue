import SwiftUI

// MARK: - Tutorial Preference Key
struct TutorialPreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        let next = nextValue()
        for (key, rect) in next {
            value[key] = rect
        }
    }
}

// MARK: - Tutorial Step
enum TutorialStep: Int, CaseIterable {
    case food = 0
    case drink = 1
    case happy = 2
    case statsWarning = 3
    case items = 4
    case shop = 5
    case achievements = 6
    
    var title: String {
        switch self {
        case .food: return "Food"
        case .drink: return "Drink"
        case .happy: return "Happy"
        case .statsWarning: return "Keep stats above 0"
        case .items: return "Items"
        case .shop: return "Shop"
        case .achievements: return "Achievements"
        }
    }
    
    var message: String {
        switch self {
        case .food:
            return "Try to keep food score over 80 points.\nIncrease food score by feeding it foods.\nMax food score is 100 points.\nFood score decrease 1 point per hour."
        case .drink:
            return "Try to keep drink score over 80 points.\nIncrease drink score by giving it drinks.\nMax drink score is 100 points.\nDrink score decrease 1 point per hour."
        case .happy:
            return "Try to keep happy score over 80 points.\nIncrease happy score by petting it.\nMax happy score is 100 points.\nHappy score decrease 1 point per hour."
        case .statsWarning:
            return "⚠️ If all stats reach 0, your capybara will run away!"
        case .items:
            return "Your capybara might like to have some accessories.\nYou can buy them using coins in the Items menu."
        case .shop:
            return "You can buy more coins from the shop."
        case .achievements:
            return "Keep food, drink, and happiness all above 50 for consecutive days to earn achievement rewards!"
        }
    }
    
    var highlightKey: String {
        // Highlight the stat/thing being talked about
        switch self {
        case .food: return "food_stat"
        case .drink: return "drink_stat"
        case .happy: return "happy_stat"
        case .statsWarning: return "food_stat" // Highlight all stats, but we'll use food_stat as anchor
        case .items: return "items_button"
        case .shop: return "shop_button"
        case .achievements: return "achievements_button"
        }
    }
    
    var targetKey: String? {
        // Where to tap (button or capybara)
        switch self {
        case .food: return "food_button"
        case .drink: return "drink_button"
        case .happy: return "capybara_tap"
        case .statsWarning: return nil // No tap target for warning
        case .items: return nil
        case .shop: return nil
        case .achievements: return nil
        }
    }
}

// MARK: - Tutorial Overlay
struct TutorialOverlay: View {
    @EnvironmentObject var gameManager: GameManager
    @Binding var currentStep: TutorialStep?
    @State private var elementFrames: [String: CGRect] = [:]
    @State private var globalFrame: CGRect = .zero
    
    var body: some View {
        if let step = currentStep {
            GeometryReader { geometry in
                ZStack {
                    // Dark overlay with cutout (rendered first, at bottom layer)
                    if let highlightFrame = elementFrames[step.highlightKey] {
                        // Full screen dark overlay
                        Color.black.opacity(0.7)
                            .ignoresSafeArea()
                            .mask(
                                // Create mask that cuts out the highlighted area
                                ZStack {
                                    Rectangle()
                                        .fill(Color.black)
                                    
                                    RoundedRectangle(cornerRadius: 20)
                                        .frame(
                                            width: highlightFrame.width + 20,
                                            height: highlightFrame.height + 20
                                        )
                                        .position(
                                            x: highlightFrame.midX,
                                            y: highlightFrame.midY
                                        )
                                        .blendMode(.destinationOut)
                                }
                            )
                            .zIndex(0)
                        
                        // Glow effect around highlighted element
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppColors.accent, lineWidth: 4)
                            .frame(width: highlightFrame.width + 20, height: highlightFrame.height + 20)
                            .position(
                                x: highlightFrame.midX,
                                y: highlightFrame.midY
                            )
                            .shadow(color: AppColors.accent.opacity(0.8), radius: 20)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: highlightFrame)
                            .zIndex(1)
                    } else {
                        // Fallback if frame not found yet
                        Color.black.opacity(0.7)
                            .ignoresSafeArea()
                            .zIndex(0)
                    }
                    
                    // Instruction card at top (above overlay)
                    VStack {
                        instructionCard(for: step)
                            .padding(.horizontal, 24)
                            .padding(.top, 60)
                        
                        Spacer()
                    }
                    .zIndex(20)
                    
                    // Tap indicator on target element (where to tap)
                    if let targetKey = step.targetKey,
                       let targetFrame = elementFrames[targetKey] {
                        TapIndicatorView()
                            .position(
                                x: targetFrame.midX,
                                y: targetFrame.maxY + 50
                            )
                            .zIndex(25)
                    } else if let highlightFrame = elementFrames[step.highlightKey] {
                        // For items and shop, tap indicator is on the highlighted element itself
                        TapIndicatorView()
                            .position(
                                x: highlightFrame.midX,
                                y: highlightFrame.maxY + 50
                            )
                            .zIndex(25)
                    }
                    
                    // Arrow pointing from stat to button (for food, drink, happy)
                    if let targetKey = step.targetKey,
                       let targetFrame = elementFrames[targetKey],
                       let highlightFrame = elementFrames[step.highlightKey],
                       targetKey != step.highlightKey {
                        ArrowView(
                            from: CGPoint(
                                x: highlightFrame.midX,
                                y: highlightFrame.midY
                            ),
                            to: CGPoint(
                                x: targetFrame.midX,
                                y: targetFrame.midY
                            )
                        )
                        .zIndex(15)
                    }
                    
                    // Hand emoji pointing to the target element (rendered last, highest zIndex)
                    if let targetKey = step.targetKey,
                       let targetFrame = elementFrames[targetKey] {
                        HandPointingView(targetPosition: CGPoint(x: targetFrame.midX, y: targetFrame.midY))
                            .zIndex(100)
                    } else if let highlightFrame = elementFrames[step.highlightKey] {
                        // For items and shop, point to the highlighted element itself
                        HandPointingView(targetPosition: CGPoint(x: highlightFrame.midX, y: highlightFrame.midY))
                            .zIndex(100)
                    }
                }
                .compositingGroup()
                .onAppear {
                    globalFrame = geometry.frame(in: .global)
                }
            }
            .onPreferenceChange(TutorialPreferenceKey.self) { frames in
                elementFrames = frames
            }
        }
    }
    
    @ViewBuilder
    private func instructionCard(for step: TutorialStep) -> some View {
        VStack(spacing: 16) {
            Text(step.title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            if step == .achievements {
                VStack(spacing: 12) {
                    Text(step.message)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                    
                    HStack(spacing: 8) {
                        Text("You can check your streaks with the")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))
                        
                        Image(systemName: "medal.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                    }
                }
            } else {
                Text(step.message)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            Button(action: {
                if let nextStep = TutorialStep(rawValue: step.rawValue + 1) {
                    currentStep = nextStep
                } else {
                    // Tutorial complete
                    gameManager.gameState.hasCompletedTutorial = true
                    currentStep = nil
                }
            }) {
                Text(step.rawValue < TutorialStep.allCases.count - 1 ? "Next" : "Got it!")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppColors.accent)
                    )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}


// MARK: - Arrow View
struct ArrowView: View {
    let from: CGPoint
    let to: CGPoint
    
    var body: some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        .stroke(AppColors.accent, lineWidth: 3)
        .shadow(color: AppColors.accent.opacity(0.5), radius: 10)
        .overlay(
            // Arrow head
            Triangle()
                .fill(AppColors.accent)
                .frame(width: 20, height: 20)
                .rotationEffect(.degrees(angle))
                .position(to)
        )
    }
    
    private var angle: Double {
        let dx = to.x - from.x
        let dy = to.y - from.y
        return atan2(dy, dx) * 180 / .pi
    }
}

// MARK: - Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Hand Pointing View
struct HandPointingView: View {
    let targetPosition: CGPoint
    @State private var animationOffset: CGFloat = 0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            
            // Position hand emoji above the instruction card, pointing down toward target
            let handX = screenWidth / 2
            let handY: CGFloat = 180 // Position above instruction card
            
            // Calculate angle to point toward target
            // The 👆 emoji naturally points up, so we need to rotate it to point toward target
            let dx = targetPosition.x - handX
            let dy = targetPosition.y - handY
            // atan2 gives angle from x-axis, but emoji points up, so subtract 90
            let angle = atan2(dy, dx) * 180 / .pi - 90
            
            ZStack {
                // Shadow/glow behind hand for visibility
                Text("👆")
                    .font(.system(size: 60))
                    .foregroundStyle(.black.opacity(0.3))
                    .blur(radius: 4)
                    .offset(x: 2, y: 2)
                
                Text("👆")
                    .font(.system(size: 60))
                    .rotationEffect(.degrees(angle))
                    .scaleEffect(scale)
                    .offset(y: animationOffset)
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 0)
            }
            .position(x: handX, y: handY)
            .allowsHitTesting(false)
            .compositingGroup()
            .onAppear {
                // Bouncing animation
                withAnimation(
                    .easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true)
                ) {
                    animationOffset = -8
                }
                
                // Pulsing scale animation
                withAnimation(
                    .easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true)
                ) {
                    scale = 1.1
                }
            }
        }
    }
}

// MARK: - Tap Indicator View
struct TapIndicatorView: View {
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    
    var body: some View {
        ZStack {
            // Outer pulsing circle
            Circle()
                .fill(AppColors.accent.opacity(0.3))
                .frame(width: 80, height: 80)
                .scaleEffect(scale)
                .opacity(opacity)
            
            // Middle circle
            Circle()
                .fill(AppColors.accent.opacity(0.5))
                .frame(width: 60, height: 60)
                .scaleEffect(scale * 0.8)
            
            // Inner circle with hand icon
            ZStack {
                Circle()
                    .fill(AppColors.accent)
                    .frame(width: 50, height: 50)
                
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.0)
                .repeatForever(autoreverses: false)
            ) {
                scale = 1.5
                opacity = 0.0
            }
        }
    }
}

// MARK: - Tutorial Modifier
struct TutorialModifier: ViewModifier {
    let key: String
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: TutorialPreferenceKey.self,
                            value: [key: geometry.frame(in: .global)]
                        )
                }
            )
    }
}

extension View {
    func tutorialHighlight(key: String) -> some View {
        modifier(TutorialModifier(key: key))
    }
}

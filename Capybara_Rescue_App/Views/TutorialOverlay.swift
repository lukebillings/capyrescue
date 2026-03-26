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

// MARK: - Tutorial Step (interactive walkthrough)
enum TutorialStep: Int, CaseIterable {
    case feedFood = 0
    case praiseFood = 1
    case feedDrink = 2
    case praiseDrink = 3
    case petHappy = 4
    case praiseHappy = 5
    case itemsIntro = 6
    
    var highlightKey: String {
        switch self {
        case .feedFood: return "food_button"
        case .praiseFood: return ""
        case .feedDrink: return "drink_button"
        case .praiseDrink: return ""
        case .petHappy: return "capybara_tap"
        case .praiseHappy: return ""
        case .itemsIntro: return "items_button"
        }
    }
    
    /// When true, the user completes the step by playing (feeding, drinking, petting). Overlay does not intercept taps.
    var waitsForUserPlayAction: Bool {
        switch self {
        case .feedFood, .feedDrink, .petHappy: return true
        default: return false
        }
    }
    
    var showFingerAndTapRing: Bool {
        waitsForUserPlayAction || self == .itemsIntro
    }
}

// MARK: - Tutorial Overlay
struct TutorialOverlay: View {
    @EnvironmentObject var gameManager: GameManager
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Binding var currentStep: TutorialStep?
    @Binding var showPanel: Bool
    
    @State private var elementFrames: [String: CGRect] = [:]
    @State private var foodBaseline: Int = 0
    @State private var drinkBaseline: Int = 0
    @State private var happinessBaseline: Int = 0
    
    var body: some View {
        if let step = currentStep {
            GeometryReader { geometry in
                ZStack {
                    // No dim: keep the game at normal brightness. Opaque steps still use an invisible layer so taps don't reach the game until Next/Got it.
                    if step.highlightKey.isEmpty {
                        Color.clear
                            .ignoresSafeArea()
                            .contentShape(Rectangle())
                            .allowsHitTesting(!step.waitsForUserPlayAction)
                            .zIndex(0)
                    } else if let highlightFrame = elementFrames[step.highlightKey] {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppColors.paywallCTAGreen, lineWidth: 4)
                            .frame(width: highlightFrame.width + 20, height: highlightFrame.height + 20)
                            .position(
                                x: highlightFrame.midX,
                                y: highlightFrame.midY
                            )
                            .shadow(color: AppColors.paywallCTAGreen.opacity(0.7), radius: 20)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: highlightFrame)
                            .allowsHitTesting(false)
                            .zIndex(1)
                    } else {
                        Color.clear
                            .ignoresSafeArea()
                            .contentShape(Rectangle())
                            .allowsHitTesting(!step.waitsForUserPlayAction)
                            .zIndex(0)
                    }
                    
                    VStack {
                        instructionCard(for: step, localization: localizationManager)
                            .padding(.horizontal, 24)
                            .padding(.top, 60)
                        
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .zIndex(20)
                    .allowsHitTesting(!step.waitsForUserPlayAction)
                    
                    if step.showFingerAndTapRing, let highlightFrame = elementFrames[step.highlightKey], !step.highlightKey.isEmpty {
                        TapIndicatorView()
                            .position(
                                x: highlightFrame.midX,
                                y: highlightFrame.maxY + 50
                            )
                            .allowsHitTesting(false)
                            .zIndex(25)
                        
                        HandPointingView(targetPosition: CGPoint(x: highlightFrame.midX, y: highlightFrame.midY))
                            .allowsHitTesting(false)
                            .zIndex(100)
                    }
                }
                .onAppear {
                    captureBaselines(for: step)
                }
            }
            .onChange(of: currentStep) { _, newStep in
                if let s = newStep {
                    captureBaselines(for: s)
                }
            }
            .onPreferenceChange(TutorialPreferenceKey.self) { frames in
                elementFrames = frames
            }
            .onChange(of: gameManager.gameState.food) { _, newValue in
                guard currentStep == .feedFood, newValue > foodBaseline else { return }
                showPanel = false
                withAnimation {
                    currentStep = .praiseFood
                }
            }
            .onChange(of: gameManager.gameState.drink) { _, newValue in
                guard currentStep == .feedDrink, newValue > drinkBaseline else { return }
                showPanel = false
                withAnimation {
                    currentStep = .praiseDrink
                }
            }
            .onChange(of: gameManager.gameState.happiness) { _, newValue in
                guard currentStep == .petHappy, newValue > happinessBaseline else { return }
                showPanel = false
                withAnimation {
                    currentStep = .praiseHappy
                }
            }
            .id(localizationManager.currentLanguage)
        }
    }
    
    private func captureBaselines(for step: TutorialStep) {
        switch step {
        case .feedFood:
            gameManager.prepareWalkthroughPlayStep(stat: .food)
            foodBaseline = gameManager.gameState.food
        case .feedDrink:
            gameManager.prepareWalkthroughPlayStep(stat: .drink)
            drinkBaseline = gameManager.gameState.drink
        case .petHappy:
            gameManager.prepareWalkthroughPlayStep(stat: .happiness)
            happinessBaseline = gameManager.gameState.happiness
        default:
            break
        }
    }
    
    @ViewBuilder
    private func instructionCard(for step: TutorialStep, localization: LocalizationManager) -> some View {
        VStack(spacing: 16) {
            Text(tutorialTitle(for: step, localization: localization))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            Group {
                if step == .itemsIntro {
                    itemsIntroMessage(localization: localization)
                } else {
                    Text(tutorialMessage(for: step, localization: localization))
                }
            }
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundStyle(.primary.opacity(0.85))
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            
            if !step.waitsForUserPlayAction {
                Button(action: {
                    HapticManager.shared.buttonPress()
                    advance(from: step)
                }) {
                    Text(step == .itemsIntro ? localization.string(for: "common.gotIt") : localization.string(for: "common.next"))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AppColors.paywallCTAGreen)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(AppColors.paywallCTABorder, lineWidth: 2)
                                )
                        )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(.primary.opacity(0.12), lineWidth: 1)
                )
        )
    }
    
    private func tutorialTitle(for step: TutorialStep, localization: LocalizationManager) -> String {
        switch step {
        case .feedFood: return localization.string(for: "tutorial.walkthroughFoodTitle")
        case .praiseFood, .praiseDrink, .praiseHappy: return localization.string(for: "tutorial.walkthroughGoodJobTitle")
        case .feedDrink: return localization.string(for: "tutorial.walkthroughDrinkTitle")
        case .petHappy: return localization.string(for: "tutorial.walkthroughHappyTitle")
        case .itemsIntro: return localization.string(for: "tutorial.walkthroughItemsTitle")
        }
    }
    
    private func tutorialMessage(for step: TutorialStep, localization: LocalizationManager) -> String {
        switch step {
        case .feedFood: return localization.string(for: "tutorial.walkthroughFoodMessage")
        case .praiseFood, .praiseDrink, .praiseHappy: return localization.string(for: "tutorial.walkthroughGoodJobMessage")
        case .feedDrink: return localization.string(for: "tutorial.walkthroughDrinkMessage")
        case .petHappy: return localization.string(for: "tutorial.walkthroughHappyMessage")
        case .itemsIntro:
            return ""
        }
    }
    
    private func itemsIntroMessage(localization: LocalizationManager) -> Text {
        let part1 = String(
            format: localization.string(for: "tutorial.walkthroughItemsMessagePart1"),
            localization.string(for: "common.getMore")
        )
        let part2Leading = localization.string(for: "tutorial.walkthroughItemsMessagePart2Leading")
        let part2Trailing = localization.string(for: "tutorial.walkthroughItemsMessagePart2Trailing")
        let medal = Text(Image(systemName: "medal.fill"))
            .font(.system(size: 17, weight: .semibold, design: .rounded))
        return Text(part1)
            + Text("\n\n")
            + Text(part2Leading)
            + medal
            + Text(part2Trailing)
    }
    
    private func advance(from step: TutorialStep) {
        showPanel = false
        switch step {
        case .praiseFood:
            currentStep = .feedDrink
        case .praiseDrink:
            currentStep = .petHappy
        case .praiseHappy:
            currentStep = .itemsIntro
        case .itemsIntro:
            gameManager.gameState.hasCompletedTutorial = true
            currentStep = nil
        default:
            break
        }
    }
}

// MARK: - Hand Pointing View (finger cues toward tap target)
struct HandPointingView: View {
    let targetPosition: CGPoint
    @State private var animationOffset: CGFloat = 0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        let offsetAbove: CGFloat = 56
        let handX = targetPosition.x
        let handY = targetPosition.y - offsetAbove
        let dx = targetPosition.x - handX
        let dy = targetPosition.y - handY
        let angle = atan2(dy, dx) * 180 / .pi - 90
        
        ZStack {
            Text("👆")
                .font(.system(size: 56))
                .foregroundStyle(.black.opacity(0.3))
                .blur(radius: 4)
                .offset(x: 2, y: 2)
            
            Text("👆")
                .font(.system(size: 56))
                .rotationEffect(.degrees(angle))
                .scaleEffect(scale)
                .offset(y: animationOffset)
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 0)
        }
        .position(x: handX, y: handY)
        .allowsHitTesting(false)
        .compositingGroup()
        .onAppear {
            withAnimation(
                .easeInOut(duration: 0.6)
                .repeatForever(autoreverses: true)
            ) {
                animationOffset = -8
            }
            
            withAnimation(
                .easeInOut(duration: 0.8)
                .repeatForever(autoreverses: true)
            ) {
                scale = 1.1
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
            Circle()
                .fill(AppColors.accent.opacity(0.3))
                .frame(width: 80, height: 80)
                .scaleEffect(scale)
                .opacity(opacity)
            
            Circle()
                .fill(AppColors.accent.opacity(0.5))
                .frame(width: 60, height: 60)
                .scaleEffect(scale * 0.8)
            
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
                            value: key.isEmpty ? [:] : [key: geometry.frame(in: .global)]
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

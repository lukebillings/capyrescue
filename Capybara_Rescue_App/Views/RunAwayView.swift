import SwiftUI

// MARK: - Run Away View
struct RunAwayView: View {
    let onRestart: () -> Void
    
    @State private var opacity: Double = 0
    @State private var capybaraOffset: CGFloat = 0
    @State private var showMessage = false
    
    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Sad capybara walking away
                ZStack {
                    // Footprints
                    HStack(spacing: 20) {
                        ForEach(0..<5, id: \.self) { i in
                            Text("🐾")
                                .font(.system(size: 20))
                                .opacity(Double(5 - i) / 5.0)
                                .offset(x: capybaraOffset - CGFloat(i * 40))
                        }
                    }
                    .offset(y: 60)
                    
                    // Capybara
                    VStack(spacing: 8) {
                        Text("🦫")
                            .font(.system(size: 80))
                            .scaleEffect(x: -1, y: 1) // Facing away
                        
                        Text("💔")
                            .font(.system(size: 30))
                            .offset(y: -20)
                    }
                    .offset(x: capybaraOffset)
                }
                .frame(height: 150)
                
                if showMessage {
                    VStack(spacing: 16) {
                        Text("Your Capybara Ran Away...")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("All stats reached zero and your capybara\ndecided to find a new home.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                        
                        // Restart button
                        Button(action: {
                            HapticManager.shared.buttonPress()
                            onRestart()
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 18, weight: .semibold))
                                
                                Text("Rescue Another Capybara")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .shadow(color: Color(hex: "FF6B6B").opacity(0.5), radius: 15, x: 0, y: 8)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.top, 20)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                
                Spacer()
            }
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) {
                opacity = 1
            }
            
            withAnimation(.easeInOut(duration: 2)) {
                capybaraOffset = 200
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showMessage = true
                }
            }
        }
    }
}

#Preview {
    RunAwayView(onRestart: {})
}


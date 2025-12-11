import SwiftUI

// MARK: - Capybara Name View
struct CapybaraNameView: View {
    let name: String
    let onRename: () -> Void
    let onAchievements: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Capybara image in circle
            Image("iconcapybara")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.3), lineWidth: 2)
                )
            
            // Name with decorative underline
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                // Decorative line
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "FFD700").opacity(0.8),
                                Color(hex: "FFD700").opacity(0.2),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 2)
                    .frame(maxWidth: 150)
            }
            
            Spacer()
            
            // Achievements button
            Button(action: {
                HapticManager.shared.buttonPress()
                onAchievements()
            }) {
                Image(systemName: "medal.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .buttonStyle(ScaleButtonStyle())
            
            // Edit button
            Button(action: {
                HapticManager.shared.buttonPress()
                onRename()
            }) {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }
}

// MARK: - Rename Sheet
struct RenameSheet: View {
    @Binding var isPresented: Bool
    @Binding var name: String
    let onSave: (String) -> Void
    
    @State private var editedName: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            // Handle bar
            Capsule()
                .fill(.white.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
            
            Text("Rename Your Capybara")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            // Text field
            TextField("", text: $editedName)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .focused($isFocused)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)
            
            // Buttons
            HStack(spacing: 16) {
                Button("Cancel") {
                    HapticManager.shared.buttonPress()
                    isPresented = false
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.1))
                )
                
                Button("Save") {
                    HapticManager.shared.purchaseSuccess()
                    if !editedName.isEmpty {
                        onSave(editedName)
                    }
                    isPresented = false
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "4CAF50"), Color(hex: "2E7D32")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .buttonStyle(ScaleButtonStyle())
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color(hex: "1a1a2e")
                .ignoresSafeArea()
        )
        .onAppear {
            editedName = name
            isFocused = true
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        
        CapybaraNameView(name: "Cappuccino", onRename: {}, onAchievements: {})
    }
}


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
                                AppColors.paywallCTAGreen.opacity(0.7),
                                AppColors.paywallCTAGreen.opacity(0.15),
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
                .fill(Color(hex: "1a1a2e").opacity(0.25))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
            
            Text(L("rename.title"))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "1a1a2e"))
            
            // Text field
            TextField("", text: $editedName)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: "1a1a2e"))
                .multilineTextAlignment(.center)
                .focused($isFocused)
                .tint(AppColors.paywallCTAGreen)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.75))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppColors.paywallCTABorder.opacity(0.8), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)
            
            // Buttons
            HStack(spacing: 16) {
                Button(L("common.cancel")) {
                    HapticManager.shared.buttonPress()
                    isPresented = false
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: "1a1a2e").opacity(0.8))
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.65))
                        .overlay(
                            Capsule()
                                .stroke(Color(hex: "1a1a2e").opacity(0.10), lineWidth: 1)
                        )
                )
                
                Button(L("common.save")) {
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
                        .fill(AppColors.paywallCTAGreen)
                        .overlay(
                            Capsule()
                                .stroke(AppColors.paywallCTABorder, lineWidth: 2)
                        )
                )
            }
            .buttonStyle(ScaleButtonStyle())
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            AppColors.background.ignoresSafeArea()
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


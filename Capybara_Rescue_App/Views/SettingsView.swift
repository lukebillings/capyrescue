import SwiftUI
import StoreKit

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.requestReview) private var requestReview
    @ObservedObject private var settingsManager = SettingsManager.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    @State private var showRenameSheet = false
    @State private var showLanguagePicker = false
    
    private let termsURL = "https://lukebillings.github.io/capyrescue/termsandconditions/"
    private let privacyURL = "https://lukebillings.github.io/capyrescue/privacypolicy/"
    private let shareAppURL = "https://apps.apple.com/gb/app/capyrescue/id6756495842"
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: colorScheme == .dark ? "1a1a2e" : "FFF8E7")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Toggles section
                        VStack(spacing: 0) {
                            SettingsRow(
                                icon: "speaker.wave.2.fill",
                                title: L("settings.sound"),
                                subtitle: L("settings.soundSubtitle")
                            ) {
                                Toggle("", isOn: $settingsManager.soundEnabled)
                                    .labelsHidden()
                                    .tint(Color(hex: "1a5f1a"))
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.2))
                                .padding(.leading, 56)
                            
                            SettingsRow(
                                icon: "bell.fill",
                                title: L("settings.notifications"),
                                subtitle: L("settings.notificationsSubtitle")
                            ) {
                                Toggle("", isOn: $settingsManager.notificationsEnabled)
                                    .labelsHidden()
                                    .tint(Color(hex: "1a5f1a"))
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.2))
                                .padding(.leading, 56)
                            
                            SettingsRow(
                                icon: "hand.tap.fill",
                                title: L("settings.hapticFeedback"),
                                subtitle: L("settings.hapticSubtitle")
                            ) {
                                Toggle("", isOn: $settingsManager.hapticEnabled)
                                    .labelsHidden()
                                    .tint(Color(hex: "1a5f1a"))
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white.opacity(0.08))
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Actions section
                        VStack(spacing: 0) {
                            SettingsActionRow(
                                icon: "globe",
                                title: L("settings.language"),
                                subtitle: LocalizationManager.supportedLanguages.first { $0.code == localizationManager.currentLanguage }?.displayName ?? L("settings.languageSubtitle")
                            ) {
                                HapticManager.shared.buttonPress()
                                showLanguagePicker = true
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.2))
                                .padding(.leading, 56)
                            
                            SettingsActionRow(
                                icon: "pencil",
                                title: L("settings.renameCapybara"),
                                subtitle: gameManager.gameState.capybaraName
                            ) {
                                HapticManager.shared.buttonPress()
                                showRenameSheet = true
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.2))
                                .padding(.leading, 56)
                            
                            SettingsActionRow(
                                icon: "star.fill",
                                title: L("settings.rateApp"),
                                subtitle: L("settings.rateSubtitle")
                            ) {
                                HapticManager.shared.buttonPress()
                                requestReview()
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.2))
                                .padding(.leading, 56)
                            
                            SettingsShareRow(
                                icon: "square.and.arrow.up",
                                title: L("settings.shareApp"),
                                subtitle: L("settings.shareSubtitle"),
                                url: shareAppURL,
                                message: L("settings.shareMessage")
                            )
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white.opacity(0.08))
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        
                        // Links section
                        VStack(spacing: 0) {
                            SettingsLinkRow(
                                icon: "doc.text.fill",
                                title: L("settings.terms"),
                                url: termsURL
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.2))
                                .padding(.leading, 56)
                            
                            SettingsLinkRow(
                                icon: "hand.raised.fill",
                                title: L("settings.privacy"),
                                url: privacyURL
                            )
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white.opacity(0.08))
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle(L("settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticManager.shared.buttonPress()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.primary.opacity(0.7))
                    }
                }
            }
        }
        .sheet(isPresented: $showLanguagePicker) {
            LanguagePickerSheet(
                localizationManager: localizationManager,
                isPresented: $showLanguagePicker
            )
        }
        .sheet(isPresented: $showRenameSheet) {
            RenameSheet(
                isPresented: $showRenameSheet,
                name: $gameManager.gameState.capybaraName,
                onSave: { newName in
                    gameManager.renameCapybara(to: newName)
                }
            )
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Settings Row (with toggle)
private struct SettingsRow<T: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    @ViewBuilder let trailing: () -> T
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color(hex: "1a5f1a"))
                .frame(width: 28, alignment: .center)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.8))
            }
            
            Spacer()
            
            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Settings Action Row (tappable)
private struct SettingsActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: "1a5f1a"))
                    .frame(width: 28, alignment: .center)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(.primary.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Settings Share Row
private struct SettingsShareRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let url: String
    let message: String
    
    var body: some View {
        ShareLink(item: URL(string: url)!, subject: Text("CapyRescue"), message: Text(message)) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: "1a5f1a"))
                    .frame(width: 28, alignment: .center)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(.primary.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(TapGesture().onEnded { _ in
            HapticManager.shared.buttonPress()
        })
    }
}

// MARK: - Settings Link Row
private struct SettingsLinkRow: View {
    let icon: String
    let title: String
    let url: String
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        Button(action: { openURL(URL(string: url)!) }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: "1a5f1a"))
                    .frame(width: 28, alignment: .center)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.primary.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Language Picker Sheet
private struct LanguagePickerSheet: View {
    @ObservedObject var localizationManager: LocalizationManager
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: colorScheme == .dark ? "1a1a2e" : "FFF8E7")
                    .ignoresSafeArea()
                
                List {
                    ForEach(LocalizationManager.supportedLanguages, id: \.code) { lang in
                        Button(action: {
                            HapticManager.shared.buttonPress()
                            localizationManager.currentLanguage = lang.code
                            isPresented = false
                        }) {
                            HStack {
                                Text(lang.displayName)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color(hex: "1a5f1a"))
                                Spacer()
                                if localizationManager.currentLanguage == lang.code {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color(hex: "1a5f1a"))
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(L("settings.language"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticManager.shared.buttonPress()
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.primary.opacity(0.7))
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(GameManager())
}

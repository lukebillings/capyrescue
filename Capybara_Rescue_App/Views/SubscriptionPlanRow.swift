import SwiftUI

// MARK: - Subscription Plan Row (selectable option for shop premium plans)
struct SubscriptionPlanRow: View {
    let tier: SubscriptionManager.SubscriptionTier
    let title: String
    let subtext: String
    var subtextHighlight: String? = nil  // When set (e.g. "7-day free trial"), shown bold + gold below subtext
    let price: String
    let priceSubtext: String
    var priceSubtext2: String? = nil  // Optional line under price (e.g. "Only £2.49/month" for yearly)
    let badge: String?
    let savingsBadge: String?
    let features: [String]
    let isSelected: Bool
    let isProcessing: Bool
    let action: () -> Void
    
    private var accentColor: Color {
        isSelected ? Color(hex: "FFD700") : Color.white.opacity(0.7)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                // Top row: radio + title/subtext left, price + badges right
                HStack(alignment: .top, spacing: 10) {
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: isSelected ? "circle.inset.filled" : "circle")
                            .font(.system(size: 22))
                            .foregroundStyle(isSelected ? Color(hex: "FFD700") : .white.opacity(0.5))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            if !subtext.isEmpty {
                                Text(subtext)
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            if let highlight = subtextHighlight {
                                Text(highlight)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                        }
                        
                        Spacer(minLength: 8)
                    }
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        if let badge = badge, tier == .annual {
                            Text(badge)
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color(hex: "FFD700").opacity(0.9)))
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(price)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text(priceSubtext)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        if let line2 = priceSubtext2 {
                            Text(line2)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        if let savings = savingsBadge, tier == .annual {
                            Text(savings)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: "FFD700"))
                        }
                    }
                }
                
                // Benefits inside the rectangle
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(features, id: \.self) { feature in
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(accentColor)
                            Text(feature)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isSelected ? Color(hex: "FFD700").opacity(0.7) : Color.white.opacity(0.15),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isProcessing)
        .opacity(isProcessing ? 0.6 : 1)
    }
}

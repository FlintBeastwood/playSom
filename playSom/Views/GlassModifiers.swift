import SwiftUI

// MARK: - Design Tokens

extension Color {
    /// Vibrant electric teal — primary glassmorphism accent.
    static let somaAccent = Color(red: 0.05, green: 0.75, blue: 0.95)
    /// Rich royal purple — used in gradients alongside somaAccent.
    static let somaPurple = Color(red: 0.50, green: 0.20, blue: 0.85)
    
    /// Ambient glow colors
    static let glowTeal   = Color(red: 0.00, green: 0.95, blue: 1.00)
    static let glowPurple = Color(red: 0.65, green: 0.30, blue: 1.00)
    
    /// Premium solid bases
    static let darkObsidian = Color(red: 0.05, green: 0.05, blue: 0.08)
    static let lightCloud   = Color(red: 0.96, green: 0.96, blue: 0.98)
}

// MARK: - Glass Card Modifier

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 12
    var tint: Color           = .clear
    var shadowRadius: CGFloat = 8

    @AppStorage("isDarkMode") private var isDarkMode = false

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                
                if tint != .clear {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(tint.opacity(isDarkMode ? 0.06 : 0.03))
                }
                
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                isDarkMode ? .white.opacity(0.12) : .black.opacity(0.06),
                                isDarkMode ? .white.opacity(0.03) : .black.opacity(0.01)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.75
                    )
            }
            .shadow(
                color: Color.black.opacity(isDarkMode ? 0.25 : 0.06),
                radius: shadowRadius,
                x: 0,
                y: shadowRadius / 2
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 12, tint: Color = .clear, shadowRadius: CGFloat = 8) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, tint: tint, shadowRadius: shadowRadius))
    }
}


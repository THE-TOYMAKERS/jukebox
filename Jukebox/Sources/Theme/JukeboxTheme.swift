import SwiftUI

enum JukeboxTheme {
    // MARK: - Colors

    static let accentGradient = LinearGradient(
        colors: [Color(hex: "1DB954"), Color(hex: "1ED760")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let backgroundGradient = LinearGradient(
        colors: [Color(hex: "0D0D0D"), Color(hex: "1A1A2E"), Color(hex: "16213E")],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cardBackground = Color.white.opacity(0.06)
    static let cardBorder = Color.white.opacity(0.08)
    static let spotifyGreen = Color(hex: "1DB954")
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textTertiary = Color.white.opacity(0.35)
    static let destructive = Color(hex: "FF4757")

    // MARK: - Chat Bubble Colors

    static let chatColors: [String] = [
        "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4",
        "#FFEAA7", "#DDA0DD", "#98D8C8", "#F7DC6F",
        "#BB8FCE", "#85C1E9", "#F0B27A", "#82E0AA"
    ]

    static func randomChatColor() -> String {
        chatColors.randomElement() ?? "#FFFFFF"
    }

    // MARK: - Modifiers

    static func glassCard<S: Shape>(_ shape: S) -> some ViewModifier {
        GlassCardModifier(shape: shape)
    }
}

// MARK: - Glass Card Modifier

struct GlassCardModifier<S: Shape>: ViewModifier {
    let shape: S

    func body(content: Content) -> some View {
        content
            .background(
                shape
                    .fill(.ultraThinMaterial)
                    .overlay(
                        shape.stroke(JukeboxTheme.cardBorder, lineWidth: 0.5)
                    )
            )
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extensions

extension View {
    func glassCard() -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(JukeboxTheme.cardBorder, lineWidth: 0.5)
            )
    }

    func glassCardSmall() -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(JukeboxTheme.cardBorder, lineWidth: 0.5)
            )
    }
}

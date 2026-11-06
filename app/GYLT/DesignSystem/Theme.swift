import SwiftUI
import UIKit

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255, opacity: opacity)
    }

    /// Resolves per colour scheme, including a scheme forced with `.environment(\.colorScheme, …)`.
    init(light: UInt32, dark: UInt32) {
        self.init(UIColor { $0.userInterfaceStyle == .dark ? UIColor(Color(hex: dark)) : UIColor(Color(hex: light)) })
    }
}

/// Design tokens: "Meadow Dusk", soft. Aubergine ink and cream neutrals, lavender as the one primary,
/// pastel companions from the illustrations. Shape rule: cards 20, controls and inputs 12, buttons and chips are capsules.
enum Theme {
    // Primary: buttons, toggles, rings, the active tab. Lavender on dark, a deeper lavender on cream so white text passes.
    static let accent = Color(light: 0x6F59C9, dark: 0xB9A6F5)
    static let onAccent = Color(light: 0xFFFFFF, dark: 0x16141D)
    static let onAccentSecondary = Color(light: 0xFFFFFF, dark: 0x16141D).opacity(0.78)
    static let accentText = Color(light: 0x5B45B5, dark: 0xCDBEF8)      // small accent text
    static let accentSoft = Color(light: 0xE9E2FB, dark: 0x2E2445)
    static let accentShade = Color(hex: 0x6F59C9)

    // Pastel companions, for data and medals. Text on them is always ink.
    static let butter = Color(hex: 0xF6D68B)
    static let peach = Color(hex: 0xF5B08B)
    static let sky = Color(hex: 0x9DB6FF)
    static let blossom = Color(hex: 0xF7A9D3)
    static let mint = Color(hex: 0x9ADBB6)
    static let peachSoft = Color(light: 0xFBE9DD, dark: 0x3A2D2B)
    static let peachText = Color(light: 0xA2491F, dark: 0xF5B08B)

    // Neutrals.
    static let bg = Color(light: 0xF6F0E6, dark: 0x16141D)
    static let surface = Color(light: 0xFFFFFF, dark: 0x201D2A)
    static let fill = Color(light: 0xEDE5D8, dark: 0x2B2837)
    static let fill2 = Color(light: 0xE3D9C8, dark: 0x393446)
    static let label = Color(light: 0x1E1B27, dark: 0xF4EFE8)
    static let label2 = Color(light: 0x6B6578, dark: 0xABA5B8)
    static let label3 = Color(light: 0x9A94A6, dark: 0x736E81)
    static let separator = Color(light: 0xE4DCCD, dark: 0x2F2B3A)
    static let sheet = bg
    static let sheetGroup = surface

    /// The focus flow (intervention, session, payoff) is always dark.
    static let focusBg = Color(hex: 0x16141D)
    static let ink = Color(hex: 0x16141D)
    static let paper = Color(hex: 0xF6F0E6)

    static let gutter: CGFloat = 20
    static let minTap: CGFloat = 44
    static let cardRadius: CGFloat = 20
    static let controlRadius: CGFloat = 12
}

// MARK: - Type

extension Font {
    /// SF Pro at a system text style, so everything follows Dynamic Type.
    static func text(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .default, weight: weight)
    }

    /// Numerals that count, time or total: SF Rounded, tabular, fixed size (always large already).
    static func numeral(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }

    /// Statements: New York, the system serif. Used for the big lines the coach says (hero, intervention, payoff, welcome).
    /// UI chrome, labels and numerals stay in SF.
    static func statement(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    /// Headlines. One display size per screen.
    static func display(_ size: CGFloat, relativeTo style: Font.TextStyle = .largeTitle) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }
}

// MARK: - Motion

/// One vocabulary: springs for anything a finger touched, strong ease-out under 300 ms for the rest.
enum Motion {
    static let spring = Animation.spring(response: 0.42, dampingFraction: 0.86)
    static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.84)
    static let easeOut = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.28)
    static let press = Animation.easeOut(duration: 0.12)
}

/// Haptics are punctuation: one per action, on the same frame as the visual.
enum Haptics {
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
}

/// Fades and lifts content in once when it first appears. Reduce Motion: a plain fade.
private struct Appear: ViewModifier {
    let delay: Double
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 14)
            .onAppear { withAnimation(Motion.easeOut.delay(delay)) { shown = true } }
    }
}

extension View {
    func appear(_ delay: Double = 0) -> some View { modifier(Appear(delay: delay)) }
}

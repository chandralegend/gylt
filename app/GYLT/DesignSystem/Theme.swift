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

/// Design tokens. Neutrals are the system's own semantic colours, so light, dark and increased contrast come for free.
/// One accent (coral). Shape rule: cards 20, controls and inputs 12, buttons and chips are capsules. All corners are continuous.
enum Theme {
    // Accent: spent only on the primary action, the active state and progress.
    static let accent = Color(hex: 0xEE4B2B)
    static let accentText = Color(light: 0xC63A1C, dark: 0xFF7A5C)       // for small accent text: passes contrast on both themes
    static let accentSoft = Color(light: 0xFDE7E1, dark: 0x3A1F18)
    static let onAccent = Color.white
    static let onAccentSecondary = Color.white.opacity(0.82)
    static let accentShade = Color(hex: 0xC63A1C)

    // Neutrals (system semantic).
    static let bg = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let fill = Color(uiColor: .tertiarySystemFill)
    static let fill2 = Color(uiColor: .secondarySystemFill)
    static let label = Color(uiColor: .label)
    static let label2 = Color(uiColor: .secondaryLabel)
    static let label3 = Color(uiColor: .tertiaryLabel)
    static let separator = Color(uiColor: .separator)
    static let sheet = Color(uiColor: .systemGroupedBackground)
    static let sheetGroup = Color(uiColor: .secondarySystemGroupedBackground)

    /// The focus flow (intervention, session, payoff) is always dark and a touch warmer than pure black.
    static let focusBg = Color(hex: 0x0E0E10)
    static let ink = Color(hex: 0x1C1C1E)
    static let paper = Color(hex: 0xF2F2F7)

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

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

/// Design tokens, mirrored from GYLT/03-Design/design-tokens.json.
/// One accent (coral). One warm grey family. Focus screens are forced dark by their container.
enum Theme {
    static let accent = Color(hex: 0xFF6548)
    static let accentShade = Color(hex: 0xC23F20)
    static let onAccent = Color(hex: 0x1C1B18)
    static let onAccentSecondary = Color(hex: 0x4A2117)

    static let bg = Color(light: 0xF5F4F0, dark: 0x141412)
    static let surface = Color(light: 0xFFFFFF, dark: 0x1F1E1B)
    static let fill = Color(light: 0xECEBE6, dark: 0x2A2925)
    static let fill2 = Color(light: 0xE2E1DB, dark: 0x34332E)
    static let label = Color(light: 0x1C1B18, dark: 0xF4F3EF)
    static let label2 = Color(light: 0x64635C, dark: 0xA6A59D)
    static let label3 = Color(light: 0x8F8E86, dark: 0x6F6E67)
    static let separator = Color(light: 0xE4E3DD, dark: 0x2F2E2A)
    static let accentText = Color(light: 0xC23F20, dark: 0xFF8A70)
    static let accentSoft = Color(light: 0xFFE6DE, dark: 0x3A2520)
    static let sheet = Color(light: 0xF5F4F0, dark: 0x1E1D1A)
    static let sheetGroup = Color(light: 0xFFFFFF, dark: 0x2A2925)
    static let ink = Color(hex: 0x1C1B18)
    static let paper = Color(hex: 0xF5F4F0)

    static let gutter: CGFloat = 20
    static let minTap: CGFloat = 44
}

// MARK: - Type

extension Font {
    /// Jersey 25 — pixel display type. Scales with Dynamic Type relative to a text style.
    static func display(_ size: CGFloat, relativeTo style: Font.TextStyle = .largeTitle) -> Font {
        // Decorative display type is already large; it stays fixed so headlines never explode at accessibility sizes.
        // Body text around it still follows Dynamic Type.
        .custom("Jersey25-Regular", fixedSize: size)
    }

    /// System monospaced for everything that must stay easy to read.
    static func mono(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .monospaced, weight: weight)
    }
}

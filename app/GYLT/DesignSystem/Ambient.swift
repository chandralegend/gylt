import SwiftUI

/// A calm, blurred field of colour behind a page. Each page has its own mood, taken from the palette.
/// Content sits on glass-like cards (see `panel(glass:)`), so the colour shows through softly.
struct AmbientBackground: View {
    enum Mood {
        case today, promises, coach, progress

        /// Three soft blobs: colour, centre (fractions of the page) and size (fraction of the page width).
        fileprivate var blobs: [(Color, CGPoint, CGFloat)] {
            let lavender = Color(hex: 0xB9A6F5)
            switch self {
            case .today:    return [(Theme.butter, CGPoint(x: 0.9, y: 0.06), 1.0), (Theme.peach, CGPoint(x: 0.02, y: 0.5), 0.85), (Theme.butter, CGPoint(x: 0.95, y: 0.9), 0.7)]
            case .promises: return [(Theme.sky, CGPoint(x: 0.08, y: 0.06), 1.0), (lavender, CGPoint(x: 0.98, y: 0.5), 0.9), (Theme.blossom, CGPoint(x: 0.04, y: 0.92), 0.65)]
            case .coach:    return [(Theme.blossom, CGPoint(x: 0.9, y: 0.06), 1.0), (lavender, CGPoint(x: 0.02, y: 0.5), 0.9), (Theme.sky, CGPoint(x: 0.85, y: 0.95), 0.7)]
            case .progress: return [(Theme.mint, CGPoint(x: 0.1, y: 0.05), 1.0), (Theme.butter, CGPoint(x: 0.98, y: 0.48), 0.85), (Theme.sky, CGPoint(x: 0.05, y: 0.92), 0.7)]
            }
        }
    }

    let mood: Mood
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drift = false

    var body: some View {
        GeometryReader { g in
            ZStack {
                Theme.bg
                ForEach(Array(mood.blobs.enumerated()), id: \.offset) { i, blob in
                    let size = g.size.width * blob.2
                    Circle()
                        .fill(blob.0.opacity(scheme == .dark ? 0.42 : 0.55))
                        .frame(width: size, height: size)
                        .blur(radius: 64)
                        .position(x: g.size.width * blob.1.x, y: g.size.height * blob.1.y)
                        .offset(x: drift ? (i.isMultiple(of: 2) ? 16 : -16) : 0, y: drift ? (i == 1 ? -14 : 14) : 0)
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 14).repeatForever(autoreverses: true)) { drift = true }
        }
    }
}

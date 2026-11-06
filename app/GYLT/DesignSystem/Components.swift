import SwiftUI

// MARK: - Shapes and surfaces

struct Squircle: Shape {
    var corner: CGFloat = Theme.controlRadius
    func path(in rect: CGRect) -> Path { RoundedRectangle(cornerRadius: corner, style: .continuous).path(in: rect) }
}

extension View {
    /// A filled, clipped surface with continuous corners and an optional hairline border.
    func panel(_ fill: Color = Theme.surface, corner: CGFloat = Theme.cardRadius, border: Color? = nil) -> some View {
        background(Squircle(corner: corner).fill(fill))
            .overlay { if let border { Squircle(corner: corner).stroke(border, lineWidth: 1) } }
            .clipShape(Squircle(corner: corner))
    }
}

struct Card<Content: View>: View {
    var fill: Color = Theme.surface
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(16).frame(maxWidth: .infinity, alignment: .leading).panel(fill)
    }
}

struct CardGroup<Content: View>: View {
    var fill: Color = Theme.surface
    @ViewBuilder var content: Content
    var body: some View { VStack(spacing: 0) { content }.panel(fill) }
}

// MARK: - Buttons

enum ButtonKind { case primary, secondary, tertiary, light }

struct AppButtonStyle: ButtonStyle {
    var kind: ButtonKind = .primary
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let (bg, fg): (Color, Color) = {
            switch kind {
            case .primary: (Theme.accent, Theme.onAccent)
            case .secondary: (Theme.fill2, Theme.label)
            case .light: (.white, Theme.ink)
            case .tertiary: (.clear, Theme.label2)
            }
        }()
        configuration.label
            .font(.text(.body, weight: kind == .tertiary ? .medium : .semibold))
            .foregroundStyle(fg)
            .frame(maxWidth: .infinity, minHeight: kind == .tertiary ? Theme.minTap : 54)
            .background { if kind != .tertiary { Capsule().fill(bg) } }
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .opacity(isEnabled ? (configuration.isPressed && kind == .tertiary ? 0.6 : 1) : 0.4)
            .animation(Motion.press, value: configuration.isPressed)
            .contentShape(Capsule())
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed && (kind == .primary || kind == .light) { Haptics.tap() }
            }
    }
}

struct IconButton: View {
    let icon: Icon
    let label: String
    var size: CGFloat = 40
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Symbol(icon: icon, size: 20).foregroundStyle(Theme.label)
                .frame(width: size, height: size).background(Circle().fill(Theme.fill2))
        }
        .buttonStyle(PressScale())
        .frame(minWidth: Theme.minTap, minHeight: Theme.minTap)
        .contentShape(Rectangle())
        .accessibilityLabel(label)
    }
}

/// Press feedback for icon-only controls and cards: a quick scale, nothing else.
struct PressScale: ButtonStyle {
    var scale: CGFloat = 0.94
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? scale : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

/// List-row press: a background highlight, never a scale.
struct RowPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.background(configuration.isPressed ? Theme.fill : .clear).animation(Motion.press, value: configuration.isPressed)
    }
}

// MARK: - Rows, chips, controls

struct ListRow: View {
    let icon: Icon?
    let title: String
    var subtitle: String?
    var trailing: String?
    var chevron = false
    var done = false
    var showsSeparator = true
    var accessory: AnyView?
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Group { typeSize.isAccessibilitySize ? AnyView(stacked) : AnyView(inline) }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .frame(minHeight: 60)
            .overlay(alignment: .top) {
                if showsSeparator {
                    Rectangle().fill(Theme.separator).frame(height: 0.5).padding(.leading, typeSize.isAccessibilitySize ? 16 : 64)
                }
            }
            .contentShape(Rectangle())
    }

    private var tile: some View {
        Group {
            if let icon {
                Symbol(icon: icon, size: 20).foregroundStyle(Theme.label)
                    .frame(width: 36, height: 36).background(Squircle(corner: 10).fill(Theme.fill))
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.text(.body, weight: .medium)).foregroundStyle(done ? Theme.label2 : Theme.label)
            if let subtitle { Text(subtitle).font(.text(.footnote)).foregroundStyle(Theme.label2).lineLimit(2) }
        }
    }

    private var stacked: some View {
        VStack(alignment: .leading, spacing: 6) {
            tile
            titleBlock
            HStack(spacing: 8) {
                if let accessory { accessory }
                if let trailing { Text(trailing).font(.text(.subheadline)).foregroundStyle(Theme.label2) }
                if chevron { Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Theme.label3) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inline: some View {
        HStack(spacing: 12) {
            tile
            titleBlock
            Spacer(minLength: 8)
            if let accessory { accessory }
            if let trailing { Text(trailing).font(.text(.subheadline)).foregroundStyle(Theme.label2).monospacedDigit() }
            if chevron { Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Theme.label3) }
        }
    }
}

struct Chip: View {
    let text: String
    var body: some View {
        Text(text).font(.text(.footnote, weight: .medium)).foregroundStyle(Theme.label)
            .padding(.horizontal, 10).frame(minHeight: 28)
            .background(Capsule().fill(Theme.fill))
    }
}

/// The native switch, tinted with the accent.
struct ToggleSwitch: View {
    @Binding var isOn: Bool
    let label: String
    var body: some View {
        Toggle(label, isOn: $isOn)
            .labelsHidden().tint(Theme.accent)
            .sensoryFeedback(.selection, trigger: isOn)
            .frame(minWidth: Theme.minTap, minHeight: Theme.minTap)
            .accessibilityLabel(label)
    }
}

/// The native segmented control.
struct SegmentedPicker<T: Hashable & CaseIterable & RawRepresentable>: View where T.RawValue == String, T.AllCases: RandomAccessCollection {
    @Binding var selection: T
    var body: some View {
        Picker("", selection: $selection) {
            ForEach(Array(T.allCases), id: \.self) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
        .sensoryFeedback(.selection, trigger: selection)
    }
}

struct SectionHeader: View {
    let title: String
    var trailing: AnyView?
    var body: some View {
        HStack {
            Text(title).font(.text(.title3, weight: .bold)).foregroundStyle(Theme.label).accessibilityAddTraits(.isHeader)
            Spacer()
            if let trailing { trailing }
        }
        .padding(.top, 28).padding(.bottom, 8)
    }
}

struct SmallLabel: View {
    let text: String
    var body: some View {
        Text(text).font(.text(.footnote, weight: .semibold)).foregroundStyle(Theme.label2).padding(.leading, 4).padding(.top, 28).padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct Footnote: View {
    let text: String
    var body: some View {
        Text(text).font(.text(.footnote)).foregroundStyle(Theme.label2).padding(.horizontal, 4).padding(.top, 8)
            .frame(maxWidth: .infinity, alignment: .leading).fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Progress

struct ProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat = 12
    var track: Color = Theme.fill
    var tint: Color = Theme.accent
    var body: some View {
        ZStack {
            Circle().stroke(track, lineWidth: lineWidth)
            if progress > 0.001 {
                Circle().trim(from: 0, to: min(1, progress))
                    .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Brand

struct Wordmark: View {
    var size: CGFloat = 22
    var color: Color = Theme.label
    var body: some View {
        Text("GYLT").font(.system(size: size, weight: .heavy, design: .rounded)).tracking(size * 0.09).foregroundStyle(color)
            .accessibilityLabel("GYLT")
    }
}

/// A row of bars for the coach's speaking state.
struct VoiceWave: View {
    var playing = false
    private let heights: [CGFloat] = [8, 14, 22, 14, 22, 16, 8, 22, 14, 22, 8, 16, 8, 14, 22, 8]
    @State private var phase = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        HStack(spacing: 3) {
            ForEach(heights.indices, id: \.self) { i in
                Capsule().fill(playing ? Theme.accent : Theme.label3)
                    .frame(width: 3, height: heights[i] * (playing && phase != (i % 2 == 0) ? 0.5 : 1))
            }
        }
        .frame(height: 22)
        .onAppear { if playing && !reduceMotion { withAnimation(.easeInOut(duration: 0.4).repeatForever()) { phase.toggle() } } }
        .accessibilityHidden(true)
    }
}

// MARK: - Third-party app icons (always normal rounded icons)

enum BrandApp { case instagram, tiktok, youtube }

struct BrandBadge: View {
    let app: BrandApp
    var size: CGFloat = 32

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous).fill(background)
            glyph.frame(width: size * 0.56, height: size * 0.56)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var background: AnyShapeStyle {
        switch app {
        case .instagram:
            AnyShapeStyle(LinearGradient(colors: [Color(hex: 0xFCA95C), Color(hex: 0xE0647E), Color(hex: 0x9D69C3)],
                                         startPoint: .bottomLeading, endPoint: .topTrailing))
        case .tiktok: AnyShapeStyle(Color(hex: 0x111111))
        case .youtube: AnyShapeStyle(Color(hex: 0xE8453C))
        }
    }

    @ViewBuilder private var glyph: some View {
        switch app {
        case .instagram:
            ZStack {
                RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(.white, lineWidth: 1.6)
                Circle().stroke(.white, lineWidth: 1.6).padding(4)
                Circle().fill(.white).frame(width: 2.4, height: 2.4).offset(x: 5, y: -5)
            }
        case .tiktok:
            GeometryReader { g in
                let w = g.size.width, h = g.size.height
                Path { p in
                    p.move(to: CGPoint(x: w * 0.62, y: h * 0.08))
                    p.addLine(to: CGPoint(x: w * 0.62, y: h * 0.62))
                    p.addArc(center: CGPoint(x: w * 0.42, y: h * 0.66), radius: w * 0.2, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
                    p.move(to: CGPoint(x: w * 0.62, y: h * 0.08))
                    p.addQuadCurve(to: CGPoint(x: w * 0.95, y: h * 0.3), control: CGPoint(x: w * 0.66, y: h * 0.3))
                }
                .stroke(.white, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
            }
        case .youtube:
            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous).stroke(.white, lineWidth: 1.6)
                Image(systemName: "play.fill").font(.system(size: size * 0.2)).foregroundStyle(.white)
            }
            .frame(height: size * 0.4)
        }
    }
}


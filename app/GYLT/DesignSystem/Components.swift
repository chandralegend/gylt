import SwiftUI
import GYLTCore

// MARK: - Shapes and surfaces

struct Squircle: Shape {
    var corner: CGFloat = Theme.controlRadius
    func path(in rect: CGRect) -> Path { RoundedRectangle(cornerRadius: corner, style: .continuous).path(in: rect) }
}

extension View {
    /// A filled, clipped surface with continuous corners and an optional hairline border.
    /// `glass`: a translucent card. A thin material blurs whatever sits behind it (the page's ambient colour), tinted by `fill`.
    func panel(_ fill: Color = Theme.surface, corner: CGFloat = Theme.cardRadius, border: Color? = nil, glass: Bool = false) -> some View {
        background {
            if glass {
                ZStack { Rectangle().fill(.ultraThinMaterial); Rectangle().fill(fill.opacity(0.58)) }.clipShape(Squircle(corner: corner))
            } else {
                Squircle(corner: corner).fill(fill)
            }
        }
        .overlay { if let border { Squircle(corner: corner).stroke(border, lineWidth: 1) } else if glass { Squircle(corner: corner).stroke(Theme.separator.opacity(0.7), lineWidth: 0.75) } }
        .clipShape(Squircle(corner: corner))
    }
}

struct Card<Content: View>: View {
    var fill: Color = Theme.surface
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(16).frame(maxWidth: .infinity, alignment: .leading).panel(fill, glass: true)
    }
}

struct CardGroup<Content: View>: View {
    var fill: Color = Theme.surface
    @ViewBuilder var content: Content
    var body: some View { VStack(spacing: 0) { content }.panel(fill, glass: true) }
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
    var art: Art? = nil
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
            if let art {
                ArtView(art: art).frame(width: 48, height: 48).clipShape(Squircle(corner: 14))
            } else if let icon {
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

/// Content that scrolls up under the status bar is blurred away, as it was under the system bar, and the blur fades in only once you have scrolled.
private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat? = nil
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) { value = value ?? nextValue() }
}

private struct TopEdgeBlur: ViewModifier {
    @State private var rest: CGFloat?
    @State private var minY: CGFloat = 0
    private static let space = "topEdgeBlurScroll"

    private var scrolled: CGFloat { max(0, (rest ?? minY) - minY) }

    func body(content: Content) -> some View {
        content
            .coordinateSpace(name: Self.space)
            .onPreferenceChange(ScrollOffsetKey.self) { y in
                guard let y else { return }
                if rest == nil { rest = y }
                minY = y
            }
            .overlay(alignment: .top) {
                GeometryReader { g in
                    let h = g.safeAreaInsets.top
                    Rectangle().fill(.ultraThinMaterial)
                        .mask(LinearGradient(stops: [.init(color: .black, location: 0), .init(color: .black, location: h / (h + 14)), .init(color: .clear, location: 1)], startPoint: .top, endPoint: .bottom))
                        .frame(height: h + 14)
                        .offset(y: -h)
                        .opacity(min(1, scrolled / 24))
                        .animation(.easeOut(duration: 0.15), value: scrolled > 1)
                        .allowsHitTesting(false)
                }
            }
    }
}

/// Put this at the top of a scroll view's content; it reports where the content sits.
struct ScrollAnchor: View {
    var body: some View {
        GeometryReader { g in Color.clear.preference(key: ScrollOffsetKey.self, value: g.frame(in: .named("topEdgeBlurScroll")).minY) }
            .frame(height: 0)
    }
}

extension View {
    func topEdgeBlur() -> some View { modifier(TopEdgeBlur()) }
}

/// The title of a top-level screen, drawn in the content instead of in a navigation bar, so nothing sits empty above it.
/// An optional round button lives on the same row.
struct ScreenTitle: View {
    let title: String
    var symbol: String?
    var label: String = ""
    var action: () -> Void = {}

    var body: some View {
        HStack(alignment: .center) {
            Text(title).font(.text(.largeTitle, weight: .bold)).foregroundStyle(Theme.label).accessibilityAddTraits(.isHeader)
            Spacer()
            if let symbol {
                Button(action: action) {
                    Image(systemName: symbol).font(.system(size: 17, weight: .semibold)).foregroundStyle(Theme.label)
                        .frame(width: 40, height: 40).background(Circle().fill(.ultraThinMaterial)).overlay(Circle().strokeBorder(Theme.separator.opacity(0.6), lineWidth: 0.5))
                }
                .buttonStyle(.plain).accessibilityLabel(label)
            }
        }
        .padding(.top, 6).padding(.bottom, 6)
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

// MARK: - Consistency

struct StreakChip: View {
    let days: Int
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "flame.fill").font(.system(size: 12, weight: .bold))
            Text("\(days) days in a row").font(.text(.footnote, weight: .semibold))
        }
        .foregroundStyle(Theme.peachText).padding(.horizontal, 10).frame(minHeight: 28)
        .background(Capsule().fill(Theme.peachSoft))
        .accessibilityElement(children: .combine)
    }
}

/// Twelve weeks at a glance, one square a day: coral for a day with every promise kept, lighter for some, grey for none.
struct ConsistencyGrid: View {
    let history: GYLTCore.Progress.History
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            ForEach(0..<history.weeks, id: \.self) { week in
                VStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { day in
                        let i = week * 7 + day
                        cell(i)
                            .scaleEffect(shown || reduceMotion ? 1 : 0.5).opacity(shown || reduceMotion ? 1 : 0)
                            .animation(reduceMotion ? nil : Motion.spring.delay(Double(week) * 0.03 + Double(day) * 0.008), value: shown)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear { shown = true }
        .onDisappear { shown = false }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Consistency over \(history.weeks) weeks")
        .accessibilityValue("\(history.daysShowedUp) days with at least one promise kept")
    }

    private func cell(_ i: Int) -> some View {
        let d = history.days[i]
        let future = i > history.todayIndex
        let fill: Color = future ? Theme.fill.opacity(0.5)
            : d.kept > 0 ? (d.fraction >= 1 ? Theme.accent : Theme.accent.opacity(0.5))
            : d.possible > 0 ? Theme.fill2 : Theme.fill.opacity(0.7)
        return RoundedRectangle(cornerRadius: 5, style: .continuous).fill(fill)
            .aspectRatio(1, contentMode: .fit)
            .overlay { if i == history.todayIndex { RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(Theme.label, lineWidth: 1.5) } }
    }
}

/// The last two weeks of one promise as dots: kept, missed, or nothing scheduled.
struct DotStrip: View {
    let history: GYLTCore.Progress.History
    var body: some View {
        let upto = history.todayIndex
        let slice = Array(history.days[max(0, upto - 13)...upto])
        HStack(spacing: 5) {
            ForEach(Array(slice.enumerated()), id: \.offset) { _, d in
                Circle().fill(d.kept > 0 ? Theme.accent : d.possible > 0 ? Theme.fill2 : Theme.fill.opacity(0.7)).frame(width: 9, height: 9)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Last two weeks")
        .accessibilityValue("\(slice.filter { $0.kept > 0 }.count) days kept")
    }
}

// MARK: - Brand

/// The GYLT wordmark: four round-stroked letters, drawn as a vector so it stays crisp and takes any colour.
/// `size` is the letter height.
struct Wordmark: View {
    var size: CGFloat = 22
    var color: Color = Theme.label
    var body: some View {
        Image("logo-wordmark").renderingMode(.template).resizable().scaledToFit()
            .frame(height: size * 1.55).foregroundStyle(color)
            .frame(height: size)
            .accessibilityLabel("GYLT")
    }
}

/// The doorway mark, in full colour.
struct LogoMark: View {
    var height: CGFloat = 44
    var body: some View {
        Image("logo-mark").resizable().scaledToFit().frame(width: height * 1.48, height: height * 1.48).frame(width: height * 0.82, height: height).clipped()
            .accessibilityHidden(true)
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

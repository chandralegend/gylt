import SwiftUI

// MARK: - Stepped corners

/// A rectangle whose corners step in 4 pt blocks instead of curving. `corner` is 4, 8 or 12.
struct PixelRect: Shape {
    var corner: CGFloat = 8

    func path(in rect: CGRect) -> Path {
        let c = min(corner, min(rect.width, rect.height) / 2)
        let s: CGFloat = 4
        var p = Path()
        // top-left staircase, then mirrored clockwise
        let tl: [CGPoint] = c <= s ? [CGPoint(x: 0, y: c), CGPoint(x: s, y: c), CGPoint(x: s, y: 0)]
                                   : [CGPoint(x: 0, y: c), CGPoint(x: s, y: c), CGPoint(x: s, y: s), CGPoint(x: c, y: s), CGPoint(x: c, y: 0)]
        var pts: [CGPoint] = tl.map { CGPoint(x: rect.minX + $0.x, y: rect.minY + $0.y) }
        pts += tl.reversed().map { CGPoint(x: rect.maxX - $0.x, y: rect.minY + $0.y) }
        pts += tl.map { CGPoint(x: rect.maxX - $0.x, y: rect.maxY - $0.y) }
        pts += tl.reversed().map { CGPoint(x: rect.minX + $0.x, y: rect.maxY - $0.y) }
        p.addLines(pts)
        p.closeSubpath()
        return p
    }
}

/// A pixel octagon-ish "circle" used for round controls.
struct PixelRound: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let a = 0.3, b = 0.1
        let pts: [CGPoint] = [
            (0, a), (b, a), (b, b), (a, b), (a, 0), (1 - a, 0), (1 - a, b), (1 - b, b), (1 - b, a), (1, a),
            (1, 1 - a), (1 - b, 1 - a), (1 - b, 1 - b), (1 - a, 1 - b), (1 - a, 1), (a, 1), (a, 1 - b), (b, 1 - b), (b, 1 - a), (0, 1 - a),
        ].map { CGPoint(x: rect.minX + $0.0 * w, y: rect.minY + $0.1 * h) }
        var p = Path()
        p.addLines(pts)
        p.closeSubpath()
        return p
    }
}

extension View {
    /// Fill plus a 2 pt inner border, both on a stepped-corner shape.
    func pixelPanel(_ fill: Color, corner: CGFloat = 12, border: Color? = nil) -> some View {
        background(PixelRect(corner: corner).fill(fill))
            .overlay {
                if let border {
                    PixelRect(corner: corner).stroke(border, lineWidth: 4).clipShape(PixelRect(corner: corner))
                }
            }
            .clipShape(PixelRect(corner: corner))
    }
}

// MARK: - Sprites and icons

/// Draws a grid of coloured cells with no smoothing. Scale only by whole numbers.
struct PixelSprite: View {
    let data: PixelSpriteData
    var scale: CGFloat = 4
    var tint: Color?

    var body: some View {
        Canvas(opaque: false, rendersAsynchronously: false) { ctx, _ in
            for (y, row) in data.rows.enumerated() {
                let chars = Array(row)
                var x = 0
                while x < chars.count {
                    let ch = chars[x]
                    var end = x
                    while end < chars.count, chars[end] == ch { end += 1 }
                    if let hex = data.palette[ch] {
                        let color = tint ?? Color(hex: hex)
                        let rect = CGRect(x: CGFloat(x) * scale, y: CGFloat(y) * scale, width: CGFloat(end - x) * scale, height: scale)
                        ctx.fill(Path(rect), with: .color(color), style: FillStyle(antialiased: false))
                    }
                    x = end
                }
            }
        }
        .frame(width: CGFloat(data.width) * scale, height: CGFloat(data.height) * scale)
        .accessibilityHidden(true)
    }
}

struct PxIconView: View {
    let icon: PxIcon
    var size: CGFloat = 24
    var body: some View {
        let k = size / 24
        Canvas { ctx, _ in
            var path = Path()
            for poly in icon.polygons {
                guard poly.count >= 4 else { continue }
                path.move(to: CGPoint(x: poly[0] * k, y: poly[1] * k))
                var i = 2
                while i + 1 < poly.count { path.addLine(to: CGPoint(x: poly[i] * k, y: poly[i + 1] * k)); i += 2 }
                path.closeSubpath()
            }
            ctx.fill(path, with: .foreground, style: FillStyle(eoFill: true, antialiased: false))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct GYLTWordmark: View {
    var scale: CGFloat = 3
    var body: some View {
        PixelSprite(data: PixelData.wordmark, scale: scale, tint: Theme.label)
            .accessibilityElement()
            .accessibilityLabel("GYLT")
    }
}

// MARK: - Third-party app icons (normal rounded icons, never pixelated)

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

// MARK: - Timer ring (pixel cells)

struct PixelRing: View {
    var progress: Double              // 0…1 of the target already elapsed
    var size: CGFloat = 272
    private static let cells: [(x: Int, y: Int, f: Double)] = {
        let n = 34, c = 17.0
        var out: [(Int, Int, Double)] = []
        for y in 0..<n {
            for x in 0..<n {
                let dx = Double(x) + 0.5 - c, dy = Double(y) + 0.5 - c
                let d = (dx * dx + dy * dy).squareRoot()
                if d >= 14.6 && d <= 16.6 {
                    var a = atan2(dx, -dy)
                    if a < 0 { a += 2 * .pi }
                    out.append((x, y, a / (2 * .pi)))
                }
            }
        }
        return out
    }()

    var body: some View {
        let cell = size / 34
        Canvas { ctx, _ in
            for k in Self.cells {
                let rect = CGRect(x: CGFloat(k.x) * cell, y: CGFloat(k.y) * cell, width: cell, height: cell)
                ctx.fill(Path(rect), with: .color(k.f < progress ? Theme.accent : Theme.fill), style: FillStyle(antialiased: false))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - Buttons

enum PxButtonKind { case accent, ink, secondary, plain }

struct PxButtonStyle: ButtonStyle {
    var kind: PxButtonKind = .accent
    var showsArrow = false

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let (bg, fg, shade): (Color, Color, Color) = {
            switch kind {
            case .accent: (Theme.accent, Theme.onAccent, Theme.accentShade)
            case .ink: (Theme.label, Theme.bg, Color.black.opacity(0.45))
            case .secondary: (Theme.fill, Theme.label, Theme.fill2)
            case .plain: (.clear, Theme.label2, .clear)
            }
        }()
        HStack(spacing: 8) {
            configuration.label.font(.mono(kind == .plain ? .subheadline : .body, weight: kind == .plain ? .medium : .semibold))
            if showsArrow { Spacer(minLength: 0); PxIconView(icon: .arrowRight, size: 24) }
        }
        .foregroundStyle(fg)
        .frame(maxWidth: .infinity, minHeight: kind == .plain ? Theme.minTap : 52)
        .padding(.horizontal, kind == .plain ? 0 : 24)
        .background {
            if kind != .plain {
                PixelRect(corner: 8).fill(bg)
                    .overlay(alignment: .bottom) { Rectangle().fill(shade).frame(height: pressed ? 2 : 4) }
                    .clipShape(PixelRect(corner: 8))
            }
        }
        .offset(y: pressed && kind != .plain ? 2 : 0)
        .opacity(pressed && kind == .plain ? 0.6 : 1)
        .contentShape(Rectangle())
    }
}

struct PxIconButton: View {
    let icon: PxIcon
    let label: String
    var size: CGFloat = 44
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            PxIconView(icon: icon, size: 24)
                .foregroundStyle(Theme.label)
                .frame(width: size, height: size)
                .background(PixelRound().fill(Theme.fill))
        }
        .buttonStyle(.plain)
        .frame(minWidth: Theme.minTap, minHeight: Theme.minTap)
        .contentShape(Rectangle())
        .accessibilityLabel(label)
    }
}

// MARK: - Lists, cards, chips

struct PxGroup<Content: View>: View {
    var fill: Color = Theme.surface
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 0) { content }
            .pixelPanel(fill, corner: 12, border: Theme.separator)
    }
}

struct PxRow: View {
    let icon: PxIcon?
    let title: String
    var subtitle: String?
    var trailing: String?
    var chevron = false
    var done = false
    var showsSeparator = true
    var tileFill: Color = Theme.fill
    var accessory: AnyView?
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Group { typeSize.isAccessibilitySize ? AnyView(stacked) : AnyView(inline) }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .frame(minHeight: 60)
            .overlay(alignment: .top) {
                if showsSeparator {
                    Rectangle().fill(Theme.separator).frame(height: 2).padding(.leading, typeSize.isAccessibilitySize ? 16 : 64)
                        .mask(Rectangle().stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 4])))
                }
            }
            .contentShape(Rectangle())
    }

    /// Large text: title and details get the full width; extras move underneath instead of squeezing the words.
    private var stacked: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let icon {
                PxIconView(icon: icon, size: 24).foregroundStyle(Theme.label)
                    .frame(width: 36, height: 36).background(PixelRect(corner: 4).fill(tileFill))
            }
            Text(title).font(.mono(.body, weight: .medium)).strikethrough(done).foregroundStyle(done ? Theme.label2 : Theme.label)
            if let subtitle { Text(subtitle).font(.mono(.footnote)).foregroundStyle(Theme.label2) }
            HStack(spacing: 8) {
                if let accessory { accessory }
                if let trailing { Text(trailing).font(.mono(.subheadline)).foregroundStyle(Theme.label2) }
                if chevron { PxIconView(icon: .chevronRight, size: 12).foregroundStyle(Theme.label3) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inline: some View {
        HStack(spacing: 12) {
            if let icon {
                PxIconView(icon: icon, size: 24).foregroundStyle(Theme.label)
                    .frame(width: 36, height: 36)
                    .background(PixelRect(corner: 4).fill(tileFill))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.mono(.body, weight: .medium)).strikethrough(done).foregroundStyle(done ? Theme.label2 : Theme.label)
                if let subtitle { Text(subtitle).font(.mono(.footnote)).foregroundStyle(Theme.label2) }
            }
            Spacer(minLength: 8)
            if let accessory { accessory }
            if let trailing { Text(trailing).font(.mono(.subheadline)).foregroundStyle(Theme.label2) }
            if chevron { PxIconView(icon: .chevronRight, size: 12).foregroundStyle(Theme.label3) }
        }
    }
}

struct PxChip: View {
    let text: String
    var body: some View {
        Text(text).font(.mono(.footnote, weight: .medium)).foregroundStyle(Theme.label)
            .padding(.horizontal, 10).frame(minHeight: 28)
            .background(PixelRect(corner: 8).fill(Theme.fill))
    }
}

struct PxCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .pixelPanel(Theme.surface, corner: 12, border: Theme.separator)
    }
}

struct PxSwitch: View {
    @Binding var isOn: Bool
    let label: String
    var body: some View {
        Button { isOn.toggle() } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                PixelRect(corner: 4).fill(isOn ? Theme.accent : Theme.fill2).frame(width: 52, height: 32)
                PixelRect(corner: 4).fill(.white).frame(width: 24, height: 24).padding(4)
            }
            .frame(width: 52, height: 32)
            .animation(.linear(duration: 0.12), value: isOn)
        }
        .buttonStyle(.plain)
        .frame(minWidth: Theme.minTap, minHeight: Theme.minTap)
        .accessibilityLabel(label)
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityAddTraits(.isButton)
    }
}

struct PxSegmented<T: Hashable & CaseIterable & RawRepresentable>: View where T.RawValue == String, T.AllCases: RandomAccessCollection {
    @Binding var selection: T
    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(T.allCases), id: \.self) { item in
                let on = item == selection
                Button { selection = item } label: {
                    Text(item.rawValue).font(.mono(.subheadline, weight: on ? .semibold : .medium))
                        .foregroundStyle(on ? Theme.label : Theme.label2)
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .background(PixelRect(corner: 8).fill(on ? Theme.surface : .clear))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(3)
        .background(PixelRect(corner: 8).fill(Theme.fill))
    }
}

struct LargeTitle: View {
    let title: String
    var actionIcon: PxIcon?
    var actionLabel = ""
    var action: () -> Void = {}
    var body: some View {
        HStack {
            Text(title).font(.display(48)).foregroundStyle(Theme.label).accessibilityAddTraits(.isHeader)
            Spacer()
            if let actionIcon { PxIconButton(icon: actionIcon, label: actionLabel, action: action) }
        }
    }
}

struct SectionHeader: View {
    let title: String
    var trailing: AnyView?
    var body: some View {
        HStack {
            Text(title).font(.display(30, relativeTo: .title2)).foregroundStyle(Theme.label).accessibilityAddTraits(.isHeader)
            Spacer()
            if let trailing { trailing }
        }
        .padding(.top, 28).padding(.bottom, 8)
    }
}

struct SmallLabel: View {
    let text: String
    var body: some View {
        Text(text).font(.mono(.footnote, weight: .medium)).foregroundStyle(Theme.label2).padding(.leading, 4).padding(.top, 28).padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct Footnote: View {
    let text: String
    var body: some View {
        Text(text).font(.mono(.footnote)).foregroundStyle(Theme.label2).padding(.horizontal, 16).padding(.top, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A row of bars for the coach's speaking state.
struct VoiceWave: View {
    var playing = false
    private let heights: [CGFloat] = [8, 12, 20, 12, 20, 16, 8, 20, 12, 20, 8, 16, 8, 12, 20, 8, 20, 12]
    @State private var phase = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        HStack(spacing: 3) {
            ForEach(heights.indices, id: \.self) { i in
                Rectangle().fill(playing ? Theme.accent : Theme.label2)
                    .frame(width: 4, height: heights[i] * (playing && phase != (i % 2 == 0) ? 0.5 : 1))
            }
        }
        .frame(height: 20)
        .onAppear { if playing && !reduceMotion { withAnimation(.linear(duration: 0.4).repeatForever()) { phase.toggle() } } }
        .accessibilityHidden(true)
    }
}

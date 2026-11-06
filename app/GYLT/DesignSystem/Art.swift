import SwiftUI

/// The illustrations. Eight from The Open Meadows Library (CC BY 4.0, credited in Settings) and three GYLT originals.
/// Two of them are softened a little so they sit with the pastel palette.
enum Art: String {
    case walk = "meadow-walk", bed = "meadow-bed", night = "meadow-night"
    case intervention = "meadow-intervention", session = "meadow-session", payoff = "meadow-payoff"
    case welcome = "meadow-welcome", coach = "meadow-coach"
    case custom = "gylt-custom", blocked = "gylt-blocked", milestone = "gylt-milestone"

    /// The art for a promise: the starters have their own; anything you add gets the generic meadow.
    static func forPromise(_ id: UUID) -> Art {
        switch id {
        case Commitment.walkID: .walk
        case Commitment.bedID: .bed
        case Commitment.nightID: .night
        default: .custom
        }
    }

    /// Where to look when the picture is cropped (0...1 from the top-left).
    var focus: UnitPoint {
        switch self {
        case .walk: UnitPoint(x: 0.42, y: 0.6)
        case .bed: UnitPoint(x: 0.5, y: 0.78)
        case .night: UnitPoint(x: 0.5, y: 0.35)
        case .intervention: UnitPoint(x: 0.78, y: 0.5)
        case .blocked: UnitPoint(x: 0.67, y: 0.4)
        case .session: UnitPoint(x: 0.5, y: 0.55)
        case .welcome: UnitPoint(x: 0.62, y: 0.5)
        case .milestone: UnitPoint(x: 0.5, y: 0.8)
        default: UnitPoint(x: 0.5, y: 0.5)
        }
    }
}

import GYLTCore

/// An illustration cropped to fill whatever room it is given, anchored on its subject.
struct ArtView: View {
    let art: Art
    var focus: UnitPoint?

    var body: some View {
        Color.clear
            .overlay {
                GeometryReader { g in
                    let img = UIImage(named: art.rawValue)
                    let ratio = (img?.size.width ?? 3) / max(1, img?.size.height ?? 2)
                    let scale = max(g.size.width / ratio, g.size.height)       // height needed to cover
                    let w = scale * ratio, h = scale
                    let f = focus ?? art.focus
                    Image(art.rawValue).resizable().frame(width: w, height: h)
                        .offset(x: -(w - g.size.width) * f.x, y: -(h - g.size.height) * f.y)
                        .modifier(Soften(art: art))
                }
            }
            .clipped()
            .accessibilityHidden(true)
    }
}

private struct Soften: ViewModifier {
    let art: Art
    func body(content: Content) -> some View {
        switch art {
        case .walk: content.saturation(0.8)
        case .intervention: content.hueRotation(.degrees(292)).saturation(0.5).brightness(0.04)
        default: content
        }
    }
}

/// A fade from the picture into the page, so text can sit on the join.
struct ArtFade: View {
    var color: Color = Theme.focusBg
    var body: some View {
        LinearGradient(stops: [.init(color: color.opacity(0), location: 0), .init(color: color, location: 0.88)], startPoint: .top, endPoint: .bottom)
            .allowsHitTesting(false)
    }
}

// MARK: - Medals

enum Milestone {
    static let days = [3, 7, 14, 30, 60, 100]

    static func tint(_ n: Int) -> Color {
        switch n { case 3: Theme.butter; case 7: Theme.peach; case 14: Theme.sky; case 30: Theme.blossom; case 60: Theme.mint; default: Color(hex: 0xB9A6F5) }
    }
    /// The medal just reached, if today's streak is exactly a milestone.
    static func reached(streak: Int) -> Int? { days.contains(streak) ? streak : nil }
    static func next(after streak: Int) -> Int? { days.first { $0 > streak } }
}

private struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY), r = min(rect.width, rect.height) / 2
        var p = Path()
        for k in 0..<6 {
            let a = Angle.degrees(-90 + 60 * Double(k)).radians
            let pt = CGPoint(x: c.x + r * cos(a), y: c.y + r * sin(a))
            k == 0 ? p.move(to: pt) : p.addLine(to: pt)
        }
        p.closeSubpath()
        return p
    }
}

/// A layered hexagon medal, one pastel per milestone. `dark` puts the numeral on an ink centre, for use over bright art.
struct MedalView: View {
    let days: Int
    var size: CGFloat = 96
    var locked = false
    var dark = false

    var body: some View {
        let tint = locked ? Theme.fill2 : Milestone.tint(days)
        ZStack {
            Hexagon().stroke(tint, style: StrokeStyle(lineWidth: size * 0.014, lineJoin: .round)).padding(size * 0.04)
            Hexagon().fill(locked ? Theme.fill : tint.opacity(0.16)).overlay(Hexagon().stroke(tint, lineWidth: size * 0.01))
                .padding(size * 0.12)
            Hexagon().fill(locked ? Theme.surface : (dark ? Theme.ink : tint)).padding(size * 0.24)
            if locked {
                Image(systemName: "lock.fill").font(.system(size: size * 0.2, weight: .semibold)).foregroundStyle(Theme.label3)
            } else {
                Text("\(days)").font(.system(size: size * (days >= 100 ? 0.26 : 0.34), weight: .bold, design: .serif))
                    .foregroundStyle(dark ? tint : Theme.ink)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(days) day medal")
        .accessibilityValue(locked ? "Locked" : "Earned")
    }
}

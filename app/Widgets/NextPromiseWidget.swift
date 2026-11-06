import WidgetKit
import SwiftUI
import GYLTCore

/// The next promise, as a picture: its art, one line, and when. Home Screen (small, medium) and Lock Screen (rectangular, inline).
struct NextPromiseWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NextPromise", provider: SnapshotProvider()) { entry in
            NextPromiseView(entry: entry)
        }
        .configurationDisplayName("Next promise")
        .description("What you said you would do, and when. Counts down while you do it.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}

private struct NextPromiseView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SnapshotEntry

    private var snap: TodaySnapshot { entry.snapshot }

    var body: some View {
        Group {
            switch family {
            case .accessoryRectangular: rectangular
            case .accessoryInline: inline
            case .systemMedium: medium
            default: small
            }
        }
        .widgetURL(entry.needsSetup ? URL(string: "gylt://today") : snap.url)
    }

    // MARK: pieces

    private var meta: String {
        if entry.needsSetup { return "WELCOME" }
        switch snap.phase {
        case .upcoming(let start): return Calendar.current.isDateInToday(start) ? "UP NEXT" : "TOMORROW"
        case .due: return "TIME TO START"
        case .active(let endsAt, _): return endsAt == nil ? "PAUSED" : "IN PROGRESS"
        case .kept: return "PROMISE KEPT"
        case .ended: return "TODAY"
        case .empty: return "PROMISES"
        }
    }

    private var headline: String {
        if entry.needsSetup { return "Open GYLT\nto begin" }
        switch snap.phase {
        case .kept: return "Look at you.\nShowing up."
        case .ended: return "A fresh start\nis still a start."
        case .empty: return "No promises\non"
        case .active: return snap.title
        default: return snap.headline
        }
    }

    /// Time, countdown or a short detail, as one view so it can stay live.
    @ViewBuilder private func detail(size: CGFloat) -> some View {
        if entry.needsSetup {
            Text("Set up your promises").font(.system(size: size, weight: .medium))
        } else {
            switch snap.phase {
            case .upcoming(let start): Text(start, style: .time).font(.system(size: size, weight: .semibold)).monospacedDigit()
            case .due: Text(snap.title).font(.system(size: size, weight: .medium))
            case .active(let endsAt, let remaining):
                if let endsAt { Text(timerInterval: entry.date...max(endsAt, entry.date.addingTimeInterval(1)), countsDown: true).font(.numeral(size + 14)).monospacedDigit() }
                else { Text(Self.clock(remaining)).font(.numeral(size + 14)) }
            case .kept(let minutes): Text(minutes < 1 ? "Under a minute" : "\(Int(minutes.rounded())) min").font(.system(size: size, weight: .medium))
            case .ended: Text("Recorded honestly").font(.system(size: size, weight: .medium))
            case .empty: Text("Switch one on in GYLT").font(.system(size: size, weight: .medium))
            }
        }
    }

    static func clock(_ seconds: TimeInterval) -> String {
        let n = max(0, Int(seconds.rounded(.up)))
        return String(format: "%02d:%02d", n / 60, n % 60)
    }

    private var background: some View {
        ZStack {
            ArtView(art: entry.needsSetup ? .custom : snap.art)
            LinearGradient(colors: [.black.opacity(0.55), .black.opacity(0.18), .black.opacity(0.0)], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.7))
            LinearGradient(colors: [.black.opacity(0.0), .black.opacity(0.42)], startPoint: UnitPoint(x: 0.5, y: 0.62), endPoint: .bottom)
        }
    }

    private var streakChip: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill").font(.system(size: 10, weight: .bold))
            Text("\(snap.streak)").font(.system(size: 12, weight: .bold)).monospacedDigit()
        }
        .foregroundStyle(Theme.peach).padding(.horizontal, 8).frame(height: 22)
        .background(Capsule().fill(.black.opacity(0.4)))
    }

    // MARK: families

    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(meta).font(.system(size: 10, weight: .bold)).tracking(0.6).foregroundStyle(.white.opacity(0.9))
            Text(headline).font(.statement(21)).foregroundStyle(.white).lineLimit(3).minimumScaleFactor(0.75).padding(.top, 4)
            Spacer(minLength: 4)
            HStack(alignment: .bottom) {
                detail(size: 14).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.7)
                Spacer(minLength: 4)
                if snap.streak >= 2 && !entry.needsSetup { streakChip }
            }
        }
        .shadow(color: .black.opacity(0.3), radius: 4, y: 1)
        .containerBackground(for: .widget) { background }
    }

    private var medium: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 0) {
                Text(meta).font(.system(size: 10, weight: .bold)).tracking(0.6).foregroundStyle(.white.opacity(0.9))
                Text(headline).font(.statement(26)).foregroundStyle(.white).lineLimit(3).minimumScaleFactor(0.75).padding(.top, 4)
                Spacer(minLength: 4)
                detail(size: 15).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.7)
            }
            .shadow(color: .black.opacity(0.3), radius: 4, y: 1)
            Spacer(minLength: 0)
            if !entry.needsSetup {
                VStack(alignment: .leading, spacing: 8) {
                    Text("THIS WEEK").font(.system(size: 9, weight: .bold)).tracking(0.6).foregroundStyle(.white.opacity(0.85))
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("\(snap.weekKept)").font(.numeral(26, weight: .bold)).foregroundStyle(.white)
                        Text("of \(snap.weekPossible)").font(.system(size: 12, weight: .medium)).foregroundStyle(.white.opacity(0.85))
                    }
                    WeekDots(days: snap.week, today: snap.todayIndex, size: 9, spacing: 4)
                    if snap.streak >= 2 { streakChip }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.black.opacity(0.32)))
            }
        }
        .containerBackground(for: .widget) { background }
    }

    private var rectangular: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(meta).font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary)
                Text(snap.phase == .empty || entry.needsSetup ? headline.replacingOccurrences(of: "\n", with: " ") : (snap.title)).font(.headline).lineLimit(1)
                detail(size: 13).lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .widgetAccentable()
        .containerBackground(for: .widget) { AccessoryWidgetBackground() }
    }

    private var inline: some View {
        switch snap.phase {
        case .upcoming(let start): Text("\(snap.title) · \(start.formatted(date: .omitted, time: .shortened))")
        case .active(let endsAt, let remaining):
            if let endsAt { Text("\(snap.title) · \(Text(timerInterval: entry.date...max(endsAt, entry.date.addingTimeInterval(1)), countsDown: true))") }
            else { Text("\(snap.title) · \(Self.clock(remaining)) left") }
        case .kept: Text("\(snap.title) · kept")
        case .due: Text("Time to start: \(snap.title)")
        default: Text(snap.title)
        }
    }
}

/// Seven small circles, Monday to Sunday: filled when something was kept, ringed for today.
struct WeekDots: View {
    let days: [DayStat]
    let today: Int
    var size: CGFloat = 10
    var spacing: CGFloat = 5
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<days.count, id: \.self) { i in
                let kept = days[i].kept > 0
                Circle().fill(kept ? Color(hex: 0xB9A6F5) : .white.opacity(0.22)).frame(width: size, height: size)
                    .overlay { if i == today { Circle().stroke(.white, lineWidth: 1.5).frame(width: size + 4, height: size + 4) } }
            }
        }
    }
}

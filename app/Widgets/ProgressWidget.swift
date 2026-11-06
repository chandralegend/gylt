import WidgetKit
import SwiftUI
import GYLTCore

/// The week and the streak, without opening the app. Dusk background with soft colour, never pretending: zeros stay zeros.
struct ProgressWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WeekProgress", provider: SnapshotProvider()) { entry in
            ProgressView(entry: entry)
        }
        .configurationDisplayName("This week")
        .description("Promises kept this week and your streak.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular])
    }
}

private struct ProgressView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SnapshotEntry
    private var snap: TodaySnapshot { entry.snapshot }
    private let lavender = Color(hex: 0xB9A6F5)

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular: circular
            case .systemMedium: medium
            default: small
            }
        }
        .widgetURL(URL(string: "gylt://progress"))
    }

    private var fraction: Double { snap.weekPossible == 0 ? 0 : Double(snap.weekKept) / Double(snap.weekPossible) }

    private var backdrop: some View {
        ZStack {
            Theme.focusBg
            Circle().fill(lavender.opacity(0.35)).frame(width: 220, height: 220).blur(radius: 50).offset(x: -70, y: -70)
            Circle().fill(Theme.peach.opacity(0.22)).frame(width: 200, height: 200).blur(radius: 50).offset(x: 90, y: 80)
        }
    }

    private func ring(size: CGFloat, line: CGFloat) -> some View {
        ZStack {
            Circle().stroke(.white.opacity(0.14), lineWidth: line)
            if fraction > 0 { Circle().trim(from: 0, to: min(1, fraction)).stroke(lavender, style: StrokeStyle(lineWidth: line, lineCap: .round)).rotationEffect(.degrees(-90)) }
            VStack(spacing: 0) {
                Text("\(snap.weekKept)").font(.numeral(size * 0.32, weight: .bold)).foregroundStyle(Theme.paper)
                Text("of \(snap.weekPossible)").font(.system(size: max(9, size * 0.11), weight: .medium)).foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(width: size, height: size)
    }

    private var streakLine: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill").font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.peach)
            Text(snap.streak >= 2 ? "\(snap.streak) days in a row" : (snap.streak == 1 ? "1 day" : "No streak yet"))
                .font(.system(size: 12, weight: .semibold)).foregroundStyle(snap.streak >= 2 ? Theme.peach : .white.opacity(0.7))
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("THIS WEEK").font(.system(size: 10, weight: .bold)).tracking(0.6).foregroundStyle(.white.opacity(0.75))
            HStack { Spacer(); ring(size: 82, line: 9); Spacer() }
            streakLine
        }
        .containerBackground(for: .widget) { backdrop }
    }

    private var medium: some View {
        HStack(spacing: 18) {
            ring(size: 100, line: 11)
            VStack(alignment: .leading, spacing: 10) {
                Text(entry.needsSetup ? "Open GYLT to begin" : (snap.weekKept == 0 ? "A starting line,\nnot a verdict." : "You showed up\n\(snap.weekKept) \(snap.weekKept == 1 ? "time" : "times").")).font(.statement(19)).foregroundStyle(Theme.paper).lineLimit(2).minimumScaleFactor(0.8)
                HStack(spacing: 5) {
                    ForEach(0..<snap.week.count, id: \.self) { i in
                        let d = snap.week[i]
                        VStack(spacing: 4) {
                            Capsule().fill(d.kept > 0 ? lavender : .white.opacity(0.16)).frame(width: 14, height: max(6, 30 * d.fraction))
                                .frame(height: 30, alignment: .bottom)
                            Text(["M", "T", "W", "T", "F", "S", "S"][i]).font(.system(size: 9, weight: i == snap.todayIndex ? .bold : .medium)).foregroundStyle(.white.opacity(i == snap.todayIndex ? 1 : 0.6))
                        }
                    }
                }
                streakLine
            }
            Spacer(minLength: 0)
        }
        .containerBackground(for: .widget) { backdrop }
    }

    private var circular: some View {
        Gauge(value: fraction) {
            Image(systemName: "flame.fill")
        } currentValueLabel: {
            Text("\(snap.streak)").font(.system(size: 17, weight: .bold, design: .rounded))
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .widgetAccentable()
        .containerBackground(for: .widget) { AccessoryWidgetBackground() }
    }
}

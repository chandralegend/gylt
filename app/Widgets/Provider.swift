import WidgetKit
import SwiftUI
import GYLTCore

struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: TodaySnapshot
    /// Onboarding has not been completed on this phone yet.
    var needsSetup = false
}

/// Reads the same saved state the app uses (through the App Group) and turns it into a few timeline entries.
/// Widgets cannot run the engine, so the picture is recomputed from saved state at the moments it changes (a start time, a timer's end, midnight);
/// the app also asks for a reload every time it saves.
struct SnapshotProvider: TimelineProvider {
    static func load() -> AppState {
        let store = FileStateStore(url: AppGroup.file("GYLT/state.json"))
        return (try? store.load()) ?? AppState()
    }

    static func entry(at date: Date, state: AppState) -> SnapshotEntry {
        SnapshotEntry(date: date, snapshot: TodaySnapshot.make(state: state, now: date), needsSetup: !state.settings.onboardingCompleted)
    }

    func placeholder(in context: Context) -> SnapshotEntry { Self.sample }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        completion(context.isPreview ? Self.sample : Self.entry(at: .now, state: Self.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let state = Self.load()
        var entries: [SnapshotEntry] = []
        var t = Date()
        for _ in 0..<4 {
            let e = Self.entry(at: t, state: state)
            entries.append(e)
            let next = max(e.snapshot.refreshAt, t.addingTimeInterval(60))
            if next.timeIntervalSince(t) > 26 * 3600 { break }
            t = next
        }
        completion(Timeline(entries: entries, policy: .after(max(t, Date().addingTimeInterval(900)))))
    }

    /// What the widget gallery shows. Clearly an example, with no claim about the person's data.
    static var sample: SnapshotEntry {
        let start = Calendar.current.date(bySettingHour: 18, minute: 30, second: 0, of: .now) ?? .now
        let days = (0..<7).map { DayStat(localDate: "2026-01-0\($0 + 1)", kept: $0 < 4 ? 1 : 0, possible: $0 <= 4 ? 1 : 0) }
        let snap = TodaySnapshot(commitmentId: Commitment.walkID, occurrenceId: nil, title: "Evening walk", headline: "Get off\nthe couch",
                                 phase: .upcoming(start: start), streak: 5, week: days, todayIndex: 4, weekKept: 4, weekPossible: 5, refreshAt: start)
        return SnapshotEntry(date: .now, snapshot: snap)
    }
}

extension TodaySnapshot {
    /// Where a tap should go.
    var url: URL {
        if let id = occurrenceId { return URL(string: "gylt://open/\(id.uuidString)")! }
        return URL(string: "gylt://today")!
    }
    /// The art for this promise.
    var art: Art {
        switch phase {
        case .kept: .payoff
        case .empty: .custom
        default: commitmentId.map(Art.forPromise) ?? .custom
        }
    }
}

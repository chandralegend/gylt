import Foundation

public extension Commitment {
    /// The line the coach opens with. The starter promises have their own; yours lead with their name.
    var headline: String {
        switch id {
        case Commitment.walkID: "Get off\nthe couch"
        case Commitment.bedID: "Make your\nbed"
        case Commitment.nightID: "Call it\na night"
        default: title
        }
    }
}

/// Everything a glanceable surface (a widget) needs, worked out from saved state alone. Nothing is invented:
/// numbers come from the same functions the app uses, and the picture is only as fresh as the last time the app saved.
public struct TodaySnapshot: Equatable, Sendable {
    public enum Phase: Equatable, Sendable {
        /// Coming up at `start`.
        case upcoming(start: Date)
        /// It is time; waiting for the person to start.
        case due
        /// A session is open. `endsAt` is set while the timer is running, nil while paused (then `remaining` is fixed).
        case active(endsAt: Date?, remaining: TimeInterval)
        /// Finished today, kept.
        case kept(minutes: Double)
        /// Finished today without keeping it (ended, rested or missed).
        case ended
        /// No promise is switched on.
        case empty
    }

    public var commitmentId: UUID?
    public var occurrenceId: UUID?
    public var title: String
    public var headline: String
    public var phase: Phase
    public var streak: Int
    /// Monday to Sunday.
    public var week: [DayStat]
    public var todayIndex: Int
    public var weekKept: Int
    public var weekPossible: Int
    /// When this picture should be recomputed even if the app saves nothing.
    public var refreshAt: Date

    public init(commitmentId: UUID?, occurrenceId: UUID?, title: String, headline: String, phase: Phase, streak: Int, week: [DayStat],
                todayIndex: Int, weekKept: Int, weekPossible: Int, refreshAt: Date) {
        self.commitmentId = commitmentId; self.occurrenceId = occurrenceId; self.title = title; self.headline = headline; self.phase = phase
        self.streak = streak; self.week = week; self.todayIndex = todayIndex; self.weekKept = weekKept; self.weekPossible = weekPossible; self.refreshAt = refreshAt
    }

    public static func make(state: AppState, now: Date, calendar: Calendar = .current) -> TodaySnapshot {
        let week = Progress.week(containing: now, in: state, calendar: calendar)
        let streak = Progress.streak(asOf: now, in: state, calendar: calendar)
        let midnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(86_400))

        var best: Candidate?
        for c in state.commitments where c.isEnabled {
            let candidate = Self.candidate(for: c, in: state, now: now, calendar: calendar)
            if let b = best { if (candidate.rank, candidate.order) < (b.rank, b.order) { best = candidate } } else { best = candidate }
        }
        guard let pick = best else {
            return TodaySnapshot(commitmentId: nil, occurrenceId: nil, title: "No promises on", headline: "No promises on", phase: .empty,
                                 streak: streak, week: week.days, todayIndex: week.todayIndex, weekKept: week.kept, weekPossible: week.possible, refreshAt: midnight)
        }
        var refresh = midnight
        switch pick.phase {
        case .upcoming(let start): refresh = min(refresh, start)
        case .active(let endsAt, _): if let endsAt { refresh = min(refresh, max(endsAt, now.addingTimeInterval(1))) }
        default: break
        }
        return TodaySnapshot(commitmentId: pick.commitment.id, occurrenceId: pick.occurrence?.id, title: pick.commitment.title, headline: pick.commitment.headline,
                             phase: pick.phase, streak: streak, week: week.days, todayIndex: week.todayIndex, weekKept: week.kept, weekPossible: week.possible, refreshAt: refresh)
    }

    private struct Candidate { var commitment: Commitment; var occurrence: Occurrence?; var phase: Phase; var rank: Int; var order: Date }

    private static func candidate(for c: Commitment, in state: AppState, now: Date, calendar: Calendar) -> Candidate {
        let mine = state.occurrences.filter { $0.commitmentId == c.id && $0.kind == .scheduled }
        // An open occurrence wins.
        if let open = mine.filter({ !$0.state.isTerminal }).min(by: { $0.scheduledStart < $1.scheduledStart }) {
            switch open.state {
            case .active, .awaitingConfirmation:
                let remaining = open.session?.remainingSeconds(at: now) ?? 0
                let running = (open.session?.isRunning ?? false) && open.state == .active && remaining > 0
                return Candidate(commitment: c, occurrence: open, phase: .active(endsAt: running ? now.addingTimeInterval(remaining) : nil, remaining: remaining), rank: 0, order: open.scheduledStart)
            case .due:
                return Candidate(commitment: c, occurrence: open, phase: .due, rank: 1, order: open.scheduledStart)
            default:
                // Scheduled and its time has passed, but the app has not run since: it is time.
                if open.scheduledStart <= now { return Candidate(commitment: c, occurrence: open, phase: .due, rank: 1, order: open.scheduledStart) }
                return Candidate(commitment: c, occurrence: open, phase: .upcoming(start: open.scheduledStart), rank: 2, order: open.scheduledStart)
            }
        }
        // Finished today?
        let todayStart = calendar.startOfDay(for: now)
        if let done = mine.filter({ $0.outcome.map { $0.recordedAt >= todayStart } ?? false }).max(by: { ($0.outcome?.recordedAt ?? .distantPast) < ($1.outcome?.recordedAt ?? .distantPast) }) {
            let kept = done.state == .completedFull || done.state == .completedMinimum
            return Candidate(commitment: c, occurrence: done, phase: kept ? .kept(minutes: done.outcome?.activeMinutes ?? 0) : .ended, rank: 3, order: done.outcome?.recordedAt ?? now)
        }
        // Nothing open and nothing finished today: the next time it will show up, from the promise's own schedule.
        let next = Self.nextStart(of: c, after: now, calendar: calendar)
        return Candidate(commitment: c, occurrence: nil, phase: .upcoming(start: next), rank: 2, order: next)
    }

    /// The next moment this promise's time of day arrives, today if still ahead, otherwise tomorrow.
    static func nextStart(of c: Commitment, after now: Date, calendar: Calendar) -> Date {
        var cal = calendar
        if let tz = TimeZone(identifier: c.timeZoneIdentifier) { cal.timeZone = tz }
        let today = cal.startOfDay(for: now)
        let todayStart = cal.date(bySettingHour: c.startHour, minute: c.startMinute, second: 0, of: today) ?? now
        if todayStart > now { return todayStart }
        let tomorrow = cal.date(byAdding: .day, value: 1, to: today) ?? today.addingTimeInterval(86_400)
        return cal.date(bySettingHour: c.startHour, minute: c.startMinute, second: 0, of: tomorrow) ?? now.addingTimeInterval(86_400)
    }
}

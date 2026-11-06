import Foundation

public struct DayStat: Equatable, Sendable {
    public var localDate: String
    public var kept: Int
    public var possible: Int
    public var fraction: Double { possible == 0 ? 0 : Double(kept) / Double(possible) }
}

public struct WeekSummary: Equatable, Sendable {
    /// Monday through Sunday.
    public var days: [DayStat]
    public var todayIndex: Int
    public var kept: Int
    public var possible: Int
    public var activeMinutes: Double
    public var daysShowedUp: Int
}

/// Real numbers derived from distinct outcomes. A reschedule chain counts as one opportunity;
/// optional extras never count as opportunities; missing data is never counted as success.
public enum Progress {
    public static func week(containing now: Date, in state: AppState, calendar: Calendar = .current) -> WeekSummary {
        var cal = calendar
        cal.firstWeekday = 2
        let start = cal.dateInterval(of: .weekOfYear, for: now)?.start ?? cal.startOfDay(for: now)
        let keys: [String] = (0..<7).map { offset in
            let d = cal.date(byAdding: .day, value: offset, to: start) ?? start
            let c = cal.dateComponents([.year, .month, .day], from: d)
            return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
        }
        let todayComps = cal.dateComponents([.year, .month, .day], from: now)
        let todayKey = String(format: "%04d-%02d-%02d", todayComps.year ?? 0, todayComps.month ?? 0, todayComps.day ?? 0)

        // one opportunity per opportunityId, dated by its first occurrence
        let scheduled = state.occurrences.filter { $0.kind == .scheduled }
        let chains = Dictionary(grouping: scheduled, by: \.opportunityId)
        var possible = [String: Int](), kept = [String: Int]()
        for (_, chain) in chains {
            // Only days that have arrived count: an occurrence already scheduled for tomorrow is not yet an opportunity.
            guard let first = chain.min(by: { $0.scheduledStart < $1.scheduledStart }), keys.contains(first.localDate), first.localDate <= todayKey else { continue }
            possible[first.localDate, default: 0] += 1
            if chain.contains(where: { $0.state == .completedFull || $0.state == .completedMinimum }) { kept[first.localDate, default: 0] += 1 }
        }
        let days = keys.map { DayStat(localDate: $0, kept: kept[$0] ?? 0, possible: possible[$0] ?? 0) }

        let minutes = state.occurrences
            .filter { $0.state == .completedFull || $0.state == .completedMinimum }
            .filter { keys.contains($0.localDate) }
            .compactMap { $0.outcome?.activeMinutes }
            .reduce(0, +)

        return WeekSummary(days: days, todayIndex: keys.firstIndex(of: todayKey) ?? 0,
                           kept: days.map(\.kept).reduce(0, +), possible: days.map(\.possible).reduce(0, +),
                           activeMinutes: minutes, daysShowedUp: days.filter { $0.kept > 0 }.count)
    }

    // MARK: History and streaks

    /// Day-by-day record, Monday-aligned weeks, oldest first. `todayIndex` points at today inside `days`; days after it are still ahead.
    public struct History: Equatable, Sendable {
        public var days: [DayStat]
        public var todayIndex: Int
        public var weeks: Int { days.count / 7 }
        public var daysShowedUp: Int { days.filter { $0.kept > 0 }.count }
    }

    /// The last `weeks` weeks ending with the current one. Same rules as `week`: only days that have arrived count as opportunities.
    /// Pass `commitmentId` to see a single promise.
    public static func history(weeks: Int, endingWith now: Date, in state: AppState, commitmentId: UUID? = nil, calendar: Calendar = .current) -> History {
        var cal = calendar
        cal.firstWeekday = 2
        let thisWeek = cal.dateInterval(of: .weekOfYear, for: now)?.start ?? cal.startOfDay(for: now)
        let first = cal.date(byAdding: .day, value: -7 * (weeks - 1), to: thisWeek) ?? thisWeek
        func key(_ d: Date) -> String {
            let c = cal.dateComponents([.year, .month, .day], from: d)
            return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
        }
        let keys = (0..<(weeks * 7)).map { key(cal.date(byAdding: .day, value: $0, to: first) ?? first) }
        let todayKey = key(now)
        let wanted = Set(keys)

        let scheduled = state.occurrences.filter { $0.kind == .scheduled && (commitmentId == nil || $0.commitmentId == commitmentId) }
        var possible = [String: Int](), kept = [String: Int]()
        for (_, chain) in Dictionary(grouping: scheduled, by: \.opportunityId) {
            guard let head = chain.min(by: { $0.scheduledStart < $1.scheduledStart }), wanted.contains(head.localDate), head.localDate <= todayKey else { continue }
            possible[head.localDate, default: 0] += 1
            if chain.contains(where: { $0.state == .completedFull || $0.state == .completedMinimum }) { kept[head.localDate, default: 0] += 1 }
        }
        return History(days: keys.map { DayStat(localDate: $0, kept: kept[$0] ?? 0, possible: possible[$0] ?? 0) },
                       todayIndex: keys.firstIndex(of: todayKey) ?? keys.count - 1)
    }

    /// Consecutive days, ending today, on which at least one promise was kept. Today still being open does not break it:
    /// if nothing is kept yet today the count runs back from yesterday. Zero when there is nothing to count.
    public static func streak(asOf now: Date, in state: AppState, calendar: Calendar = .current) -> Int {
        let h = history(weeks: 18, endingWith: now, in: state, calendar: calendar)
        var i = h.todayIndex
        if h.days[i].kept == 0 { i -= 1 }
        var count = 0
        while i >= 0, h.days[i].kept > 0 { count += 1; i -= 1 }
        return count
    }

    /// The longest run of consecutive days with at least one promise kept, over the last year. Zero when nothing was kept.
    public static func longestStreak(asOf now: Date, in state: AppState, calendar: Calendar = .current) -> Int {
        let h = history(weeks: 53, endingWith: now, in: state, calendar: calendar)
        var best = 0, run = 0
        for (i, d) in h.days.enumerated() where i <= h.todayIndex {
            if d.kept > 0 { run += 1; best = max(best, run) } else { run = 0 }
        }
        return best
    }
}

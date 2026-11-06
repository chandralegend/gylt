import Foundation
import Testing
@testable import GYLTCore

private let utc: Calendar = { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }()
private let friday = utc.date(from: DateComponents(timeZone: TimeZone(identifier: "UTC"), year: 2026, month: 11, day: 6, hour: 12))!

@Suite("Today snapshot")
struct SnapshotTests {
    private func fresh(_ ids: [UUID]? = nil) -> AppState {
        var s = AppState(commitments: Commitment.defaults(timeZone: TimeZone(identifier: "UTC")!))
        if let ids { s.commitments = s.commitments.filter { ids.contains($0.id) } }
        return s
    }
    private func apply(_ c: Command, to s: AppState, at t: Date) throws -> AppState {
        try Engine().apply(CommandEnvelope(c), to: s, now: t, calendar: utc).state
    }

    @Test func emptyWhenNothingIsOn() {
        var s = fresh()
        for i in s.commitments.indices { s.commitments[i].isEnabled = false }
        let snap = TodaySnapshot.make(state: s, now: friday, calendar: utc)
        #expect(snap.phase == .empty)
        #expect(snap.commitmentId == nil)
    }

    @Test func theEarliestUpcomingPromiseLeads() throws {
        // Friday 12:00: the walk is at 18:30, bed tomorrow 07:30, night 22:30.
        let s = try apply(.materialize, to: fresh(), at: friday)
        let snap = TodaySnapshot.make(state: s, now: friday, calendar: utc)
        #expect(snap.commitmentId == Commitment.walkID)
        guard case .upcoming(let start) = snap.phase else { Issue.record("expected upcoming"); return }
        #expect(utc.component(.hour, from: start) == 18 && utc.component(.minute, from: start) == 30)
        #expect(snap.refreshAt == start)
        #expect(snap.headline == "Get off\nthe couch")
    }

    @Test func anActiveRunningSessionShowsWhenItEnds() throws {
        var s = try apply(.materialize, to: fresh([Commitment.walkID]), at: friday)
        let id = s.occurrences[0].id
        let t = utc.date(from: DateComponents(timeZone: TimeZone(identifier: "UTC"), year: 2026, month: 11, day: 6, hour: 18, minute: 31))!
        s = try apply(.start(id, .full), to: s, at: t)
        let snap = TodaySnapshot.make(state: s, now: t.addingTimeInterval(60), calendar: utc)
        guard case .active(let endsAt, let remaining) = snap.phase else { Issue.record("expected active"); return }
        #expect(abs(remaining - 19 * 60) < 1)
        #expect(endsAt != nil)
        #expect(snap.occurrenceId == id)
    }

    @Test func aPausedSessionHasNoEndTime() throws {
        var s = try apply(.materialize, to: fresh([Commitment.walkID]), at: friday)
        let id = s.occurrences[0].id
        let t = utc.date(from: DateComponents(timeZone: TimeZone(identifier: "UTC"), year: 2026, month: 11, day: 6, hour: 18, minute: 31))!
        s = try apply(.start(id, .full), to: s, at: t)
        s = try apply(.pauseTimer(id), to: s, at: t.addingTimeInterval(120))
        let snap = TodaySnapshot.make(state: s, now: t.addingTimeInterval(300), calendar: utc)
        guard case .active(let endsAt, let remaining) = snap.phase else { Issue.record("expected active"); return }
        #expect(endsAt == nil)
        #expect(abs(remaining - 18 * 60) < 1)
    }

    @Test func aKeptPromiseShowsKeptThenTomorrowComesAfterMidnight() throws {
        var s = try apply(.materialize, to: fresh([Commitment.walkID]), at: friday)
        let id = s.occurrences[0].id
        let t = utc.date(from: DateComponents(timeZone: TimeZone(identifier: "UTC"), year: 2026, month: 11, day: 6, hour: 18, minute: 31))!
        s = try apply(.start(id, .full), to: s, at: t)
        s = try apply(.reportDone(id, .full), to: s, at: t.addingTimeInterval(1200))
        let evening = t.addingTimeInterval(3600)
        guard case .kept(let minutes) = TodaySnapshot.make(state: s, now: evening, calendar: utc).phase else { Issue.record("expected kept"); return }
        #expect(abs(minutes - 20) < 0.5)
        // The next morning the app may not have run, but the widget still points at the walk's next start.
        let morning = utc.date(from: DateComponents(timeZone: TimeZone(identifier: "UTC"), year: 2026, month: 11, day: 7, hour: 8))!
        let next = TodaySnapshot.make(state: s, now: morning, calendar: utc)
        guard case .upcoming(let start) = next.phase else { Issue.record("expected upcoming"); return }
        #expect(utc.component(.day, from: start) == 7 && utc.component(.hour, from: start) == 18)
    }

    @Test func aSwitchedOffPromiseIsNeverShown() throws {
        var s = try apply(.materialize, to: fresh(), at: friday)
        for i in s.commitments.indices where s.commitments[i].id == Commitment.walkID { s.commitments[i].isEnabled = false }
        let snap = TodaySnapshot.make(state: s, now: friday, calendar: utc)
        #expect(snap.commitmentId != Commitment.walkID)
    }

    @Test func streakAndWeekMatchTheAppsOwnNumbers() throws {
        let s = try apply(.materialize, to: fresh(), at: friday)
        let snap = TodaySnapshot.make(state: s, now: friday, calendar: utc)
        let week = Progress.week(containing: friday, in: s, calendar: utc)
        #expect(snap.weekKept == week.kept && snap.weekPossible == week.possible)
        #expect(snap.streak == Progress.streak(asOf: friday, in: s, calendar: utc))
        #expect(snap.week.count == 7)
    }

    @Test func aScheduledPromiseWhoseTimeHasPassedIsDueEvenIfTheAppHasNotRun() throws {
        let s = try apply(.materialize, to: fresh([Commitment.walkID]), at: friday)     // walk at 18:30, saved at noon
        let later = utc.date(from: DateComponents(timeZone: TimeZone(identifier: "UTC"), year: 2026, month: 11, day: 6, hour: 18, minute: 40))!
        #expect(TodaySnapshot.make(state: s, now: later, calendar: utc).phase == .due)
    }
}


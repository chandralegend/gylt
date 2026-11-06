import Foundation
import Testing
@testable import GYLTCore

private let utc: Calendar = { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }()
// Friday 6 Nov 2026, 18:00 UTC
private let friday = utc.date(from: DateComponents(timeZone: TimeZone(identifier: "UTC"), year: 2026, month: 11, day: 6, hour: 18))!

@Suite("Weekly progress")
struct ProgressTests {
    private func run(_ commands: [(Command, TimeInterval)]) throws -> AppState {
        var s = AppState(commitments: Commitment.defaults(timeZone: TimeZone(identifier: "UTC")!).filter { $0.id == Commitment.walkID })
        for (c, offsetMinutes) in commands {
            s = try Engine().apply(CommandEnvelope(c), to: s, now: friday.addingTimeInterval(offsetMinutes * 60), calendar: utc).state
        }
        return s
    }

    @Test func emptyWeekIsAllZeroNotSuccess() throws {
        let s = try run([(.materialize, 0)])
        let w = Progress.week(containing: friday, in: s, calendar: utc)
        #expect(w.days.count == 7)
        #expect(w.kept == 0)
        #expect(w.possible == 1)           // today's walk is still open
        #expect(w.todayIndex == 4)         // Friday
        #expect(w.activeMinutes == 0)
    }

    @Test func occurrencesScheduledForTomorrowAreNotYetOpportunities() throws {
        // 23:00 Friday: today's 18:30 walk window is over, so the walk is scheduled for Saturday.
        var s = AppState(commitments: Commitment.defaults(timeZone: TimeZone(identifier: "UTC")!).filter { $0.id == Commitment.walkID })
        let late = friday.addingTimeInterval(5 * 3600)
        s = try Engine().apply(CommandEnvelope(.materialize), to: s, now: late, calendar: utc).state
        #expect(s.occurrences.first?.localDate == "2026-11-07")
        let w = Progress.week(containing: late, in: s, calendar: utc)
        #expect(w.possible == 0)
        #expect(w.kept == 0)
    }

    @Test func aKeptWalkCountsOnceWithItsRealMinutes() throws {
        var s = try run([(.materialize, 0)])
        let id = s.occurrences[0].id
        s = try Engine().apply(CommandEnvelope(.start(id, .full)), to: s, now: friday, calendar: utc).state
        s = try Engine().apply(CommandEnvelope(.reportDone(id, .minimum)), to: s, now: friday.addingTimeInterval(6 * 60), calendar: utc).state
        let w = Progress.week(containing: friday, in: s, calendar: utc)
        #expect(w.kept == 1)
        #expect(w.daysShowedUp == 1)
        #expect(abs(w.activeMinutes - 6) < 0.01)
        #expect(w.days[4].fraction == 1)
    }

    @Test func rescheduledChainIsOneOpportunityAndExtrasAreNotOpportunities() throws {
        var s = try run([(.materialize, 0)])
        let first = s.occurrences[0].id
        s = try Engine().apply(CommandEnvelope(.start(first, .full)), to: s, now: friday, calendar: utc).state
        s = try Engine().apply(CommandEnvelope(.reschedule(first, minutes: 30)), to: s, now: friday.addingTimeInterval(60), calendar: utc).state
        let second = s.occurrences.last!.id
        s = try Engine().apply(CommandEnvelope(.start(second, .full)), to: s, now: friday.addingTimeInterval(35 * 60), calendar: utc).state
        s = try Engine().apply(CommandEnvelope(.reportDone(second, .full)), to: s, now: friday.addingTimeInterval(55 * 60), calendar: utc).state
        s = try Engine().apply(CommandEnvelope(.startFresh(from: second, minutes: 5)), to: s, now: friday.addingTimeInterval(56 * 60), calendar: utc).state
        let w = Progress.week(containing: friday, in: s, calendar: utc)
        #expect(w.possible == 1)
        #expect(w.kept == 1)
    }
}

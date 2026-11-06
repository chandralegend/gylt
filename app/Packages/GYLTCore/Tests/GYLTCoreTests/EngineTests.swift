import Foundation
import Testing
@testable import GYLTCore

/// Fixed clock and calendar so every rule is deterministic.
private let utc: Calendar = { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }()
private let day = utc.date(from: DateComponents(timeZone: TimeZone(identifier: "UTC"), year: 2026, month: 11, day: 6, hour: 18, minute: 0))!

private func minutes(_ m: Double, after t: Date = day) -> Date { t.addingTimeInterval(m * 60) }

private struct Harness {
    var state: AppState
    let engine = Engine()
    var effects: [SideEffect] = []

    init() {
        var s = AppState(commitments: Commitment.defaults(timeZone: TimeZone(identifier: "UTC")!))
        s.commitments = s.commitments.filter { $0.id == Commitment.walkID }   // one commitment keeps assertions simple
        state = s
    }

    @discardableResult
    mutating func send(_ command: Command, at now: Date, id: UUID = UUID()) throws -> EngineResult {
        let r = try engine.apply(CommandEnvelope(command, id: id), to: state, now: now, calendar: utc)
        state = r.state
        effects += r.effects
        return r
    }

    var occ: Occurrence { state.occurrences.first { !$0.state.isTerminal } ?? state.occurrences.last! }
    func occurrence(_ id: UUID) -> Occurrence { state.occurrence(id)! }
}

private func started(mode: SessionMode = .full, at t: Date = day) throws -> Harness {
    var h = Harness()
    try h.send(.materialize, at: t)
    try h.send(.start(h.occ.id, mode), at: t)
    return h
}

@Suite("Scheduling")
struct SchedulingTests {
    @Test func reviewedProofRecordsTheOutcomeWithItsEvidenceAndReason() throws {
        var h = try started()
        let r = try h.send(.reportReviewed(h.occ.id, ReviewedReport(mode: .full, reason: "Photo shows the river path.", usedPhoto: true, usedText: false)), at: minutes(21))
        let o = try #require(h.state.occurrences.first?.outcome)
        #expect(o.kind == .full)
        #expect(o.evidence == .aiReviewed)
        #expect(o.note == "Photo shows the river path.")
        #expect(h.state.occurrences.first?.state == .completedFull)
        #expect(r.events.contains { $0.type == .outcomeRecorded && $0.detail["evidence"] == "aiReviewed" && $0.detail["photo"] == "1" })
    }

    @Test func aSelfReportStaysMarkedAsSelfReported() throws {
        var h = try started()
        try h.send(.reportDone(h.occ.id, .minimum), at: minutes(6))
        #expect(h.state.occurrences.first?.outcome?.evidence == .selfReport)
        #expect(h.state.occurrences.first?.outcome?.note == nil)
    }

    @Test func aPromiseSwitchedOffStopsBeingScheduled() throws {
        var h = Harness()
        try h.send(.materialize, at: day)
        #expect(h.state.occurrences.count == 1)
        var walk = h.state.commitments[0]; walk.isEnabled = false
        try h.send(.upsertCommitment(walk), at: day)
        #expect(h.state.occurrences.isEmpty)
        try h.send(.materialize, at: minutes(5))
        #expect(h.state.occurrences.isEmpty)
        walk.isEnabled = true
        try h.send(.upsertCommitment(walk), at: minutes(10))     // switched back on: scheduled again
        #expect(h.state.occurrences.count == 1)
    }

    @Test func switchingOffADuePromiseReleasesItsPause() throws {
        var h = Harness()
        try h.send(.materialize, at: day)
        try h.send(.trigger(h.occ.id), at: minutes(30))          // due, lease granted
        #expect(h.occ.hasActiveLease)
        var walk = h.state.commitments[0]; walk.isEnabled = false
        let r = try h.send(.upsertCommitment(walk), at: minutes(31))
        #expect(h.state.occurrences.isEmpty)
        #expect(r.effects.contains { if case .releaseRestriction = $0 { true } else { false } })
    }

    @Test func materializeCreatesTodaysOccurrenceBeforeItsWindowCloses() throws {
        var h = Harness()
        try h.send(.materialize, at: day)           // 18:00, walk is at 18:30
        #expect(h.state.occurrences.count == 1)
        #expect(h.occ.state == .scheduled)
        #expect(h.occ.localDate == "2026-11-06")
    }

    @Test func materializeSchedulesTomorrowWhenTodaysWindowHasPassed() throws {
        var h = Harness()
        try h.send(.materialize, at: minutes(5 * 60))   // 23:00, window closed at 19:00
        #expect(h.occ.localDate == "2026-11-07")
    }

    @Test func materializeIsIdempotent() throws {
        var h = Harness()
        try h.send(.materialize, at: day)
        try h.send(.materialize, at: day)
        #expect(h.state.occurrences.count == 1)
    }
}

@Suite("Elapsed time and targets")
struct ElapsedTests {
    @Test func switchingToMinimumKeepsElapsedAndBackKeepsItToo() throws {
        var h = try started()                                        // 20-minute walk
        let id = h.occ.id
        try h.send(.selectTarget(id, .minimum), at: minutes(3))      // 3 min in
        #expect(h.occurrence(id).session!.remainingSeconds(at: minutes(3)) == 120)   // 5 - 3 = 2 min left
        try h.send(.selectTarget(id, .full), at: minutes(3))
        #expect(h.occurrence(id).session!.activeSeconds(at: minutes(3)) == 180)
        #expect(h.occurrence(id).session!.remainingSeconds(at: minutes(3)) == 17 * 60)
    }

    @Test func minimumAlreadyMetAsksForConfirmationImmediatelyAndKeepsRealElapsed() throws {
        var h = try started()
        let id = h.occ.id
        try h.send(.selectTarget(id, .minimum), at: minutes(7))
        #expect(h.occurrence(id).state == .awaitingConfirmation)
        #expect(h.occurrence(id).session!.activeSeconds(at: minutes(9)) == 7 * 60)   // clock stopped, 7 minutes recorded
        try h.send(.selectTarget(id, .full), at: minutes(7))                        // switching back resumes everything
        #expect(h.occurrence(id).state == .active)
        #expect(h.occurrence(id).session!.activeSeconds(at: minutes(7)) == 7 * 60)
    }

    @Test func pausedTimeDoesNotCount() throws {
        var h = try started()
        let id = h.occ.id
        try h.send(.pauseTimer(id), at: minutes(4))
        try h.send(.resumeTimer(id), at: minutes(10))     // 6 minutes paused
        #expect(h.occurrence(id).session!.activeSeconds(at: minutes(12)) == 6 * 60)
    }

    @Test func reachingTheTargetNeverRecordsACompletion() throws {
        var h = try started(mode: .minimum)
        let id = h.occ.id
        try h.send(.tick, at: minutes(30))                // long past the 5-minute minimum
        let o = h.occurrence(id)
        #expect(o.state == .awaitingConfirmation)
        #expect(o.outcome == nil)
        #expect(o.session!.activeSeconds(at: minutes(60)) == 5 * 60)   // stopped at the target instant, not at tick time
    }
}

@Suite("Restriction authority")
struct LeaseTests {
    @Test func startGrantsALeaseWithAFixedExpiry() throws {
        let h = try started()
        let lease = try #require(h.occ.lease)
        #expect(lease.status == .active)
        #expect(lease.expiresAt == minutes(30))
        #expect(h.effects.contains(.applyRestriction(leaseId: lease.id, apps: lease.apps, expiresAt: lease.expiresAt)))
    }

    @Test func pauseSwitchAndRoundTripNeverMoveTheExpiry() throws {
        var h = try started()
        let id = h.occ.id
        let expiry = h.occ.lease!.expiresAt
        try h.send(.pauseTimer(id), at: minutes(2))
        try h.send(.resumeTimer(id), at: minutes(5))
        try h.send(.selectTarget(id, .minimum), at: minutes(6))
        try h.send(.selectTarget(id, .full), at: minutes(6))
        #expect(h.occurrence(id).lease!.expiresAt == expiry)
        // survives a save/restart
        let data = try FileStateStore.encoder.encode(h.state)
        let restored = try FileStateStore.decoder.decode(AppState.self, from: data)
        #expect(restored.occurrence(id)!.lease!.expiresAt == expiry)
        #expect(restored == h.state)
    }

    @Test func expiryReleasesEvenWhenTheSessionKeepsRunning() throws {
        var h = try started()
        let id = h.occ.id
        let r = try h.send(.tick, at: minutes(31))
        #expect(h.occurrence(id).lease!.status == .released)
        #expect(h.occurrence(id).lease!.releaseReason == .expired)
        #expect(h.occurrence(id).state == .active || h.occurrence(id).state == .awaitingConfirmation)
        #expect(r.effects.contains { if case .releaseRestriction(_, .expired) = $0 { true } else { false } })
    }

    @Test func everyTerminalOutcomeReleasesTheLease() throws {
        let cases: [(String, (inout Harness, UUID) throws -> Void)] = [
            ("done", { h, id in try h.send(.reportDone(id, .full), at: minutes(10)) }),
            ("minimum", { h, id in try h.send(.reportDone(id, .minimum), at: minutes(10)) }),
            ("override", { h, id in try h.send(.endUnfinished(id), at: minutes(10)) }),
            ("rest", { h, id in try h.send(.restForDay(id), at: minutes(10)) }),
            ("reschedule", { h, id in try h.send(.reschedule(id, minutes: 30), at: minutes(10)) }),
        ]
        for (name, act) in cases {
            var h = try started()
            let id = h.occ.id
            try act(&h, id)
            #expect(h.occurrence(id).lease?.status == .released, "lease should be released after \(name)")
            #expect(h.occurrence(id).state.isTerminal, "\(name) should be terminal")
        }
    }

    @Test func revokingPermissionReleasesAndStopsFutureLeases() throws {
        var h = try started()
        let id = h.occ.id
        try h.send(.setRestrictionPermission(false), at: minutes(3))
        #expect(h.occurrence(id).lease!.releaseReason == .permissionRevoked)
        // a new occurrence after revocation gets no lease
        try h.send(.reportDone(id, .full), at: minutes(4))
        try h.send(.startFresh(from: id, minutes: 5), at: minutes(5))
        #expect(h.state.occurrences.last!.lease == nil)
    }

    @Test func clockMovingBackwardsFailsOpen() throws {
        var h = try started()
        let id = h.occ.id
        try h.send(.tick, at: minutes(10))
        try h.send(.tick, at: minutes(-60))               // clock set back an hour
        #expect(h.occurrence(id).lease!.status == .released)
        #expect(h.occurrence(id).lease!.releaseReason == .clockAnomaly)
        #expect(h.state.events.contains { $0.type == .clockAnomaly })
    }

    @Test func smallClockJitterIsTolerated() throws {
        var h = try started()
        try h.send(.tick, at: minutes(10))
        try h.send(.tick, at: minutes(10).addingTimeInterval(-30))   // 30 s back, e.g. network time sync
        #expect(h.occ.lease!.status == .active)
    }

    @Test func coachingOnlyWhenBlockingIsOff() throws {
        var h = Harness()
        h.state.commitments[0].blockingEnabled = false
        try h.send(.materialize, at: day)
        try h.send(.start(h.occ.id, .full), at: day)
        #expect(h.occ.lease == nil)
    }
}

@Suite("Outcomes and linking")
struct OutcomeTests {
    @Test func fullAndMinimumAreDistinctAndSelfReported() throws {
        var a = try started(); try a.send(.reportDone(a.occ.id, .full), at: minutes(20))
        var b = try started(); try b.send(.reportDone(b.occ.id, .minimum), at: minutes(5))
        #expect(a.state.occurrences[0].state == .completedFull)
        #expect(b.state.occurrences[0].state == .completedMinimum)
        #expect(a.state.occurrences[0].outcome?.evidence == .selfReport)
    }

    @Test func overrideIsRecordedHonestlyAsUnfinished() throws {
        var h = try started()
        try h.send(.endUnfinished(h.occ.id), at: minutes(2))
        #expect(h.state.occurrences[0].outcome?.kind == .unfinished)
    }

    @Test func rescheduleKeepsOneOpportunityAndLinksTheChain() throws {
        var h = try started()
        let first = h.occ
        try h.send(.reschedule(first.id, minutes: 30), at: minutes(5))
        let next = try #require(h.state.occurrences.last)
        #expect(next.id != first.id)
        #expect(next.opportunityId == first.opportunityId)
        #expect(next.rescheduledFromOccurrenceId == first.id)
        #expect(next.state == .scheduled)
        #expect(next.scheduledStart == minutes(35))
        #expect(h.state.occurrences.first!.state == .rescheduled)
    }

    @Test func aTerminalOccurrenceIsNeverReopened() throws {
        var h = try started()
        let id = h.occ.id
        try h.send(.reportDone(id, .full), at: minutes(20))
        #expect(throws: EngineError.self) { try h.send(.start(id, .full), at: minutes(21)) }
        #expect(throws: EngineError.self) { try h.send(.pauseTimer(id), at: minutes(21)) }
        #expect(throws: EngineError.self) { try h.send(.reportDone(id, .minimum), at: minutes(21)) }
    }

    @Test func fiveMoreMinutesCreatesANewLinkedExtraWithNoRestrictionAndNoNewOpportunity() throws {
        var h = try started()
        let first = h.occ
        try h.send(.reportDone(first.id, .full), at: minutes(20))
        try h.send(.startFresh(from: first.id, minutes: 5), at: minutes(21))
        let extra = try #require(h.state.occurrences.last)
        #expect(extra.kind == .extra)
        #expect(extra.continuesOccurrenceId == first.id)
        #expect(extra.opportunityId != first.opportunityId)
        #expect(extra.lease == nil)
        #expect(extra.state == .active)
        #expect(h.state.occurrence(first.id)!.state == .completedFull)   // earlier success untouched
    }

    @Test func startFreshRequiresAFinishedOccurrence() throws {
        var h = try started()
        #expect(throws: EngineError.self) { try h.send(.startFresh(from: h.occ.id, minutes: 5), at: minutes(1)) }
    }

    @Test func ignoredOccurrenceBecomesMissedAndReleases() throws {
        var h = Harness()
        try h.send(.materialize, at: day)
        let id = h.occ.id
        try h.send(.tick, at: minutes(30 + 61))    // 18:30 start + 30 min window passed
        #expect(h.state.occurrence(id)!.state == .missed)
        #expect(h.state.occurrence(id)!.outcome?.kind == .missed)
    }
}

@Suite("Safety of the command pipeline")
struct PipelineTests {
    @Test func duplicateCommandDeliveryIsANoOp() throws {
        var h = Harness()
        try h.send(.materialize, at: day)
        let id = h.occ.id
        let cmd = UUID()
        try h.send(.start(id, .full), at: day, id: cmd)
        let before = h.state
        try h.send(.start(id, .full), at: day, id: cmd)    // retry of the same command
        #expect(h.state == before)
        #expect(h.effects.filter { if case .applyRestriction = $0 { true } else { false } }.count == 1)
    }

    @Test func settingsChangesReportAnEventSoTheyGetSaved() throws {
        var h = Harness()
        var s = h.state.settings
        s.tone = .savage; s.onboardingCompleted = true
        let r = try h.send(.updateSettings(s), at: day)
        #expect(!r.events.isEmpty)                       // the app only persists when there are events or effects
        #expect(h.state.settings.tone == .savage)
        #expect(h.state.settings.onboardingCompleted)
        let again = try h.send(.updateSettings(s), at: day)   // no change, nothing to save
        #expect(again.events.isEmpty)
    }

    @Test func invalidCommitmentsAreRejected() throws {
        var h = Harness()
        var bad = h.state.commitments[0]
        bad.minimumMinutes = 25                           // longer than the full version
        #expect(throws: EngineError.self) { try h.send(.upsertCommitment(bad), at: day) }
        bad.minimumMinutes = 5; bad.title = "   "
        #expect(throws: EngineError.self) { try h.send(.upsertCommitment(bad), at: day) }
    }

    @Test func editingAPlanRebuildsOnlyUnstartedOccurrences() throws {
        var h = Harness()
        try h.send(.materialize, at: day)
        var edited = h.state.commitments[0]
        edited.minimumMinutes = 10
        try h.send(.upsertCommitment(edited), at: day)
        #expect(h.state.commitments[0].revision == 2)
        #expect(h.state.occurrences.filter { !$0.state.isTerminal }.count == 1)
        #expect(h.occ.commitmentRevision == 2)
    }

    @Test func stateSurvivesAFileRoundTripAtomically() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("gylt-test-\(UUID().uuidString)/state.json")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = FileStateStore(url: url)
        #expect(try store.load() == nil)
        var h = try started()
        try h.send(.pauseTimer(h.occ.id), at: minutes(2))
        try store.save(h.state)
        #expect(try store.load() == h.state)
    }
}

@Suite("Coach")
struct CoachTests {
    @Test func unknownSuggestionsFromAModelAreDropped() {
        #expect(CoachOutputValidator.suggestion(from: "offerMinimum") == .offerMinimum)
        #expect(CoachOutputValidator.suggestion(from: "extendBlockForOneHour") == .none)
        #expect(CoachOutputValidator.suggestion(from: nil) == .none)
    }

    @Test func modelTextIsBoundedAndStripped() {
        let long = String(repeating: "x", count: 1000)
        #expect(CoachOutputValidator.sanitize(long).count <= CoachOutputValidator.maxCharacters + 1)
        #expect(CoachOutputValidator.sanitize("hi\u{0007}\u{0000} there") == "hi there")
    }

    @Test func finishedCopyNeverQuotesAnUnbackedNumber() {
        let coach = ScriptedCoach()
        func line(_ minutes: Int) -> String {
            coach.line(for: CoachContext(commitmentTitle: "Walk", commitmentId: Commitment.walkID, firstStep: "Shoes.", minimumMinutes: 5,
                                         tone: .direct, persona: .coach, moment: .finished(minimum: true, minutes: minutes)))
        }
        #expect(!line(0).contains("0 minutes"))
        #expect(line(1).hasPrefix("1 minute beats"))
        #expect(line(6).hasPrefix("6 minutes beats"))
    }

    @Test func scriptedCoachNeverPromisesAuthority() async throws {
        let ctx = CoachContext(commitmentTitle: "Evening walk", commitmentId: Commitment.walkID, firstStep: "Shoes.", minimumMinutes: 5,
                               tone: .savage, persona: .coach, moment: .stuck)
        let reply = try await ScriptedCoach().reply(for: ctx)
        #expect(reply.suggestion == .offerMinimum)
        #expect(!reply.text.isEmpty)
    }
}

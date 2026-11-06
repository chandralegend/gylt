import Foundation

// MARK: - Commands and results

public enum Command: Equatable, Sendable {
    /// Make sure every enabled commitment has a scheduled or open occurrence.
    case materialize
    /// Reconcile with the clock only (expiry, target reached, missed).
    case tick
    case trigger(UUID)
    case start(UUID, SessionMode)
    case pauseTimer(UUID)
    case resumeTimer(UUID)
    case selectTarget(UUID, SessionMode)
    /// The user reports what actually happened. Never inferred from the timer.
    case reportDone(UUID, SessionMode)
    /// The person showed proof and their chosen model judged it counts. The app only sends this for a full or minimum verdict.
    case reportReviewed(UUID, ReviewedReport)
    case reschedule(UUID, minutes: Int)
    case restForDay(UUID)
    case endUnfinished(UUID)
    /// "Five more minutes" / "try again": a new linked session. Never reopens a finished occurrence and never carries restrictions.
    case startFresh(from: UUID, minutes: Int)
    case setRestrictionPermission(Bool)
    case upsertCommitment(Commitment)
    case removeCommitment(UUID)
    case updateSettings(Settings)
}


public struct ReviewedReport: Equatable, Sendable {
    public var mode: SessionMode
    public var reason: String
    public var usedPhoto: Bool
    public var usedText: Bool
    public init(mode: SessionMode, reason: String, usedPhoto: Bool, usedText: Bool) {
        self.mode = mode; self.reason = reason; self.usedPhoto = usedPhoto; self.usedText = usedText
    }
}

public struct CommandEnvelope: Sendable {
    public let id: UUID
    public let command: Command
    public init(_ command: Command, id: UUID = UUID()) { self.id = id; self.command = command }
}

/// Things the platform must do after a transition. The engine never performs them itself.
public enum SideEffect: Equatable, Sendable {
    case applyRestriction(leaseId: UUID, apps: Set<ProtectedApp>, expiresAt: Date)
    case releaseRestriction(leaseId: UUID, reason: ReleaseReason)
    case scheduleTrigger(occurrenceId: UUID, at: Date)
    case cancelTrigger(occurrenceId: UUID)
}

public struct EngineResult: Sendable {
    public var state: AppState
    public var events: [Event]
    public var effects: [SideEffect]
}

public enum EngineError: Error, Equatable, Sendable {
    case unknownOccurrence(UUID)
    case unknownCommitment(UUID)
    case invalidTransition(from: OccurrenceState, command: String)
    case invalidArgument(String)
}

// MARK: - Engine

/// Deterministic reducer. `now` is always passed in, so every rule is testable without a clock.
public struct Engine: Sendable {
    /// A clock that moves back by more than this is treated as an anomaly: authority is released.
    public static let clockToleranceSeconds: TimeInterval = 120
    /// An open occurrence this long after its start is closed as missed.
    public static let abandonAfterSeconds: TimeInterval = 12 * 3600
    public static let maxRememberedCommands = 200

    public init() {}

    public func apply(_ envelope: CommandEnvelope, to state: AppState, now: Date, calendar: Calendar = .current) throws -> EngineResult {
        // Duplicate delivery (retries, double taps) is a no-op.
        if state.appliedCommandIds.contains(envelope.id) {
            return EngineResult(state: state, events: [], effects: [])
        }
        var r = Reducer(state: state, now: now, calendar: calendar)
        r.reconcile()
        try r.handle(envelope.command)
        r.reconcile()
        r.state.appliedCommandIds.append(envelope.id)
        if r.state.appliedCommandIds.count > Engine.maxRememberedCommands {
            r.state.appliedCommandIds.removeFirst(r.state.appliedCommandIds.count - Engine.maxRememberedCommands)
        }
        return EngineResult(state: r.state, events: r.events, effects: r.effects)
    }
}

// MARK: - Reducer

struct Reducer {
    var state: AppState
    var events: [Event] = []
    var effects: [SideEffect] = []
    let now: Date
    let calendar: Calendar

    init(state: AppState, now: Date, calendar: Calendar) {
        self.state = state; self.now = now; self.calendar = calendar
    }

    // MARK: helpers

    mutating func emit(_ type: EventType, _ occurrence: UUID? = nil, _ detail: [String: String] = [:]) {
        let e = Event(id: UUID(), sequence: state.nextSequence, occurrenceId: occurrence, type: type, at: now, detail: detail)
        state.nextSequence += 1
        state.events.append(e)
        events.append(e)
    }

    func index(of id: UUID) throws -> Int {
        guard let i = state.occurrences.firstIndex(where: { $0.id == id }) else { throw EngineError.unknownOccurrence(id) }
        return i
    }

    func windowSeconds(for occurrence: Occurrence) -> TimeInterval {
        Double(state.commitment(occurrence.commitmentId)?.restrictionWindowMinutes ?? 30) * 60
    }

    mutating func closeSegment(_ i: Int, at date: Date) {
        guard var s = state.occurrences[i].session, let since = s.runningSince else { return }
        s.closedActiveSeconds += max(0, date.timeIntervalSince(since))
        s.runningSince = nil
        state.occurrences[i].session = s
    }

    mutating func grantLeaseIfEligible(_ i: Int) {
        let occ = state.occurrences[i]
        guard occ.kind == .scheduled, occ.lease == nil, state.permissions.restrictionsAuthorized,
              let c = state.commitment(occ.commitmentId), c.blockingEnabled, !c.protectedApps.isEmpty else { return }
        let lease = RestrictionLease(grantedAt: now, expiresAt: now.addingTimeInterval(Double(c.restrictionWindowMinutes) * 60), apps: c.protectedApps)
        state.occurrences[i].lease = lease
        effects.append(.applyRestriction(leaseId: lease.id, apps: lease.apps, expiresAt: lease.expiresAt))
        emit(.restrictionApplied, occ.id, ["expiresAt": String(lease.expiresAt.timeIntervalSince1970)])
    }

    mutating func releaseLease(_ i: Int, _ reason: ReleaseReason) {
        guard var lease = state.occurrences[i].lease, lease.status == .active else { return }
        lease.status = .released
        lease.releasedAt = now
        lease.releaseReason = reason
        state.occurrences[i].lease = lease
        effects.append(.releaseRestriction(leaseId: lease.id, reason: reason))
        emit(reason == .expired ? .restrictionExpired : .restrictionReleased, state.occurrences[i].id, ["reason": reason.rawValue])
    }

    mutating func finish(_ i: Int, as newState: OccurrenceState, outcome kind: OutcomeKind, release reason: ReleaseReason) {
        closeSegment(i, at: now)
        let minutes = state.occurrences[i].session.map { $0.activeSeconds(at: now) / 60 }
        state.occurrences[i].state = newState
        state.occurrences[i].outcome = Outcome(kind: kind, activeMinutes: minutes, evidence: kind == .full || kind == .minimum ? .selfReport : .none, recordedAt: now)
        releaseLease(i, reason)
        effects.append(.cancelTrigger(occurrenceId: state.occurrences[i].id))
    }

    // MARK: reconcile (runs before and after every command)

    mutating func reconcile() {
        if let last = state.lastObservedAt, now.timeIntervalSince(last) < -Engine.clockToleranceSeconds {
            emit(.clockAnomaly, nil, ["backwardsBySeconds": String(Int(last.timeIntervalSince(now)))])
            for i in state.occurrences.indices { releaseLease(i, .clockAnomaly) }
        }
        state.lastObservedAt = now

        for i in state.occurrences.indices {
            // 1. Expiry is independent of behaviour: it releases even if the session continues.
            if let lease = state.occurrences[i].lease, lease.status == .active, now >= lease.expiresAt {
                releaseLease(i, .expired)
            }
            // 2. Target reached: stop the clock at the exact instant and ask; never infer completion.
            if state.occurrences[i].state == .active, let s = state.occurrences[i].session, let since = s.runningSince,
               s.remainingSeconds(at: now) <= 0 {
                let reachedAt = since.addingTimeInterval(max(0, Double(s.targetSeconds) - s.closedActiveSeconds))
                closeSegment(i, at: min(reachedAt, now))
                state.occurrences[i].state = .awaitingConfirmation
                emit(.targetReached, state.occurrences[i].id)
            }
            // 3. Missed: the window closed with no outcome.
            let occ = state.occurrences[i]
            if occ.state == .scheduled || occ.state == .due, now >= occ.scheduledStart.addingTimeInterval(windowSeconds(for: occ)) {
                finish(i, as: .missed, outcome: .missed, release: .missed)
                emit(.missed, occ.id)
            } else if !occ.state.isTerminal, now >= occ.scheduledStart.addingTimeInterval(Engine.abandonAfterSeconds) {
                finish(i, as: .missed, outcome: .missed, release: .missed)
                emit(.missed, occ.id, ["reason": "abandoned"])
            }
        }
    }

    // MARK: commands

    mutating func handle(_ command: Command) throws {
        switch command {
        case .tick: break
        case .materialize: materialize()
        case .trigger(let id): try trigger(id)
        case .start(let id, let mode): try start(id, mode)
        case .pauseTimer(let id): try pause(id)
        case .resumeTimer(let id): try resume(id)
        case .selectTarget(let id, let mode): try selectTarget(id, mode)
        case .reportDone(let id, let mode): try reportDone(id, mode)
        case .reportReviewed(let id, let report): try reportReviewed(id, report)
        case .reschedule(let id, let minutes): try reschedule(id, minutes)
        case .restForDay(let id): try rest(id)
        case .endUnfinished(let id): try endUnfinished(id)
        case .startFresh(let from, let minutes): try startFresh(from, minutes)
        case .setRestrictionPermission(let on): setPermission(on)
        case .upsertCommitment(let c): try upsert(c)
        case .removeCommitment(let id): remove(id)
        case .updateSettings(let s):
            // Every change to saved state must report an event: the app persists whenever events or effects exist.
            guard s != state.settings else { return }
            state.settings = s
            emit(.settingsChanged)
        }
    }

    private func requireOpen(_ i: Int, _ name: String, allowed: Set<OccurrenceState>) throws {
        let s = state.occurrences[i].state
        guard allowed.contains(s) else { throw EngineError.invalidTransition(from: s, command: name) }
    }

    mutating func trigger(_ id: UUID) throws {
        let i = try index(of: id)
        try requireOpen(i, "trigger", allowed: [.scheduled])
        state.occurrences[i].state = .due
        emit(.occurrenceDue, id)
        grantLeaseIfEligible(i)
    }

    mutating func start(_ id: UUID, _ mode: SessionMode) throws {
        let i = try index(of: id)
        try requireOpen(i, "start", allowed: [.scheduled, .due])
        guard let c = state.commitment(state.occurrences[i].commitmentId) else { throw EngineError.unknownCommitment(state.occurrences[i].commitmentId) }
        state.occurrences[i].session = Session(id: UUID(), mode: mode, fullSeconds: c.fullMinutes * 60, minimumSeconds: c.minimumMinutes * 60,
                                               startedAt: now, closedActiveSeconds: 0, runningSince: now)
        state.occurrences[i].state = .active
        grantLeaseIfEligible(i)
        emit(.sessionStarted, id, ["mode": mode.rawValue])
    }

    mutating func pause(_ id: UUID) throws {
        let i = try index(of: id)
        try requireOpen(i, "pauseTimer", allowed: [.active])
        guard state.occurrences[i].session?.isRunning == true else { return }
        closeSegment(i, at: now)   // the lease deadline is untouched
        emit(.timerPaused, id)
    }

    mutating func resume(_ id: UUID) throws {
        let i = try index(of: id)
        try requireOpen(i, "resumeTimer", allowed: [.active])
        guard state.occurrences[i].session?.isRunning == false else { return }
        let t = now
        state.occurrences[i].session?.runningSince = t
        emit(.timerResumed, id)
    }

    /// Changing the target changes only the target. Elapsed time and the lease deadline are preserved.
    mutating func selectTarget(_ id: UUID, _ mode: SessionMode) throws {
        let i = try index(of: id)
        try requireOpen(i, "selectTarget", allowed: [.active, .awaitingConfirmation])
        guard var s = state.occurrences[i].session else { return }
        let from = s.mode
        let elapsed = s.activeSeconds(at: now)
        s.mode = mode
        state.occurrences[i].session = s
        emit(.targetChanged, id, ["from": from.rawValue, "to": mode.rawValue, "elapsedSeconds": String(Int(elapsed))])
        let remaining = s.remainingSeconds(at: now)
        if remaining <= 0 {
            // Already met (e.g. 7 minutes in, switching to a 5-minute minimum): ask right away, keep the real elapsed time.
            closeSegment(i, at: now)
            if state.occurrences[i].state != .awaitingConfirmation {
                state.occurrences[i].state = .awaitingConfirmation
                emit(.targetReached, id)
            }
        } else if state.occurrences[i].state == .awaitingConfirmation {
            // Back to the larger target: resume with everything already accumulated.
            let t = now
            state.occurrences[i].state = .active
            state.occurrences[i].session?.runningSince = t
        }
    }

    mutating func reportDone(_ id: UUID, _ mode: SessionMode) throws {
        let i = try index(of: id)
        try requireOpen(i, "reportDone", allowed: [.due, .active, .awaitingConfirmation])
        finish(i, as: mode == .full ? .completedFull : .completedMinimum, outcome: mode == .full ? .full : .minimum, release: .completed)
        emit(.outcomeRecorded, id, ["kind": mode.rawValue])
    }


    mutating func reportReviewed(_ id: UUID, _ report: ReviewedReport) throws {
        let i = try index(of: id)
        try requireOpen(i, "reportReviewed", allowed: [.due, .active, .awaitingConfirmation])
        let mode = report.mode
        finish(i, as: mode == .full ? .completedFull : .completedMinimum, outcome: mode == .full ? .full : .minimum, release: .completed)
        state.occurrences[i].outcome?.evidence = .aiReviewed
        state.occurrences[i].outcome?.note = CoachOutputValidator.sanitize(report.reason)
        emit(.outcomeRecorded, id, ["kind": mode.rawValue, "evidence": "aiReviewed",
                                    "photo": report.usedPhoto ? "1" : "0", "text": report.usedText ? "1" : "0"])
    }

    mutating func reschedule(_ id: UUID, _ minutes: Int) throws {
        guard minutes > 0 else { throw EngineError.invalidArgument("minutes must be positive") }
        let i = try index(of: id)
        try requireOpen(i, "reschedule", allowed: [.scheduled, .due, .active, .awaitingConfirmation])
        let old = state.occurrences[i]
        finish(i, as: .rescheduled, outcome: .rescheduled, release: .rescheduled)
        let start = now.addingTimeInterval(Double(minutes) * 60)
        let next = Occurrence(id: UUID(), opportunityId: old.opportunityId, rescheduledFromOccurrenceId: old.id, continuesOccurrenceId: nil,
                              kind: old.kind, commitmentId: old.commitmentId, commitmentRevision: old.commitmentRevision,
                              localDate: localKey(start, old.commitmentId), scheduledStart: start, state: .scheduled,
                              consentVersion: state.consentVersion, session: nil, lease: nil, outcome: nil)
        state.occurrences.append(next)
        effects.append(.scheduleTrigger(occurrenceId: next.id, at: start))
        emit(.rescheduled, id, ["to": next.id.uuidString, "minutes": String(minutes)])
    }

    mutating func rest(_ id: UUID) throws {
        let i = try index(of: id)
        try requireOpen(i, "restForDay", allowed: [.scheduled, .due, .active, .awaitingConfirmation])
        finish(i, as: .pausedForDay, outcome: .rested, release: .rested)
        emit(.restedForDay, id)
    }

    mutating func endUnfinished(_ id: UUID) throws {
        let i = try index(of: id)
        try requireOpen(i, "endUnfinished", allowed: [.scheduled, .due, .active, .awaitingConfirmation])
        finish(i, as: .overriddenUnfinished, outcome: .unfinished, release: .overridden)
        emit(.overridden, id)
    }

    mutating func startFresh(_ fromId: UUID, _ minutes: Int) throws {
        guard minutes > 0 else { throw EngineError.invalidArgument("minutes must be positive") }
        let from = try index(of: fromId)
        guard state.occurrences[from].state.isTerminal else {
            throw EngineError.invalidTransition(from: state.occurrences[from].state, command: "startFresh")
        }
        let prior = state.occurrences[from]
        let occ = Occurrence(id: UUID(), opportunityId: UUID(), rescheduledFromOccurrenceId: nil, continuesOccurrenceId: prior.id,
                             kind: .extra, commitmentId: prior.commitmentId, commitmentRevision: prior.commitmentRevision,
                             localDate: localKey(now, prior.commitmentId), scheduledStart: now, state: .active, consentVersion: state.consentVersion,
                             session: Session(id: UUID(), mode: .full, fullSeconds: minutes * 60, minimumSeconds: minutes * 60,
                                              startedAt: now, closedActiveSeconds: 0, runningSince: now),
                             lease: nil, outcome: nil)
        state.occurrences.append(occ)
        emit(.freshStartCreated, occ.id, ["from": fromId.uuidString, "minutes": String(minutes)])
    }

    mutating func setPermission(_ on: Bool) {
        guard state.permissions.restrictionsAuthorized != on else { return }
        state.permissions.restrictionsAuthorized = on
        emit(.permissionChanged, nil, ["restrictionsAuthorized": String(on)])
        if !on { for i in state.occurrences.indices { releaseLease(i, .permissionRevoked) } }
    }

    mutating func upsert(_ incoming: Commitment) throws {
        guard incoming.fullMinutes > 0, incoming.minimumMinutes > 0, incoming.minimumMinutes < incoming.fullMinutes else {
            throw EngineError.invalidArgument("the minimum must be shorter than the full version")
        }
        guard !incoming.title.trimmingCharacters(in: .whitespaces).isEmpty else { throw EngineError.invalidArgument("title is required") }
        var c = incoming
        if let idx = state.commitments.firstIndex(where: { $0.id == c.id }) {
            c.revision = state.commitments[idx].revision + 1
            state.commitments[idx] = c
        } else {
            state.commitments.append(c)
        }
        // A scheduled occurrence that never started is simply rebuilt from the new plan.
        state.occurrences.removeAll { $0.commitmentId == c.id && $0.state == .scheduled }
        // Switched off while the coach was already due (no session yet): drop it and release any pause, so no shield outlives the promise.
        if !c.isEnabled {
            for i in state.occurrences.indices where state.occurrences[i].commitmentId == c.id && state.occurrences[i].state == .due && state.occurrences[i].session == nil {
                releaseLease(i, .rested)
                effects.append(.cancelTrigger(occurrenceId: state.occurrences[i].id))
            }
            state.occurrences.removeAll { $0.commitmentId == c.id && $0.state == .due && $0.session == nil }
        }
        emit(.commitmentChanged, nil, ["id": c.id.uuidString, "revision": String(c.revision)])
        materialize()
    }

    mutating func remove(_ id: UUID) {
        state.commitments.removeAll { $0.id == id }
        for i in state.occurrences.indices where state.occurrences[i].commitmentId == id && !state.occurrences[i].state.isTerminal {
            finish(i, as: .overriddenUnfinished, outcome: .unfinished, release: .overridden)
        }
    }

    // MARK: scheduling

    func localCalendar(_ commitmentId: UUID) -> Calendar {
        var cal = calendar
        if let id = state.commitment(commitmentId)?.timeZoneIdentifier, let tz = TimeZone(identifier: id) { cal.timeZone = tz }
        return cal
    }

    func localKey(_ date: Date, _ commitmentId: UUID) -> String {
        let cal = localCalendar(commitmentId)
        let c = cal.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    mutating func materialize() {
        for c in state.commitments where c.isEnabled {
            if state.occurrences.contains(where: { $0.commitmentId == c.id && !$0.state.isTerminal }) { continue }
            let cal = localCalendar(c.id)
            let todayKey = localKey(now, c.id)
            // Already handled today (completed, rested, missed…): wait for tomorrow.
            if state.occurrences.contains(where: { $0.commitmentId == c.id && $0.kind == .scheduled && $0.localDate == todayKey }) { continue }
            let today = cal.startOfDay(for: now)
            guard let startToday = cal.date(bySettingHour: c.startHour, minute: c.startMinute, second: 0, of: today) else { continue }
            var start = startToday
            if now >= startToday.addingTimeInterval(Double(c.restrictionWindowMinutes) * 60) {
                start = cal.date(byAdding: .day, value: 1, to: startToday) ?? startToday.addingTimeInterval(86_400)
            }
            let occ = Occurrence(id: UUID(), opportunityId: UUID(), rescheduledFromOccurrenceId: nil, continuesOccurrenceId: nil, kind: .scheduled,
                                 commitmentId: c.id, commitmentRevision: c.revision, localDate: localKey(start, c.id), scheduledStart: start,
                                 state: .scheduled, consentVersion: state.consentVersion, session: nil, lease: nil, outcome: nil)
            state.occurrences.append(occ)
            effects.append(.scheduleTrigger(occurrenceId: occ.id, at: start))
            emit(.occurrenceScheduled, occ.id, ["start": String(start.timeIntervalSince1970)])
        }
    }
}

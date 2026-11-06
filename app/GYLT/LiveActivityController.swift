import ActivityKit
import Foundation
import GYLTCore

/// Keeps one Live Activity in step with the session that is running. It shows only what the engine already knows;
/// it never decides anything. No session in progress means no Live Activity.
@MainActor
final class LiveActivityController {
    private var activity: Activity<SessionActivityAttributes>?

    func sync(state: AppState, now: Date = .now) {
        guard let (occ, title) = Self.current(in: state) else { end(); return }
        let content = Self.content(for: occ, now: now)
        if let a = activity ?? Activity<SessionActivityAttributes>.activities.first(where: { $0.attributes.occurrenceId == occ.id }) {
            activity = a
            if !Self.same(a.content.state, content) {
                Task { await a.update(ActivityContent(state: content, staleDate: nil)) }
            }
            return
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        // Anything left over from another session is gone before a new one starts.
        for stale in Activity<SessionActivityAttributes>.activities where stale.attributes.occurrenceId != occ.id {
            Task { await stale.end(nil, dismissalPolicy: .immediate) }
        }
        activity = try? Activity.request(attributes: SessionActivityAttributes(occurrenceId: occ.id, commitmentId: occ.commitmentId, title: title),
                                         content: ActivityContent(state: content, staleDate: nil))
    }

    func end() {
        activity = nil
        for a in Activity<SessionActivityAttributes>.activities { Task { await a.end(nil, dismissalPolicy: .immediate) } }
    }

    // MARK: pure parts

    static func current(in state: AppState) -> (Occurrence, String)? {
        guard let occ = state.occurrences.first(where: { ($0.state == .active || $0.state == .awaitingConfirmation) && $0.session != nil }),
              let c = state.commitment(occ.commitmentId) else { return nil }
        return (occ, c.title)
    }

    static func content(for occ: Occurrence, now: Date) -> SessionActivityAttributes.ContentState {
        guard let s = occ.session else { return .init(phase: .finished, endsAt: now, target: 1, remaining: 0) }
        let remaining = s.remainingSeconds(at: now)
        let target = Double(s.targetSeconds)
        if occ.state == .awaitingConfirmation || remaining <= 0 { return .init(phase: .finished, endsAt: now, target: target, remaining: 0) }
        if let since = s.runningSince {
            // Anchored to when the running segment began, so it is the same value on every call.
            let ends = since.addingTimeInterval(target - s.closedActiveSeconds)
            return .init(phase: .running, endsAt: ends, target: target, remaining: remaining)
        }
        return .init(phase: .paused, endsAt: now, target: target, remaining: remaining)
    }

    /// Paused and finished states carry a changing `endsAt` that means nothing; only the meaningful fields decide.
    static func same(_ a: SessionActivityAttributes.ContentState, _ b: SessionActivityAttributes.ContentState) -> Bool {
        guard a.phase == b.phase, a.target == b.target else { return false }
        switch a.phase {
        case .running: return abs(a.endsAt.timeIntervalSince(b.endsAt)) < 1
        case .paused: return abs(a.remaining - b.remaining) < 1
        case .finished: return true
        }
    }
}

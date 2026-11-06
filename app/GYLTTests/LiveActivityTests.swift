import XCTest
@testable import GYLT
import GYLTCore

final class LiveActivityTests: XCTestCase {
    /// A model with the walk started. The occurrence is whatever the engine made for today.
    @MainActor private func started() -> (AppModel, UUID) {
        let model = AppModel(store: InMemoryStateStore())
        let id = model.current(for: Commitment.walkID)!.id
        model.begin(id)
        return (model, id)
    }

    @MainActor func testNoSessionMeansNoLiveActivity() {
        let model = AppModel(store: InMemoryStateStore())
        XCTAssertNil(LiveActivityController.current(in: model.state))
    }

    @MainActor func testRunningSessionCountsDownToItsAnchoredEnd() {
        let (model, id) = started()
        guard let (occ, title) = LiveActivityController.current(in: model.state) else { return XCTFail("a started session shows a Live Activity") }
        XCTAssertEqual(occ.id, id)
        XCTAssertFalse(title.isEmpty)
        let a = LiveActivityController.content(for: occ, now: .now)
        let b = LiveActivityController.content(for: occ, now: .now.addingTimeInterval(20))
        XCTAssertEqual(a.phase, .running)
        // The end does not move as the clock does, so the activity is not rewritten every tick.
        XCTAssertEqual(a.endsAt.timeIntervalSince1970, b.endsAt.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertTrue(LiveActivityController.same(a, b))
        XCTAssertGreaterThan(a.endsAt, .now)
    }

    @MainActor func testPausedSessionFreezesWhatIsLeft() {
        let (model, id) = started()
        model.send(.pauseTimer(id))
        let occ = model.state.occurrence(id)!
        let now = Date.now
        let a = LiveActivityController.content(for: occ, now: now)
        let b = LiveActivityController.content(for: occ, now: now.addingTimeInterval(30))
        XCTAssertEqual(a.phase, .paused)
        XCTAssertEqual(a.remaining, b.remaining, accuracy: 0.001)
        XCTAssertTrue(LiveActivityController.same(a, b))
    }

    @MainActor func testTimeUpAsksInsteadOfCounting() {
        let (model, id) = started()
        let occ = model.state.occurrence(id)!
        let late = LiveActivityController.content(for: occ, now: .now.addingTimeInterval(10 * 3600))
        XCTAssertEqual(late.phase, .finished)
    }

    @MainActor func testRunningAndPausedAreNotTheSame() {
        let (model, id) = started()
        let running = LiveActivityController.content(for: model.state.occurrence(id)!, now: .now)
        model.send(.pauseTimer(id))
        let paused = LiveActivityController.content(for: model.state.occurrence(id)!, now: .now)
        XCTAssertFalse(LiveActivityController.same(running, paused))
    }
}

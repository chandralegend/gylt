import XCTest
@testable import GYLT
import GYLTCore

final class SmokeTests: XCTestCase {
    func testEveryIconIsARealSymbol() {
        XCTAssertFalse(Icon.allCases.isEmpty)
        for icon in Icon.allCases { XCTAssertNotNil(UIImage(systemName: icon.symbol), "\(icon) maps to a missing SF Symbol: \(icon.symbol)") }
    }

    func testSavedPromiseIconNamesStillResolve() {
        // Promises saved by older builds stored these names.
        for c in Commitment.defaults() { XCTAssertNotNil(Icon(rawValue: c.iconName), "\(c.title) icon \(c.iconName) no longer resolves") }
    }

    func testEveryIllustrationIsInTheBundle() {
        for art in [Art.walk, .bed, .night, .intervention, .session, .payoff, .welcome, .coach, .custom, .blocked, .milestone] {
            XCTAssertNotNil(UIImage(named: art.rawValue), "\(art.rawValue) is missing from the asset catalog")
        }
    }

    func testStarterPromisesHaveTheirOwnArt() {
        XCTAssertEqual(Art.forPromise(Commitment.walkID), .walk)
        XCTAssertEqual(Art.forPromise(Commitment.bedID), .bed)
        XCTAssertEqual(Art.forPromise(Commitment.nightID), .night)
        XCTAssertEqual(Art.forPromise(UUID()), .custom)
    }

    func testMilestonesOnlyFireOnTheDay() {
        XCTAssertEqual(Milestone.reached(streak: 7), 7)
        XCTAssertNil(Milestone.reached(streak: 8))
        XCTAssertEqual(Milestone.next(after: 7), 14)
        XCTAssertNil(Milestone.next(after: 100))
    }

    @MainActor func testModelSeedsTodaysWalk() {
        let model = AppModel(store: InMemoryStateStore())
        XCTAssertNotNil(model.current(for: Commitment.walkID))
        XCTAssertEqual(model.current(for: Commitment.walkID)?.state, .scheduled)
    }

    // MARK: honesty about pausing apps

    @MainActor func testNoPauseIsClaimedWithoutScreenTime() {
        // The test host has no Screen Time approval and no chosen apps, so a promise that "pauses apps" must not.
        let model = AppModel(store: InMemoryStateStore())
        XCTAssertFalse(model.pauseReady)
        XCTAssertFalse(model.state.permissions.restrictionsAuthorized)
        let occ = model.current(for: Commitment.walkID)!
        model.begin(occ.id)
        XCTAssertEqual(model.state.occurrence(occ.id)?.state, .active)
        XCTAssertNil(model.state.occurrence(occ.id)?.lease, "no lease may exist when nothing can really be paused")
        XCTAssertFalse(model.anyActiveLease)
    }

    @MainActor func testEraseEverythingStartsFresh() {
        let model = AppModel(store: InMemoryStateStore())
        var s = model.settings; s.onboardingCompleted = true; s.tone = .savage; model.update(settings: s)
        model.setPromise(Commitment.bedID, enabled: false)
        model.markMilestoneSeen(7)
        model.eraseEverything()
        XCTAssertFalse(model.settings.onboardingCompleted)
        XCTAssertEqual(model.settings.tone, .direct)
        XCTAssertTrue(model.state.commitment(Commitment.bedID)?.isEnabled ?? false)
        XCTAssertFalse(model.milestoneSeen(7))
        XCTAssertNotNil(model.current(for: Commitment.walkID), "a fresh install has today's promise ready")
    }
}


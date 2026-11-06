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
}

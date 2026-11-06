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

    @MainActor func testModelSeedsTodaysWalk() {
        let model = AppModel(store: InMemoryStateStore())
        XCTAssertNotNil(model.current(for: Commitment.walkID))
        XCTAssertEqual(model.current(for: Commitment.walkID)?.state, .scheduled)
    }
}

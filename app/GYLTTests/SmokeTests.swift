import XCTest
@testable import GYLT
import GYLTCore

final class SmokeTests: XCTestCase {
    func testPixelDataIsConsistent() {
        XCTAssertEqual(PixelData.coach.width, 24)
        XCTAssertEqual(PixelData.coach.height, 29)
        for row in PixelData.coach.rows { XCTAssertEqual(row.count, 24) }
        XCTAssertEqual(PixelData.wordmark.width, 36)
        XCTAssertFalse(PxIcon.allCases.isEmpty)
        for icon in PxIcon.allCases { XCTAssertFalse(icon.polygons.isEmpty, "\(icon) has no polygons") }
    }

    @MainActor func testModelSeedsTodaysWalk() {
        let model = AppModel(store: InMemoryStateStore())
        XCTAssertNotNil(model.current(for: Commitment.walkID))
        XCTAssertEqual(model.current(for: Commitment.walkID)?.state, .scheduled)
    }
}

import ActivityKit
import Foundation

/// The running session, as the Lock Screen and Dynamic Island show it.
/// Shared by the app (which starts, updates and ends it) and the widget extension (which draws it).
struct SessionActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        enum Phase: String, Codable, Hashable { case running, paused, finished }
        var phase: Phase
        /// When the timer reaches zero while running; meaningless while paused.
        var endsAt: Date
        /// The full length of this session, in seconds.
        var target: Double
        /// Seconds left while paused.
        var remaining: Double

        /// The window the timer's progress bar fills across.
        var window: ClosedRange<Date> { endsAt.addingTimeInterval(-max(1, target))...endsAt }
        /// 0...1 while paused or finished.
        var fraction: Double { target > 0 ? min(1, max(0, 1 - remaining / target)) : 1 }
    }

    var occurrenceId: UUID
    /// Picks the promise's illustration.
    var commitmentId: UUID
    var title: String
}

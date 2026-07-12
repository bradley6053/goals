import Foundation
import ActivityKit

/// Live Activity payload for a running timer. Static identity lives in the
/// attributes; only what changes (end date, pause) travels in ContentState.
/// Compiled into app + widget so both sides agree on the shape.
struct TimerActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var endDate: Date
        /// Non-nil means paused, holding the frozen remaining time.
        var pausedRemaining: TimeInterval?
    }

    var timerID: UUID
    var label: String
    var emoji: String
    var accentName: String
    var totalSeconds: TimeInterval
}

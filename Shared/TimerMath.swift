import Foundation
import CoreGraphics

/// Pure math for the winding timer dial and countdown display. One full
/// revolution winds an hour, exactly like a minute hand — 6° per minute.
/// Views hold no math: the drag gesture feeds points through `angle`,
/// `angleDelta`, and `accumulate`, which makes the tricky unwrap behavior
/// (crossing 12 o'clock, multi-revolution winds) unit-testable.
enum TimerMath {
    static let secondsPerRevolution: TimeInterval = 3600
    static let snapSeconds: TimeInterval = 60
    /// 4 revolutions. Keeps a wound timer far under the system's ~8 h
    /// Live Activity limit.
    static let maxDuration: TimeInterval = 4 * 3600

    static var maxAngle: Double { maxDuration / secondsPerRevolution * 2 * .pi }

    // MARK: - Winding geometry

    /// Angle of a touch point around the dial center, in radians:
    /// 0 at 12 o'clock, clockwise positive, range (-π, π].
    static func angle(of p: CGPoint, around c: CGPoint) -> Double {
        atan2(p.x - c.x, c.y - p.y)
    }

    /// Signed shortest-path delta between two raw angles, in (-π, π].
    /// Crossing 12 o'clock (π → -π) yields a small delta, never ±2π.
    static func angleDelta(from old: Double, to new: Double) -> Double {
        var d = new - old
        if d > .pi { d -= 2 * .pi }
        if d <= -.pi { d += 2 * .pi }
        return d
    }

    /// Fold a drag delta into the cumulative wound angle, clamped so the
    /// dial can't unwind below zero or past the 4-hour cap.
    static func accumulate(_ total: Double, adding delta: Double) -> Double {
        min(max(total + delta, 0), maxAngle)
    }

    /// Wound duration for a cumulative angle, snapped to whole minutes.
    static func duration(forTotalAngle angle: Double) -> TimeInterval {
        let raw = angle / (2 * .pi) * secondsPerRevolution
        return min(maxDuration, max(0, (raw / snapSeconds).rounded() * snapSeconds))
    }

    static func totalAngle(for duration: TimeInterval) -> Double {
        duration / secondsPerRevolution * 2 * .pi
    }

    // MARK: - Countdown

    static func fractionRemaining(endDate: Date, total: TimeInterval, now: Date) -> Double {
        guard total > 0 else { return 0 }
        return min(1, max(0, endDate.timeIntervalSince(now) / total))
    }

    /// Compact ticking readout: "0:42", "12:05", "1:05:00".
    static func remainingText(_ seconds: TimeInterval) -> String {
        let s = Int(max(0, seconds).rounded())
        let hours = s / 3600
        let minutes = (s % 3600) / 60
        let secs = s % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }

    /// Friendly wind label: "25 min", "1 hr", "1 hr 10 min".
    static func windLabel(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int((max(0, seconds) / 60).rounded())
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        switch (hours, minutes) {
        case (0, _): return "\(minutes) min"
        case (_, 0): return "\(hours) hr"
        default: return "\(hours) hr \(minutes) min"
        }
    }

    // MARK: - Clock-anchored presets

    /// Next occurrence of a wall-clock time after `now` — today if it hasn't
    /// passed yet, otherwise tomorrow. Calendar math only, so DST-safe.
    static func nextOccurrence(hour: Int, minute: Int, after now: Date,
                               calendar: Calendar = .current) -> Date {
        calendar.nextDate(after: now,
                          matching: DateComponents(hour: hour, minute: minute),
                          matchingPolicy: .nextTime) ?? now
    }
}

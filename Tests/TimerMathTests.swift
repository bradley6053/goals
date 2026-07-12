import XCTest
@testable import Ember

final class TimerMathTests: XCTestCase {

    // Fixed calendar so clock-anchor tests are deterministic regardless of
    // when or where they run.
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Chicago")!
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int,
                      _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(
            year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    // MARK: - angle(of:around:)

    private let center = CGPoint(x: 100, y: 100)

    func testAngleAtTwelveOClockIsZero() {
        XCTAssertEqual(TimerMath.angle(of: CGPoint(x: 100, y: 0), around: center),
                       0, accuracy: 1e-9)
    }

    func testAngleAtThreeOClockIsQuarterTurn() {
        XCTAssertEqual(TimerMath.angle(of: CGPoint(x: 200, y: 100), around: center),
                       .pi / 2, accuracy: 1e-9)
    }

    func testAngleAtSixOClockIsHalfTurn() {
        XCTAssertEqual(TimerMath.angle(of: CGPoint(x: 100, y: 200), around: center),
                       .pi, accuracy: 1e-9)
    }

    func testAngleAtNineOClockIsNegativeQuarterTurn() {
        XCTAssertEqual(TimerMath.angle(of: CGPoint(x: 0, y: 100), around: center),
                       -.pi / 2, accuracy: 1e-9)
    }

    // MARK: - angleDelta (the unwrap)

    func testDeltaSimpleClockwise() {
        XCTAssertEqual(TimerMath.angleDelta(from: 0.2, to: 0.5), 0.3, accuracy: 1e-9)
    }

    func testDeltaCrossingTwelveClockwiseStaysSmall() {
        // 3.1 rad → -3.1 rad crosses 6 o'clock… the wrap seam. Crossing the
        // atan2 seam clockwise must be a small positive step, never -2π.
        let delta = TimerMath.angleDelta(from: 3.1, to: -3.1)
        XCTAssertEqual(delta, 2 * .pi - 6.2, accuracy: 1e-9)
        XCTAssertGreaterThan(delta, 0)
    }

    func testDeltaCrossingTwelveCounterClockwiseStaysSmall() {
        let delta = TimerMath.angleDelta(from: -3.1, to: 3.1)
        XCTAssertEqual(delta, -(2 * .pi - 6.2), accuracy: 1e-9)
        XCTAssertLessThan(delta, 0)
    }

    // MARK: - accumulate

    func testAccumulateAcrossTwoAndAHalfRevolutions() {
        var total = 0.0
        // 100 small clockwise steps of 0.05π = 2.5 revolutions.
        for _ in 0..<100 {
            total = TimerMath.accumulate(total, adding: 0.05 * .pi)
        }
        XCTAssertEqual(total, 5 * .pi, accuracy: 1e-9)
        XCTAssertEqual(TimerMath.duration(forTotalAngle: total),
                       2.5 * 3600, accuracy: 1e-6)
    }

    func testAccumulateClampsAtZero() {
        XCTAssertEqual(TimerMath.accumulate(0.1, adding: -1.0), 0)
    }

    func testAccumulateClampsAtMax() {
        XCTAssertEqual(TimerMath.accumulate(TimerMath.maxAngle - 0.1, adding: 1.0),
                       TimerMath.maxAngle)
    }

    // MARK: - duration snapping & round trip

    func testDurationSnapsToWholeMinutes() {
        // 37.4 minutes of angle snaps to 37 minutes.
        let angle = 37.4 * 60 / TimerMath.secondsPerRevolution * 2 * .pi
        XCTAssertEqual(TimerMath.duration(forTotalAngle: angle), 37 * 60)
    }

    func testDurationAngleRoundTrip() {
        let duration: TimeInterval = 95 * 60  // 1 hr 35 min
        let angle = TimerMath.totalAngle(for: duration)
        XCTAssertEqual(TimerMath.duration(forTotalAngle: angle), duration)
    }

    func testFullRevolutionIsOneHour() {
        XCTAssertEqual(TimerMath.duration(forTotalAngle: 2 * .pi), 3600)
    }

    // MARK: - fractionRemaining

    func testFractionRemainingMidway() {
        let end = date(2026, 7, 4, 12)
        let now = date(2026, 7, 4, 11, 30)
        XCTAssertEqual(
            TimerMath.fractionRemaining(endDate: end, total: 3600, now: now),
            0.5, accuracy: 1e-9)
    }

    func testFractionRemainingClampsPastEnd() {
        let end = date(2026, 7, 4, 12)
        let now = date(2026, 7, 4, 13)
        XCTAssertEqual(
            TimerMath.fractionRemaining(endDate: end, total: 3600, now: now), 0)
    }

    func testFractionRemainingClampsBeforeStart() {
        let end = date(2026, 7, 4, 12)
        let now = date(2026, 7, 4, 10)
        XCTAssertEqual(
            TimerMath.fractionRemaining(endDate: end, total: 3600, now: now), 1)
    }

    // MARK: - formatting

    func testRemainingTextSecondsOnly() {
        XCTAssertEqual(TimerMath.remainingText(42), "0:42")
    }

    func testRemainingTextMinutes() {
        XCTAssertEqual(TimerMath.remainingText(12 * 60 + 5), "12:05")
    }

    func testRemainingTextHours() {
        XCTAssertEqual(TimerMath.remainingText(65 * 60), "1:05:00")
    }

    func testWindLabelFormats() {
        XCTAssertEqual(TimerMath.windLabel(25 * 60), "25 min")
        XCTAssertEqual(TimerMath.windLabel(3600), "1 hr")
        XCTAssertEqual(TimerMath.windLabel(70 * 60), "1 hr 10 min")
    }

    // MARK: - nextOccurrence (clock-anchored presets)

    func testNextOccurrenceLaterToday() {
        // 3 PM asking for 8 PM → tonight.
        let now = date(2026, 7, 4, 15)
        XCTAssertEqual(
            TimerMath.nextOccurrence(hour: 20, minute: 0, after: now, calendar: calendar),
            date(2026, 7, 4, 20))
    }

    func testNextOccurrenceRollsToTomorrow() {
        // 9 PM asking for 8 PM → tomorrow night.
        let now = date(2026, 7, 4, 21)
        XCTAssertEqual(
            TimerMath.nextOccurrence(hour: 20, minute: 0, after: now, calendar: calendar),
            date(2026, 7, 5, 20))
    }
}

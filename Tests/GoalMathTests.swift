import XCTest
@testable import Ember

final class GoalMathTests: XCTestCase {

    // Lose 20 lbs: 220 → 200
    func testDecreasingGoalFraction() {
        XCTAssertEqual(GoalMath.fraction(start: 220, target: 200, current: 220), 0)
        XCTAssertEqual(GoalMath.fraction(start: 220, target: 200, current: 210), 0.5)
        XCTAssertEqual(GoalMath.fraction(start: 220, target: 200, current: 200), 1)
        // Overshoot clamps
        XCTAssertEqual(GoalMath.fraction(start: 220, target: 200, current: 195), 1)
        XCTAssertEqual(GoalMath.fraction(start: 220, target: 200, current: 225), 0)
    }

    // Save $5,000: 0 → 5000
    func testIncreasingGoalFraction() {
        XCTAssertEqual(GoalMath.fraction(start: 0, target: 5000, current: 0), 0)
        XCTAssertEqual(GoalMath.fraction(start: 0, target: 5000, current: 2500), 0.5)
        XCTAssertEqual(GoalMath.fraction(start: 0, target: 5000, current: 6000), 1)
    }

    func testDirection() {
        XCTAssertEqual(GoalMath.direction(start: 220, target: 200), .decreasing)
        XCTAssertEqual(GoalMath.direction(start: 0, target: 5000), .increasing)
    }

    func testMilestoneReachedDecreasing() {
        // Milestone at 210 (i.e. -10 lbs)
        XCTAssertFalse(GoalMath.reached(value: 210, start: 220, target: 200, current: 212))
        XCTAssertTrue(GoalMath.reached(value: 210, start: 220, target: 200, current: 210))
        XCTAssertTrue(GoalMath.reached(value: 210, start: 220, target: 200, current: 208.5))
    }

    func testMilestoneReachedIncreasing() {
        XCTAssertFalse(GoalMath.reached(value: 3000, start: 0, target: 5000, current: 2999))
        XCTAssertTrue(GoalMath.reached(value: 3000, start: 0, target: 5000, current: 3000))
        XCTAssertTrue(GoalMath.reached(value: 3000, start: 0, target: 5000, current: 4200))
    }

    func testRemaining() {
        XCTAssertEqual(GoalMath.remaining(to: 210, current: 213, start: 220, target: 200), 3)
        XCTAssertEqual(GoalMath.remaining(to: 210, current: 208, start: 220, target: 200), 0)
        XCTAssertEqual(GoalMath.remaining(to: 3000, current: 1800, start: 0, target: 5000), 1200)
    }

    func testDegenerateGoalDoesNotDivideByZero() {
        XCTAssertEqual(GoalMath.fraction(start: 100, target: 100, current: 100), 1)
    }

    // MARK: - Formatting

    func testNumberTrimsTrailingZeros() {
        XCTAssertEqual(GoalFormat.number(12), "12")
        XCTAssertEqual(GoalFormat.number(12.5), "12.5")
        XCTAssertEqual(GoalFormat.number(12.0), "12")
    }

    func testValueFormatting() {
        XCTAssertEqual(GoalFormat.value(12.5, unit: "lbs"), "12.5 lbs")
        XCTAssertEqual(GoalFormat.value(5000, unit: "$"), "$5,000")
        XCTAssertEqual(GoalFormat.value(7, unit: ""), "7")
    }

    func testSignedDelta() {
        XCTAssertEqual(GoalFormat.signedDelta(-12, unit: "lbs"), "−12 lbs")
        XCTAssertEqual(GoalFormat.signedDelta(1200, unit: "$"), "+$1,200")
        XCTAssertEqual(GoalFormat.signedDelta(0, unit: "lbs"), "0 lbs")
    }

    func testMilestoneLabels() {
        // Weight loss milestones read as deltas
        XCTAssertEqual(
            GoalFormat.milestoneLabel(value: 210, start: 220, target: 200, unit: "lbs"),
            "−10 lbs")
        // Savings milestones read as absolute values
        XCTAssertEqual(
            GoalFormat.milestoneLabel(value: 3000, start: 0, target: 5000, unit: "$"),
            "$3,000")
    }
}

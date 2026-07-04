import XCTest
@testable import Ember

final class StreakMathTests: XCTestCase {

    // Fixed calendar + "today" so tests are deterministic regardless of when
    // or where they run.
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Chicago")!
        return calendar
    }()

    /// Noon on 2026-06-15 (a Monday) — mid-day so start-of-day math is exercised.
    private var today: Date {
        day(2026, 6, 15, hour: 12)
    }

    private func day(_ year: Int, _ month: Int, _ dayOfMonth: Int, hour: Int = 9) -> Date {
        calendar.date(from: DateComponents(
            year: year, month: month, day: dayOfMonth, hour: hour))!
    }

    /// Dates offset from today by whole days (0 = today, -1 = yesterday…).
    private func daysAgo(_ offset: Int, hour: Int = 9) -> Date {
        let base = calendar.date(byAdding: .day, value: -offset,
                                 to: calendar.startOfDay(for: today))!
        return calendar.date(byAdding: .hour, value: hour, to: base)!
    }

    // MARK: - currentStreak

    func testEmptyDatesZeroStreak() {
        XCTAssertEqual(StreakMath.currentStreak(dates: [], calendar: calendar, today: today), 0)
    }

    func testSingleLogTodayIsOne() {
        XCTAssertEqual(
            StreakMath.currentStreak(dates: [daysAgo(0)], calendar: calendar, today: today), 1)
    }

    func testLogYesterdayOnlyStreakStillAlive() {
        // Not yet logged today — the streak survives until midnight passes.
        XCTAssertEqual(
            StreakMath.currentStreak(dates: [daysAgo(1)], calendar: calendar, today: today), 1)
    }

    func testLastLogTwoDaysAgoIsLapsed() {
        XCTAssertEqual(
            StreakMath.currentStreak(dates: [daysAgo(2)], calendar: calendar, today: today), 0)
    }

    func testConsecutiveRunEndingToday() {
        let dates = [daysAgo(3), daysAgo(2), daysAgo(1), daysAgo(0)]
        XCTAssertEqual(
            StreakMath.currentStreak(dates: dates, calendar: calendar, today: today), 4)
    }

    func testGapBreaksRun() {
        // day -4, day -3, (gap at -2), day -1, day 0 → current run is 2.
        let dates = [daysAgo(4), daysAgo(3), daysAgo(1), daysAgo(0)]
        XCTAssertEqual(
            StreakMath.currentStreak(dates: dates, calendar: calendar, today: today), 2)
    }

    func testMultipleLogsSameDayDeduplicate() {
        let dates = [daysAgo(0, hour: 8), daysAgo(0, hour: 12), daysAgo(0, hour: 20)]
        XCTAssertEqual(
            StreakMath.currentStreak(dates: dates, calendar: calendar, today: today), 1)
    }

    func testFutureDatesIgnored() {
        let dates = [daysAgo(-1)] // tomorrow (clock weirdness)
        XCTAssertEqual(
            StreakMath.currentStreak(dates: dates, calendar: calendar, today: today), 0)
    }

    // MARK: - bestStreak

    func testBestStreakAcrossGaps() {
        // 8-day run ending 12 days ago, then a 5-day run ending yesterday.
        let oldRun = (12...19).map { daysAgo($0) }
        let recentRun = (1...5).map { daysAgo($0) }
        let dates = oldRun + recentRun
        XCTAssertEqual(StreakMath.bestStreak(dates: dates, calendar: calendar, today: today), 8)
        XCTAssertEqual(StreakMath.currentStreak(dates: dates, calendar: calendar, today: today), 5)
    }

    func testBestStreakEmptyIsZero() {
        XCTAssertEqual(StreakMath.bestStreak(dates: [], calendar: calendar, today: today), 0)
    }

    // MARK: - recentDays

    func testRecentDaysDots() {
        // Logged yesterday and 3 days ago; 7 bools oldest-first, today last.
        let dates = [daysAgo(1), daysAgo(3)]
        let dots = StreakMath.recentDays(dates: dates, count: 7,
                                         calendar: calendar, today: today)
        XCTAssertEqual(dots, [false, false, false, true, false, true, false])
    }

    // MARK: - displayedStreak (widget midnight lapse)

    func testDisplayedStreakLapsesAfterMidnight() {
        let lastCheckIn = calendar.startOfDay(for: daysAgo(1))
        // Viewed today: last check-in was yesterday → still alive.
        XCTAssertEqual(
            StreakMath.displayedStreak(storedStreak: 5, lastCheckInDay: lastCheckIn,
                                       asOf: today, calendar: calendar), 5)
        // Viewed tomorrow (past midnight, no new check-in) → lapsed.
        let tomorrow = daysAgo(-1)
        XCTAssertEqual(
            StreakMath.displayedStreak(storedStreak: 5, lastCheckInDay: lastCheckIn,
                                       asOf: tomorrow, calendar: calendar), 0)
        XCTAssertEqual(
            StreakMath.displayedStreak(storedStreak: 5, lastCheckInDay: nil,
                                       asOf: today, calendar: calendar), 0)
    }

    // MARK: - Formatting

    func testStreakAndCountHeadlines() {
        XCTAssertEqual(GoalFormat.streakHeadline(12), "🔥 12 days")
        XCTAssertEqual(GoalFormat.streakHeadline(1), "🔥 1 day")
        XCTAssertEqual(GoalFormat.streakHeadline(0), "🔥 0 days")
        XCTAssertEqual(GoalFormat.countHeadline(current: 42, target: 100), "42 / 100")
    }
}

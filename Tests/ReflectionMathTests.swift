import XCTest
@testable import Ember

final class ReflectionMathTests: XCTestCase {

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

    private var libraryCount: Int { ReflectionQuotes.all.count }

    // MARK: - quoteIndex determinism

    func testSameDayAnyHourSameIndex() {
        let early = day(2026, 6, 15, hour: 0)
        let late = calendar.date(
            bySettingHour: 23, minute: 55, second: 0, of: today)!
        XCTAssertEqual(
            ReflectionMath.quoteIndex(on: early, count: libraryCount, calendar: calendar),
            ReflectionMath.quoteIndex(on: late, count: libraryCount, calendar: calendar))
    }

    func testConsecutiveDaysAdvanceByOne() {
        let index = ReflectionMath.quoteIndex(on: today, count: libraryCount,
                                              calendar: calendar)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        XCTAssertEqual(
            ReflectionMath.quoteIndex(on: tomorrow, count: libraryCount, calendar: calendar),
            (index + 1) % libraryCount)
    }

    func testWrapsAroundLibrary() {
        let cycleAway = calendar.date(byAdding: .day, value: libraryCount, to: today)!
        XCTAssertEqual(
            ReflectionMath.quoteIndex(on: today, count: libraryCount, calendar: calendar),
            ReflectionMath.quoteIndex(on: cycleAway, count: libraryCount, calendar: calendar))
        let dayBeforeWrap = calendar.date(byAdding: .day, value: libraryCount - 1, to: today)!
        XCTAssertNotEqual(
            ReflectionMath.quoteIndex(on: today, count: libraryCount, calendar: calendar),
            ReflectionMath.quoteIndex(on: dayBeforeWrap, count: libraryCount,
                                      calendar: calendar))
    }

    func testStableAcrossTimeZones() {
        // The same civil date (2026-06-15) built in Chicago and Tokyo picks
        // the same quote, even though the underlying instants differ.
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let tokyoDate = tokyo.date(from: DateComponents(
            year: 2026, month: 6, day: 15, hour: 12))!
        XCTAssertEqual(
            ReflectionMath.quoteIndex(on: today, count: libraryCount, calendar: calendar),
            ReflectionMath.quoteIndex(on: tokyoDate, count: libraryCount, calendar: tokyo))
    }

    func testDatesBeforeReferenceStayInRange() {
        // Clock set years before the 2025-01-01 reference → still a valid index.
        let past = day(2020, 3, 14)
        let index = ReflectionMath.quoteIndex(on: past, count: libraryCount,
                                              calendar: calendar)
        XCTAssertTrue((0..<libraryCount).contains(index))
    }

    func testQuoteConvenienceMatchesIndex() {
        let index = ReflectionMath.quoteIndex(on: today, count: libraryCount,
                                              calendar: calendar)
        XCTAssertEqual(ReflectionMath.quote(on: today, calendar: calendar),
                       ReflectionQuotes.all[index])
    }

    // MARK: - Library invariants (guard the authored array)

    func testLibraryCountAndBalance() {
        XCTAssertEqual(libraryCount, 210)
        for category in ReflectionCategory.allCases {
            XCTAssertEqual(
                ReflectionQuotes.all.filter { $0.category == category }.count, 35,
                "Category \(category.rawValue) is out of balance")
        }
    }

    func testLibraryIDsUnique() {
        XCTAssertEqual(Set(ReflectionQuotes.all.map(\.id)).count, libraryCount)
    }

    func testLibraryNoEmptyFields() {
        for quote in ReflectionQuotes.all {
            XCTAssertFalse(quote.text.isEmpty, "Empty text: \(quote.id)")
            XCTAssertFalse(quote.attribution.isEmpty, "Empty attribution: \(quote.id)")
        }
    }

    func testLibraryInterleaved() {
        // Authored round-robin so plain modulo day-selection rotates themes:
        // index 0 scripture, 1 saints, 2 fatherhood, 3 marriage, 4 leadership,
        // 5 virtue, 6 scripture, …
        for (index, quote) in ReflectionQuotes.all.enumerated() {
            XCTAssertEqual(
                quote.category,
                ReflectionCategory.allCases[index % ReflectionCategory.allCases.count],
                "Interleave broken at index \(index) (\(quote.id))")
        }
    }
}

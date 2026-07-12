import Foundation

/// Pure quote-of-the-day selection shared by app, widgets, and tests.
/// All day arithmetic goes through Calendar (never 86_400) so DST is safe.
/// The same civil date picks the same quote in any time zone, and the
/// sequence walks the whole library before repeating — no "same quote every
/// Jan 1" anchoring.
enum ReflectionMath {
    /// Civil days since 2025-01-01, built from components inside `calendar`
    /// so the reference midnight lives in the caller's time zone.
    static func dayNumber(for date: Date, calendar: Calendar = .current) -> Int {
        guard let reference = calendar.date(
            from: DateComponents(year: 2025, month: 1, day: 1)) else { return 0 }
        return calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: reference),
            to: calendar.startOfDay(for: date)).day ?? 0
    }

    /// Index into a library of `count` quotes. Double-modulo keeps a clock
    /// set before the reference date (negative day numbers) in range.
    static func quoteIndex(on date: Date, count: Int, calendar: Calendar = .current) -> Int {
        guard count > 0 else { return 0 }
        let day = dayNumber(for: date, calendar: calendar)
        return ((day % count) + count) % count
    }

    /// Today's quote from the full library.
    static func quote(on date: Date, calendar: Calendar = .current) -> ReflectionQuote {
        ReflectionQuotes.all[
            quoteIndex(on: date, count: ReflectionQuotes.all.count, calendar: calendar)]
    }
}

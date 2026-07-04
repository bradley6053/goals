import Foundation

/// Pure streak math shared by app, widgets, and tests.
/// All day arithmetic goes through Calendar (never 86_400) so DST is safe.
/// A "day" is a calendar day in the given calendar's time zone.
enum StreakMath {
    /// Distinct calendar days (as start-of-day dates), ascending.
    /// Days after `today` are ignored so a stray future-dated entry
    /// can't fake a streak.
    static func loggedDays(_ dates: [Date], calendar: Calendar = .current,
                           today: Date = Date()) -> [Date] {
        let cutoff = calendar.startOfDay(for: today)
        return Set(dates.map { calendar.startOfDay(for: $0) })
            .filter { $0 <= cutoff }
            .sorted()
    }

    /// Length of the consecutive-day run ending today OR yesterday.
    /// A run ending yesterday is still alive (it extends if the user logs
    /// today); a run whose last day is two or more days ago returns 0.
    static func currentStreak(dates: [Date], calendar: Calendar = .current,
                              today: Date = Date()) -> Int {
        let days = loggedDays(dates, calendar: calendar, today: today)
        guard let last = days.last else { return 0 }

        let startOfToday = calendar.startOfDay(for: today)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday),
              last == startOfToday || last == yesterday
        else { return 0 }

        var streak = 1
        var runEnd = last
        for day in days.dropLast().reversed() {
            guard calendar.dateComponents([.day], from: day, to: runEnd).day == 1 else { break }
            streak += 1
            runEnd = day
        }
        return streak
    }

    /// Longest consecutive-day run anywhere in history. Empty → 0.
    static func bestStreak(dates: [Date], calendar: Calendar = .current,
                           today: Date = Date()) -> Int {
        let days = loggedDays(dates, calendar: calendar, today: today)
        guard !days.isEmpty else { return 0 }

        var best = 1
        var run = 1
        for (previous, next) in zip(days, days.dropFirst()) {
            if calendar.dateComponents([.day], from: previous, to: next).day == 1 {
                run += 1
                best = max(best, run)
            } else {
                run = 1
            }
        }
        return best
    }

    /// Whether any entry falls on the same calendar day as `day`.
    static func didLog(on day: Date, dates: [Date], calendar: Calendar = .current) -> Bool {
        dates.contains { calendar.isDate($0, inSameDayAs: day) }
    }

    /// The last `count` days as bools (oldest first, ending with today) —
    /// for the last-7-days dots row.
    static func recentDays(dates: [Date], count: Int = 7,
                           calendar: Calendar = .current, today: Date = Date()) -> [Bool] {
        let logged = Set(loggedDays(dates, calendar: calendar, today: today))
        let startOfToday = calendar.startOfDay(for: today)
        return (0..<count).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: startOfToday)
            else { return nil }
            return logged.contains(day)
        }
    }

    /// The streak as it should DISPLAY at `asOf`, given the last check-in day.
    /// Used by the widget's midnight timeline entry: once the last check-in is
    /// before yesterday(asOf), the streak has lapsed and shows 0.
    static func displayedStreak(storedStreak: Int, lastCheckInDay: Date?,
                                asOf: Date, calendar: Calendar = .current) -> Int {
        guard let lastCheckInDay else { return 0 }
        let startOfDay = calendar.startOfDay(for: asOf)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: startOfDay)
        else { return storedStreak }
        return calendar.startOfDay(for: lastCheckInDay) >= yesterday ? storedStreak : 0
    }
}

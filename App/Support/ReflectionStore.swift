import Foundation
import Observation

/// Owns the reflection check-in history. Every mutation writes straight to
/// the app-group JSON file (same discipline as TimerStore). Dates are stored
/// raw; all day logic goes through StreakMath so DST/timezone rules live in
/// one place.
@Observable
final class ReflectionStore {
    private(set) var checkInDates: [Date] = []

    init() {
        load()
    }

    func hasCheckedIn(on date: Date = Date(), calendar: Calendar = .current) -> Bool {
        StreakMath.didLog(on: date, dates: checkInDates, calendar: calendar)
    }

    /// Idempotent — a second same-day call is a no-op.
    func checkIn(on date: Date = Date(), calendar: Calendar = .current) {
        guard !hasCheckedIn(on: date, calendar: calendar) else { return }
        checkInDates.append(date)
        save()
    }

    /// Accidental-tap escape hatch: removes the check-in for `date`'s day.
    func undoCheckIn(on date: Date = Date(), calendar: Calendar = .current) {
        checkInDates.removeAll { calendar.isDate($0, inSameDayAs: date) }
        save()
    }

    func currentStreak(calendar: Calendar = .current, today: Date = Date()) -> Int {
        StreakMath.currentStreak(dates: checkInDates, calendar: calendar, today: today)
    }

    func recentDays(calendar: Calendar = .current, today: Date = Date()) -> [Bool] {
        StreakMath.recentDays(dates: checkInDates, calendar: calendar, today: today)
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var checkInDates: [Date]
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(
            Snapshot(checkInDates: checkInDates)) else { return }
        try? data.write(to: AppGroup.reflectionURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: AppGroup.reflectionURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let snapshot = try? decoder.decode(Snapshot.self, from: data) else { return }
        checkInDates = snapshot.checkInDates
    }
}

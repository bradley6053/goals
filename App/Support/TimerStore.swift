import Foundation
import Observation

/// Owns all active timers. Every mutation writes straight to the app-group
/// JSON file, so a force-killed app loses nothing — remaining time is always
/// derived from the persisted `endDate`, never from ticking. Nothing in this
/// class runs a Timer.
@Observable
final class TimerStore {
    private(set) var timers: [EmberTimer] = []
    private(set) var presetConfigs: [TimerPresetConfig] = []

    init() {
        load()
        sweep(now: Date())
        TimerActivityController.cleanUpOrphans(
            existingTimerIDs: Set(timers.map(\.id)))
    }

    // MARK: - Lifecycle

    @discardableResult
    func start(seconds: TimeInterval, label: String, emoji: String,
               accentName: String, kind: TimerKind = .countdown,
               turnNames: [String]? = nil, turnIndex: Int? = nil,
               doneTitle: String? = nil, doneBody: String? = nil) -> EmberTimer {
        let timer = EmberTimer(
            label: label, emoji: emoji, accentName: accentName,
            totalSeconds: seconds, endDate: Date().addingTimeInterval(seconds),
            kind: kind, turnNames: turnNames, turnIndex: turnIndex,
            doneTitle: doneTitle, doneBody: doneBody)
        timers.append(timer)
        save()
        TimerNotifications.requestAuthorizationIfNeeded()
        TimerNotifications.schedule(for: timer)
        setActivityID(TimerActivityController.start(for: timer), for: timer.id)
        return timers.first { $0.id == timer.id } ?? timer
    }

    func pause(_ id: UUID) {
        guard var timer = timers.first(where: { $0.id == id }),
              !timer.isPaused else { return }
        timer.pausedRemaining = timer.remaining(at: Date())
        replace(timer)
        TimerNotifications.cancel(id)
        TimerActivityController.update(for: timer)
    }

    func resume(_ id: UUID) {
        guard var timer = timers.first(where: { $0.id == id }),
              let remaining = timer.pausedRemaining else { return }
        timer.endDate = Date().addingTimeInterval(remaining)
        timer.pausedRemaining = nil
        replace(timer)
        TimerNotifications.schedule(for: timer)
        TimerActivityController.update(for: timer)
    }

    func cancel(_ id: UUID) {
        let activityID = timers.first { $0.id == id }?.activityID
        timers.removeAll { $0.id == id }
        save()
        TimerNotifications.cancel(id)
        TimerNotifications.clearDelivered([id])
        TimerActivityController.end(activityID: activityID, immediately: true)
    }

    /// Drop finished timers. Called on launch and every foregrounding so
    /// stale timers never linger after the notification already fired.
    func sweep(now: Date) {
        let finished = timers.filter { $0.isFinished(at: now) }
        guard !finished.isEmpty else { return }
        timers.removeAll { timer in finished.contains { $0.id == timer.id } }
        save()
        TimerNotifications.clearDelivered(finished.map(\.id))
        // Fired naturally — let the activity linger at 0:00 briefly.
        for timer in finished {
            TimerActivityController.end(activityID: timer.activityID,
                                        immediately: false)
        }
    }

    /// Turns mode handoff: retire the finished turn and immediately wind up
    /// an identical timer for the next kid in the rotation.
    @discardableResult
    func startNextTurn(after timer: EmberTimer) -> EmberTimer {
        cancel(timer.id)
        let count = max(timer.turnNames?.count ?? 1, 1)
        return start(seconds: timer.totalSeconds, label: timer.label,
                     emoji: timer.emoji, accentName: timer.accentName,
                     kind: .turns, turnNames: timer.turnNames,
                     turnIndex: ((timer.turnIndex ?? 0) + 1) % count,
                     doneTitle: timer.doneTitle)
    }

    func setActivityID(_ activityID: String?, for id: UUID) {
        guard var timer = timers.first(where: { $0.id == id }) else { return }
        timer.activityID = activityID
        replace(timer)
    }

    // MARK: - Preset config

    func config(for preset: TimerPreset) -> TimerPresetConfig? {
        presetConfigs.first { $0.presetID == preset.id }
    }

    /// Effective mode for a preset — user override if saved, else default.
    func mode(for preset: TimerPreset) -> TimerPresetMode {
        config(for: preset)?.mode ?? preset.defaultMode
    }

    func saveConfig(_ config: TimerPresetConfig) {
        presetConfigs.removeAll { $0.presetID == config.presetID }
        presetConfigs.append(config)
        save()
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var timers: [EmberTimer]
        var presetConfigs: [TimerPresetConfig]?
    }

    private func replace(_ timer: EmberTimer) {
        guard let index = timers.firstIndex(where: { $0.id == timer.id }) else { return }
        timers[index] = timer
        save()
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(
            Snapshot(timers: timers, presetConfigs: presetConfigs)) else { return }
        try? data.write(to: AppGroup.timersURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: AppGroup.timersURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let snapshot = try? decoder.decode(Snapshot.self, from: data) else { return }
        timers = snapshot.timers
        presetConfigs = snapshot.presetConfigs ?? []
    }
}

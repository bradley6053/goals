import Foundation

enum TimerKind: String, Codable {
    case countdown
    case turns
}

/// A running (or paused) timer. Not SwiftData — timers are ephemeral, so
/// they live in a small JSON file in the app group. `endDate` is the only
/// source of truth while running; nothing ever ticks or accumulates.
struct EmberTimer: Codable, Identifiable, Equatable {
    let id: UUID
    var label: String
    var emoji: String
    var accentName: String
    var totalSeconds: TimeInterval
    var endDate: Date
    /// Non-nil means paused, holding the frozen remaining time.
    var pausedRemaining: TimeInterval?
    var kind: TimerKind
    /// Live Activity id so a relaunched app can reattach or clean up.
    var activityID: String?
    // Turns mode: whose turn it is, rotating through the names.
    var turnNames: [String]?
    var turnIndex: Int?
    /// Notification copy at zero; nil falls back to generic wording.
    var doneTitle: String?
    var doneBody: String?

    init(id: UUID = UUID(), label: String, emoji: String, accentName: String,
         totalSeconds: TimeInterval, endDate: Date,
         pausedRemaining: TimeInterval? = nil, kind: TimerKind = .countdown,
         activityID: String? = nil, turnNames: [String]? = nil,
         turnIndex: Int? = nil, doneTitle: String? = nil,
         doneBody: String? = nil) {
        self.id = id
        self.label = label
        self.emoji = emoji
        self.accentName = accentName
        self.totalSeconds = totalSeconds
        self.endDate = endDate
        self.pausedRemaining = pausedRemaining
        self.kind = kind
        self.activityID = activityID
        self.turnNames = turnNames
        self.turnIndex = turnIndex
        self.doneTitle = doneTitle
        self.doneBody = doneBody
    }

    var isPaused: Bool { pausedRemaining != nil }

    func remaining(at now: Date) -> TimeInterval {
        pausedRemaining ?? max(0, endDate.timeIntervalSince(now))
    }

    func isFinished(at now: Date) -> Bool {
        pausedRemaining == nil && endDate <= now
    }

    /// Whose turn is running right now (turns mode only).
    var currentTurnName: String? {
        guard let turnNames, !turnNames.isEmpty else { return nil }
        return turnNames[(turnIndex ?? 0) % turnNames.count]
    }

    /// Who's up after this turn ends (turns mode only).
    var nextTurnName: String? {
        guard let turnNames, !turnNames.isEmpty else { return nil }
        return turnNames[((turnIndex ?? 0) + 1) % turnNames.count]
    }
}

/// How a preset produces a countdown: a wound duration, a wall-clock target
/// ("bedtime is 8:00 PM"), or per-kid turns.
enum TimerPresetMode: Codable, Equatable {
    case duration(TimeInterval)
    case clockTime(hour: Int, minute: Int)
    case turns(perTurn: TimeInterval)
}

/// A tappable chip on the Timers tab. The built-in list is static; user
/// tweaks (bedtime hour, kid names, adjusted durations) persist as
/// `TimerPresetConfig` in the timers JSON file.
struct TimerPreset: Identifiable, Equatable {
    let id: String
    let name: String
    let emoji: String
    let accentName: String
    let defaultMode: TimerPresetMode
    let doneTitle: String
    let doneBody: String

    static let leaveTheHouse = TimerPreset(
        id: "leave", name: "Leave the House", emoji: "🚗", accentName: "ember",
        defaultMode: .duration(10 * 60),
        doneTitle: "Time to roll! 🚗",
        doneBody: "Shoes on, everyone in the car.")
    static let bedtime = TimerPreset(
        id: "bedtime", name: "Bedtime", emoji: "🌙", accentName: "violet",
        defaultMode: .clockTime(hour: 20, minute: 0),
        doneTitle: "Bedtime, crew 🌙",
        doneBody: "Teeth, jammies, book.")
    static let cleanUp = TimerPreset(
        id: "cleanup", name: "Clean-Up", emoji: "🧹", accentName: "jade",
        defaultMode: .duration(10 * 60),
        doneTitle: "Clean-up's done! 🧹",
        doneBody: "Inspection time.")
    static let screenTime = TimerPreset(
        id: "screens", name: "Screen Time", emoji: "📺", accentName: "glacier",
        defaultMode: .duration(30 * 60),
        doneTitle: "Screens off! 📺",
        doneBody: "You did it. Eyes free.")
    static let turnTimer = TimerPreset(
        id: "turns", name: "Turn Timer", emoji: "🔁", accentName: "ember",
        defaultMode: .turns(perTurn: 5 * 60),
        doneTitle: "Switch! 🔁",
        doneBody: "Time's up — next turn.")

    static let all: [TimerPreset] = [
        .leaveTheHouse, .bedtime, .cleanUp, .screenTime, .turnTimer,
    ]

    static func named(_ id: String) -> TimerPreset? {
        all.first { $0.id == id }
    }
}

/// User overrides for a preset (bedtime hour, kid names…), persisted
/// alongside the active timers.
struct TimerPresetConfig: Codable, Equatable {
    var presetID: String
    var mode: TimerPresetMode?
    var turnNames: [String]?
}

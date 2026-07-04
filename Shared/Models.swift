import Foundation
import SwiftData

/// How progress is measured. Stored on Goal as a raw string
/// (`goalTypeName`) so the SwiftData schema change stays additive.
enum GoalKind: String {
    /// Absolute readings toward a start → target value (lose 20 lbs).
    case numeric
    /// Check-ins that add up (do X 100 times).
    case count
    /// Consecutive calendar days (do X 30 days in a row).
    case streak
}

@Model
final class Goal {
    var uuid: UUID = UUID()
    var title: String = ""
    var unit: String = ""
    var startValue: Double = 0
    var targetValue: Double = 0
    var accentName: String = "ember"
    var rewardTitle: String = ""
    var rewardImageFile: String?
    var createdAt: Date = Date()
    var targetDate: Date?
    var completedAt: Date?
    var celebratedCompletion: Bool = false
    var goalTypeName: String = "numeric"

    @Relationship(deleteRule: .cascade, inverse: \Milestone.goal)
    var milestones: [Milestone] = []

    @Relationship(deleteRule: .cascade, inverse: \ProgressEntry.goal)
    var entries: [ProgressEntry] = []

    init(title: String, unit: String, startValue: Double, targetValue: Double,
         accentName: String, rewardTitle: String, rewardImageFile: String? = nil,
         targetDate: Date? = nil, goalTypeName: String = "numeric") {
        self.uuid = UUID()
        self.title = title
        self.unit = unit
        self.startValue = startValue
        self.targetValue = targetValue
        self.accentName = accentName
        self.rewardTitle = rewardTitle
        self.rewardImageFile = rewardImageFile
        self.createdAt = Date()
        self.targetDate = targetDate
        self.goalTypeName = goalTypeName
    }
}

@Model
final class Milestone {
    var uuid: UUID = UUID()
    var value: Double = 0
    var rewardTitle: String = ""
    var rewardImageFile: String?
    var unlockedAt: Date?
    var claimedAt: Date?
    var goal: Goal?

    init(value: Double, rewardTitle: String, rewardImageFile: String? = nil) {
        self.uuid = UUID()
        self.value = value
        self.rewardTitle = rewardTitle
        self.rewardImageFile = rewardImageFile
    }
}

@Model
final class ProgressEntry {
    var uuid: UUID = UUID()
    var date: Date = Date()
    var value: Double = 0
    var note: String?
    var goal: Goal?

    init(date: Date = Date(), value: Double, note: String? = nil) {
        self.uuid = UUID()
        self.date = date
        self.value = value
        self.note = note
    }
}

// MARK: - Derived state

extension Goal {
    var kind: GoalKind {
        GoalKind(rawValue: goalTypeName) ?? .numeric
    }

    var currentValue: Double {
        switch kind {
        case .numeric:
            return entries.max(by: { $0.date < $1.date })?.value ?? startValue
        case .count:
            return startValue + entries.reduce(0) { $0 + $1.value }
        case .streak:
            return Double(currentStreak)
        }
    }

    var currentStreak: Int {
        StreakMath.currentStreak(dates: entries.map(\.date))
    }

    var bestStreak: Int {
        StreakMath.bestStreak(dates: entries.map(\.date))
    }

    var hasCheckedInToday: Bool {
        StreakMath.didLog(on: Date(), dates: entries.map(\.date))
    }

    /// Monotonic value used for milestone/completion checks. A streak goal's
    /// current streak can reset to 0, but claimed rewards must never re-lock,
    /// so achievements key off the best streak ever reached.
    private var achievementValue: Double {
        kind == .streak ? Double(bestStreak) : currentValue
    }

    var lastLoggedAt: Date? {
        entries.map(\.date).max()
    }

    var fraction: Double {
        if kind == .streak {
            guard targetValue > 0 else { return 1 }
            return isComplete ? 1 : min(1, Double(currentStreak) / targetValue)
        }
        return GoalMath.fraction(start: startValue, target: targetValue, current: currentValue)
    }

    var isComplete: Bool {
        GoalMath.reached(value: targetValue, start: startValue, target: targetValue, current: achievementValue)
    }

    /// Milestones ordered by progress position (closest-to-start first).
    var orderedMilestones: [Milestone] {
        milestones.sorted {
            GoalMath.fraction(start: startValue, target: targetValue, current: $0.value)
                < GoalMath.fraction(start: startValue, target: targetValue, current: $1.value)
        }
    }

    var nextMilestone: Milestone? {
        orderedMilestones.first {
            !GoalMath.reached(value: $0.value, start: startValue, target: targetValue, current: achievementValue)
        }
    }

    func isReached(_ milestone: Milestone) -> Bool {
        GoalMath.reached(value: milestone.value, start: startValue, target: targetValue, current: achievementValue)
    }
}

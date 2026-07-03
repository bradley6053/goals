import Foundation
import SwiftData

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

    @Relationship(deleteRule: .cascade, inverse: \Milestone.goal)
    var milestones: [Milestone] = []

    @Relationship(deleteRule: .cascade, inverse: \ProgressEntry.goal)
    var entries: [ProgressEntry] = []

    init(title: String, unit: String, startValue: Double, targetValue: Double,
         accentName: String, rewardTitle: String, rewardImageFile: String? = nil,
         targetDate: Date? = nil) {
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
    var currentValue: Double {
        entries.max(by: { $0.date < $1.date })?.value ?? startValue
    }

    var lastLoggedAt: Date? {
        entries.map(\.date).max()
    }

    var fraction: Double {
        GoalMath.fraction(start: startValue, target: targetValue, current: currentValue)
    }

    var isComplete: Bool {
        GoalMath.reached(value: targetValue, start: startValue, target: targetValue, current: currentValue)
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
            !GoalMath.reached(value: $0.value, start: startValue, target: targetValue, current: currentValue)
        }
    }

    func isReached(_ milestone: Milestone) -> Bool {
        GoalMath.reached(value: milestone.value, start: startValue, target: targetValue, current: currentValue)
    }
}

import Foundation
import SwiftData

/// The single save path for progress: numeric logs and habit check-ins both
/// come through here so milestone stamping and celebrations can't drift apart.
enum ProgressLogger {
    /// Inserts an entry, stamps newly unlocked milestones, marks completion,
    /// saves, and rewrites the widget snapshot. Returns a celebration payload
    /// if a milestone or the goal was just crossed (completion wins).
    @MainActor
    static func log(goal: Goal, value: Double, note: String?,
                    context: ModelContext) -> CelebrationPayload? {
        let before = Set(goal.milestones.filter { goal.isReached($0) }.map(\.uuid))
        let wasComplete = goal.isComplete

        let entry = ProgressEntry(value: value, note: note)
        entry.goal = goal
        context.insert(entry)

        // Stamp newly crossed milestones.
        var newlyUnlocked: [Milestone] = []
        for milestone in goal.orderedMilestones where !before.contains(milestone.uuid) {
            if goal.isReached(milestone) {
                milestone.unlockedAt = Date()
                newlyUnlocked.append(milestone)
            }
        }
        let justCompleted = !wasComplete && goal.isComplete
        if justCompleted {
            goal.completedAt = Date()
            goal.celebratedCompletion = true
        }

        try? context.save()
        if let allGoals = try? context.fetch(FetchDescriptor<Goal>()) {
            WidgetSnapshotStore.write(from: allGoals)
        }

        // Completion beats milestone if both crossed in one log.
        if justCompleted {
            return CelebrationPayload(
                milestoneLabel: GoalFormat.milestoneLabel(
                    value: goal.targetValue, start: goal.startValue,
                    target: goal.targetValue, unit: goal.unit),
                rewardTitle: goal.rewardTitle,
                rewardImageFile: goal.rewardImageFile,
                accentName: goal.accentName,
                isGoalComplete: true)
        }
        if let milestone = newlyUnlocked.last {
            return CelebrationPayload(
                milestoneLabel: GoalFormat.milestoneLabel(
                    value: milestone.value, start: goal.startValue,
                    target: goal.targetValue, unit: goal.unit),
                rewardTitle: milestone.rewardTitle,
                rewardImageFile: milestone.rewardImageFile,
                accentName: goal.accentName,
                isGoalComplete: false)
        }
        return nil
    }
}

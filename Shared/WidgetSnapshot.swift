import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// A lightweight, Codable picture of goal state, written to the App Group on
/// every save. Widgets read this instead of opening the SwiftData store —
/// simpler, faster, and immune to schema migrations.
struct GoalSnapshot: Codable, Identifiable {
    var id: UUID
    var title: String
    var accentName: String
    var unit: String
    var fraction: Double
    /// Big line, e.g. "−12 lbs"
    var headline: String
    /// Small line, e.g. "3 lbs to next reward"
    var subline: String
    var nextRewardTitle: String?
    var nextRewardImageFile: String?
    var isComplete: Bool
    var updatedAt: Date
    // Habit-goal extras. Optional so snapshots written by older builds
    // still decode (missing keys → nil → numeric rendering).
    var kindName: String? = nil
    var streakCount: Int? = nil
    var bestStreak: Int? = nil
    var lastCheckInDay: Date? = nil
}

enum WidgetSnapshotStore {
    static func write(from goals: [Goal]) {
        let active = goals
            .filter { !$0.isComplete || !$0.celebratedCompletion }
            .sorted { ($0.lastLoggedAt ?? $0.createdAt) > ($1.lastLoggedAt ?? $1.createdAt) }
        let all = active + goals.filter { !active.contains($0) }

        let snapshots = all.map { goal -> GoalSnapshot in
            let next = goal.nextMilestone

            let headline: String
            switch goal.kind {
            case .numeric:
                headline = GoalFormat.signedDelta(
                    GoalMath.deltaFromStart(start: goal.startValue, current: goal.currentValue),
                    unit: goal.unit)
            case .count:
                headline = GoalFormat.countHeadline(
                    current: goal.currentValue, target: goal.targetValue)
            case .streak:
                headline = GoalFormat.streakHeadline(goal.currentStreak)
            }

            let subline: String
            if goal.isComplete {
                subline = "Goal complete — \(goal.rewardTitle)"
            } else if goal.kind == .streak && !goal.hasCheckedInToday {
                subline = "Check in to keep the flame"
            } else if let next {
                let left = GoalMath.remaining(
                    to: next.value, current: goal.currentValue,
                    start: goal.startValue, target: goal.targetValue)
                subline = "\(GoalFormat.value(left, unit: goal.unit)) to next reward"
            } else {
                let left = GoalMath.remaining(
                    to: goal.targetValue, current: goal.currentValue,
                    start: goal.startValue, target: goal.targetValue)
                subline = "\(GoalFormat.value(left, unit: goal.unit)) to go"
            }

            let isStreak = goal.kind == .streak
            return GoalSnapshot(
                id: goal.uuid,
                title: goal.title,
                accentName: goal.accentName,
                unit: goal.unit,
                fraction: goal.fraction,
                headline: headline,
                subline: subline,
                nextRewardTitle: next?.rewardTitle ?? goal.rewardTitle,
                nextRewardImageFile: next?.rewardImageFile ?? goal.rewardImageFile,
                isComplete: goal.isComplete,
                updatedAt: Date(),
                kindName: goal.goalTypeName,
                streakCount: isStreak ? goal.currentStreak : nil,
                bestStreak: isStreak ? goal.bestStreak : nil,
                lastCheckInDay: isStreak
                    ? goal.lastLoggedAt.map { Calendar.current.startOfDay(for: $0) }
                    : nil
            )
        }

        if let data = try? JSONEncoder().encode(snapshots) {
            try? data.write(to: AppGroup.snapshotURL, options: .atomic)
        }
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    static func read() -> [GoalSnapshot] {
        guard let data = try? Data(contentsOf: AppGroup.snapshotURL) else { return [] }
        return (try? JSONDecoder().decode([GoalSnapshot].self, from: data)) ?? []
    }
}

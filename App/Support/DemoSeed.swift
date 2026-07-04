import Foundation
import SwiftData

/// Seeds a sample goal when launched with the "-seedDemo" argument.
/// Used for simulator previews and screenshots — never runs in normal use.
enum DemoSeed {
    static func runIfRequested(container: ModelContainer) {
        guard ProcessInfo.processInfo.arguments.contains("-seedDemo") else { return }
        let context = ModelContext(container)
        let existing = (try? context.fetch(FetchDescriptor<Goal>())) ?? []
        guard existing.isEmpty else { return }

        let goal = Goal(title: "Lose 20 lbs", unit: "lbs",
                        startValue: 220, targetValue: 200,
                        accentName: "ember", rewardTitle: "Golf trip to Kiawah")
        context.insert(goal)

        let m1 = Milestone(value: 210, rewardTitle: "New running shoes")
        m1.goal = goal
        m1.unlockedAt = Date()
        context.insert(m1)
        let m2 = Milestone(value: 205, rewardTitle: "Steak night out")
        m2.goal = goal
        context.insert(m2)

        for (daysAgo, value) in [(21, 218.0), (14, 215.5), (7, 212.0), (1, 208.0)] {
            let entry = ProgressEntry(
                date: Date().addingTimeInterval(-Double(daysAgo) * 86400), value: value)
            entry.goal = goal
            context.insert(entry)
        }

        let savings = Goal(title: "Save for a boat", unit: "$",
                           startValue: 0, targetValue: 15000,
                           accentName: "glacier", rewardTitle: "The boat")
        context.insert(savings)
        let s1 = Milestone(value: 5000, rewardTitle: "Weekend at the lake")
        s1.goal = savings
        context.insert(s1)
        let entry = ProgressEntry(date: Date().addingTimeInterval(-3 * 86400), value: 6200)
        entry.goal = savings
        context.insert(entry)
        s1.unlockedAt = Date()

        seedHabitGoals(context: context)

        try? context.save()
        let all = (try? context.fetch(FetchDescriptor<Goal>())) ?? []
        WidgetSnapshotStore.write(from: all)
    }

    /// One count goal and one streak goal so every kind shows in previews.
    private static func seedHabitGoals(context: ModelContext) {
        let calendar = Calendar.current

        func day(ago offset: Int, hour: Int = 9) -> Date {
            let base = calendar.date(byAdding: .day, value: -offset,
                                     to: calendar.startOfDay(for: Date())) ?? Date()
            return calendar.date(byAdding: .hour, value: hour, to: base) ?? base
        }

        // Count: 8 of 20 workouts logged, first milestone already unlocked.
        let workouts = Goal(title: "20 workouts", unit: "times",
                            startValue: 0, targetValue: 20,
                            accentName: "violet", rewardTitle: "New putter",
                            goalTypeName: GoalKind.count.rawValue)
        context.insert(workouts)
        let w1 = Milestone(value: 5, rewardTitle: "Massage")
        w1.goal = workouts
        w1.unlockedAt = Date()
        context.insert(w1)
        let w2 = Milestone(value: 12, rewardTitle: "Lifting shoes")
        w2.goal = workouts
        context.insert(w2)
        for offset in [18, 16, 13, 11, 8, 6, 3, 1] {
            let entry = ProgressEntry(date: day(ago: offset), value: 1)
            entry.goal = workouts
            context.insert(entry)
        }

        // Streak: best run of 8 ended 12 days ago; current 5-day run is
        // alive through yesterday so "Check in today" is enabled.
        let meditate = Goal(title: "Meditate daily", unit: "days",
                            startValue: 0, targetValue: 30,
                            accentName: "jade", rewardTitle: "Weekend retreat",
                            goalTypeName: GoalKind.streak.rawValue)
        context.insert(meditate)
        let m = Milestone(value: 7, rewardTitle: "Fancy coffee")
        m.goal = meditate
        m.unlockedAt = Date()
        context.insert(m)
        for offset in Array(12...19) + Array(1...5) {
            let entry = ProgressEntry(date: day(ago: offset), value: 1)
            entry.goal = meditate
            context.insert(entry)
        }
    }
}

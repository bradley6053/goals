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

        try? context.save()
        let all = (try? context.fetch(FetchDescriptor<Goal>())) ?? []
        WidgetSnapshotStore.write(from: all)
    }
}

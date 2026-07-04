import XCTest
import SwiftData
@testable import Ember

final class GoalKindTests: XCTestCase {

    // The container must outlive the context (the context does not retain it),
    // so tests hold it here rather than a helper returning only the context.
    @MainActor
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Goal.self, Milestone.self, ProgressEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    private func entry(daysAgo offset: Int, value: Double = 1, for goal: Goal,
                       in context: ModelContext) {
        let date = Calendar.current.date(
            byAdding: .day, value: -offset,
            to: Calendar.current.startOfDay(for: Date()))!
            .addingTimeInterval(9 * 3600)
        let entry = ProgressEntry(date: date, value: value)
        entry.goal = goal
        context.insert(entry)
    }

    func testUnknownGoalTypeNameFallsBackToNumeric() {
        let goal = Goal(title: "Mystery", unit: "", startValue: 0, targetValue: 10,
                        accentName: "ember", rewardTitle: "Prize")
        goal.goalTypeName = "something-from-the-future"
        XCTAssertEqual(goal.kind, .numeric)
    }

    @MainActor
    func testCountGoalCurrentValueIsSumOfEntries() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let goal = Goal(title: "100 workouts", unit: "times", startValue: 0,
                        targetValue: 100, accentName: "ember", rewardTitle: "Putter",
                        goalTypeName: GoalKind.count.rawValue)
        context.insert(goal)
        entry(daysAgo: 2, for: goal, in: context)
        entry(daysAgo: 1, for: goal, in: context)
        entry(daysAgo: 1, for: goal, in: context) // two check-ins one day
        XCTAssertEqual(goal.currentValue, 3)
        XCTAssertEqual(goal.fraction, 0.03, accuracy: 0.0001)
        XCTAssertFalse(goal.isComplete)
    }

    @MainActor
    func testStreakMilestoneStaysReachedAfterStreakBreaks() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let goal = Goal(title: "Meditate daily", unit: "days", startValue: 0,
                        targetValue: 30, accentName: "ember", rewardTitle: "Retreat",
                        goalTypeName: GoalKind.streak.rawValue)
        context.insert(goal)
        let milestone = Milestone(value: 7, rewardTitle: "Fancy coffee")
        milestone.goal = goal
        context.insert(milestone)

        // A 7-day run that ended 10 days ago — streak is dead, best is 7.
        for offset in 10...16 { entry(daysAgo: offset, for: goal, in: context) }

        XCTAssertEqual(goal.currentStreak, 0)
        XCTAssertEqual(goal.bestStreak, 7)
        XCTAssertTrue(goal.isReached(milestone),
                      "Milestones key off best streak so rewards never re-lock")
        XCTAssertNil(goal.nextMilestone, "The reached milestone is no longer 'next'")
    }

    @MainActor
    func testStreakGoalIsCompleteViaBestStreak() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let goal = Goal(title: "Stretch", unit: "days", startValue: 0,
                        targetValue: 5, accentName: "ember", rewardTitle: "Massage",
                        goalTypeName: GoalKind.streak.rawValue)
        context.insert(goal)
        // 5-day run ending 8 days ago; nothing since.
        for offset in 8...12 { entry(daysAgo: offset, for: goal, in: context) }

        XCTAssertEqual(goal.currentStreak, 0)
        XCTAssertTrue(goal.isComplete, "Hit the target once → stays conquered")
        XCTAssertEqual(goal.fraction, 1)
    }

    func testSnapshotDecodesLegacyJSONWithoutKindFields() throws {
        // Snapshot JSON exactly as the previous app version wrote it.
        let legacy = """
        [{"id":"11111111-2222-3333-4444-555555555555","title":"Lose 20 lbs",
        "accentName":"ember","unit":"lbs","fraction":0.6,"headline":"−12 lbs",
        "subline":"3 lbs to next reward","isComplete":false,
        "updatedAt":773452800}]
        """
        let snapshots = try JSONDecoder().decode([GoalSnapshot].self,
                                                 from: Data(legacy.utf8))
        XCTAssertEqual(snapshots.count, 1)
        XCTAssertNil(snapshots[0].kindName)
        XCTAssertNil(snapshots[0].streakCount)
    }
}

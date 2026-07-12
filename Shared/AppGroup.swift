import Foundation
import SwiftData

enum AppGroup {
    static let identifier = "group.com.bradniemeier.ember"

    /// Shared container if the entitlement is present, else the app's own
    /// documents directory so the app still works without the group.
    static var containerURL: URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static var imagesURL: URL {
        let url = containerURL.appendingPathComponent("Images", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static var snapshotURL: URL {
        containerURL.appendingPathComponent("widget-snapshot.json")
    }

    static var timersURL: URL {
        containerURL.appendingPathComponent("active-timers.json")
    }

    static var reflectionURL: URL {
        containerURL.appendingPathComponent("reflection.json")
    }
}

enum EmberStore {
    static func container() -> ModelContainer {
        let schema = Schema([Goal.self, Milestone.self, ProgressEntry.self,
                             GolfCourse.self, GolfTee.self, GolfHole.self,
                             GolfRound.self, GolfHoleScore.self])
        do {
            let config = ModelConfiguration(
                "Ember",
                schema: schema,
                url: AppGroup.containerURL.appendingPathComponent("Ember.store")
            )
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Last resort: in-memory so the app never crashes on launch.
            let fallback = ModelConfiguration(isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [fallback])
        }
    }
}

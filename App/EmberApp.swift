import SwiftUI
import SwiftData

@main
struct EmberApp: App {
    private let container: ModelContainer

    init() {
        container = EmberStore.container()
        DemoSeed.runIfRequested(container: container)
    }

    var body: some Scene {
        WindowGroup {
            GoalListView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}

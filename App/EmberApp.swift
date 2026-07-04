import SwiftUI
import SwiftData

@main
struct EmberApp: App {
    private let container: ModelContainer

    init() {
        container = EmberStore.container()
        DemoSeed.runIfRequested(container: container)
        GolfDemoSeed.runIfRequested(container: container)
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}

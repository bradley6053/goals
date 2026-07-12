import SwiftUI
import SwiftData

@main
struct EmberApp: App {
    private let container: ModelContainer
    @State private var timerStore = TimerStore()
    @State private var reflectionStore = ReflectionStore()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        container = EmberStore.container()
        DemoSeed.runIfRequested(container: container)
        GolfDemoSeed.runIfRequested(container: container)
        TimerNotificationDelegate.shared.install()
        // "-demoTimer" starts a 2-minute countdown on launch — simulator
        // testing/screenshots only, same pattern as "-seedDemo".
        if ProcessInfo.processInfo.arguments.contains("-demoTimer"),
           timerStore.timers.isEmpty {
            timerStore.start(seconds: 120, label: "Leave the House",
                             emoji: "🚗", accentName: "ember",
                             doneTitle: "Time to roll! 🚗",
                             doneBody: "Shoes on, everyone in the car.")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .preferredColorScheme(.dark)
                .environment(timerStore)
                .environment(reflectionStore)
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, phase in
            // Timers that fired while we were backgrounded already alerted
            // via their notification — drop them on return.
            if phase == .active { timerStore.sweep(now: Date()) }
        }
    }
}

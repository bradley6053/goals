import SwiftUI

/// Root tab bar. Each tab is intentionally its own world: Goals keeps the
/// dark ember look, Golf goes full Sweetens Cove cream.
struct RootTabView: View {
    enum Tab: Hashable {
        case goals, timers, golf
    }

    /// "-golfTab"/"-timersTab" launch arguments open straight to a tab —
    /// same pattern as DemoSeed's "-seedDemo", used for simulator screenshots.
    @State private var selection: Tab = {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-golfTab") { return .golf }
        if args.contains("-timersTab") { return .timers }
        return .goals
    }()

    var body: some View {
        TabView(selection: $selection) {
            GoalListView()
                .tabItem { Label("Goals", systemImage: "flame.fill") }
                .tag(Tab.goals)

            TimersHomeView()
                .tabItem { Label("Timers", systemImage: "timer") }
                .tag(Tab.timers)

            GolfHomeView()
                .tabItem { Label("Golf", systemImage: "figure.golf") }
                .tag(Tab.golf)
        }
        // ember://golf and ember://timers jump straight to a tab (used by
        // deep links — the Live Activity taps through ember://timers).
        // Goal links keep working — GoalListView has its own onOpenURL for
        // ember://goal/<uuid>.
        .onOpenURL { url in
            if url.host() == "golf" { selection = .golf }
            if url.host() == "timers" { selection = .timers }
        }
    }
}

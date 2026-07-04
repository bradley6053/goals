import SwiftUI

/// Root tab bar. Each tab is intentionally its own world: Goals keeps the
/// dark ember look, Golf goes full Sweetens Cove cream.
struct RootTabView: View {
    enum Tab: Hashable {
        case goals, golf
    }

    /// "-golfTab" launch argument opens straight to golf — same pattern as
    /// DemoSeed's "-seedDemo", used for simulator screenshots.
    @State private var selection: Tab =
        ProcessInfo.processInfo.arguments.contains("-golfTab") ? .golf : .goals

    var body: some View {
        TabView(selection: $selection) {
            GoalListView()
                .tabItem { Label("Goals", systemImage: "flame.fill") }
                .tag(Tab.goals)

            GolfHomeView()
                .tabItem { Label("Golf", systemImage: "figure.golf") }
                .tag(Tab.golf)
        }
        // ember://golf jumps straight to the golf tab (used by deep links
        // and handy for a future golf widget). Goal links keep working —
        // GoalListView has its own onOpenURL for ember://goal/<uuid>.
        .onOpenURL { url in
            if url.host() == "golf" { selection = .golf }
        }
    }
}

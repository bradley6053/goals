import SwiftUI
import SwiftData

struct GoalListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Goal.createdAt, order: .reverse) private var goals: [Goal]
    @State private var path: [Goal] = []
    @State private var showingEditor = false

    private var activeGoals: [Goal] { goals.filter { !$0.isComplete } }
    private var completedGoals: [Goal] { goals.filter { $0.isComplete } }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if goals.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(activeGoals) { goal in
                                NavigationLink(value: goal) {
                                    GoalCardView(goal: goal)
                                }
                                .buttonStyle(.plain)
                            }
                            if !completedGoals.isEmpty {
                                OverlineText("Conquered")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 20)
                                ForEach(completedGoals) { goal in
                                    NavigationLink(value: goal) {
                                        GoalCardView(goal: goal)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Ember")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Goal.self) { goal in
                GoalDetailView(goal: goal)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                GoalEditorView()
            }
            .onAppear {
                // Screenshot/dev helper: jump straight into the first goal.
                if ProcessInfo.processInfo.arguments.contains("-openFirstGoal") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if path.isEmpty, let first = activeGoals.first { path = [first] }
                    }
                }
            }
            .onOpenURL { url in
                guard url.scheme == "ember",
                      let idString = url.pathComponents.last ?? url.host,
                      let uuid = UUID(uuidString: idString),
                      let goal = goals.first(where: { $0.uuid == uuid })
                else { return }
                path = [goal]
            }
        }
        .tint(Theme.textPrimary)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "flame.fill")
                .font(.system(size: 44))
                .foregroundStyle(Accent.ember.gradient)
                .shadow(color: Accent.ember.primary.opacity(0.6), radius: 18)
            Text("SET A GOAL\nWORTH CHASING")
                .font(Theme.display(34))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textPrimary)
            Text("Pick the prize. Earn it one milestone at a time.")
                .font(.system(size: 15))
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            EmberButton(title: "New goal", accent: .ember, systemImage: "plus") {
                showingEditor = true
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 24)
    }
}

/// Photo-forward card: reward image bleeding into the dark card, condensed
/// title, glowing progress, next-unlock line.
struct GoalCardView: View {
    let goal: Goal

    var body: some View {
        let accent = Accent.named(goal.accentName)
        let next = goal.nextMilestone

        EmberCard {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    Group {
                        if let image = ImageStore.image(next?.rewardImageFile ?? goal.rewardImageFile) {
                            Color.clear.overlay(
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                            )
                        } else {
                            Rectangle().fill(
                                LinearGradient(
                                    colors: [accent.primary.opacity(0.35), Theme.card],
                                    startPoint: .topTrailing, endPoint: .bottomLeading))
                        }
                    }
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .overlay(
                        Rectangle().fill(
                            LinearGradient(
                                colors: [.clear, .clear, Theme.card],
                                startPoint: .top, endPoint: .bottom))
                    )

                    HStack {
                        Text(goal.title.uppercased())
                            .font(Theme.display(26))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(2)
                            .shadow(color: .black.opacity(0.7), radius: 6, y: 1)
                        Spacer()
                        if goal.isComplete {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(accent.gradient)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 4)
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(statsLine)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(accent.gradient)
                        Spacer()
                        Text(nextLine(next: next, accent: accent))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    GlowProgressBar(fraction: goal.fraction, accent: accent, height: 8)
                }
                .padding(18)
            }
        }
    }

    private var statsLine: String {
        switch goal.kind {
        case .numeric:
            return GoalFormat.signedDelta(
                GoalMath.deltaFromStart(start: goal.startValue, current: goal.currentValue),
                unit: goal.unit)
        case .count:
            let headline = GoalFormat.countHeadline(
                current: goal.currentValue, target: goal.targetValue)
            return goal.unit.isEmpty ? headline : "\(headline) \(goal.unit)"
        case .streak:
            return GoalFormat.streakHeadline(goal.currentStreak)
        }
    }

    private func nextLine(next: Milestone?, accent: Accent) -> String {
        if goal.isComplete {
            return "Reward earned: \(goal.rewardTitle)"
        }
        if let next {
            let left = GoalMath.remaining(
                to: next.value, current: goal.currentValue,
                start: goal.startValue, target: goal.targetValue)
            return "\(GoalFormat.value(left, unit: goal.unit)) to \(next.rewardTitle)"
        }
        let left = GoalMath.remaining(
            to: goal.targetValue, current: goal.currentValue,
            start: goal.startValue, target: goal.targetValue)
        return "\(GoalFormat.value(left, unit: goal.unit)) to \(goal.rewardTitle)"
    }
}

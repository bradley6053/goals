import SwiftUI
import SwiftData

/// Everything the celebration screen needs, captured at unlock time.
struct CelebrationPayload: Identifiable {
    let id = UUID()
    let milestoneLabel: String
    let rewardTitle: String
    let rewardImageFile: String?
    let accentName: String
    let isGoalComplete: Bool
}

struct LogProgressSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let goal: Goal
    let onCelebration: (CelebrationPayload) -> Void

    @State private var valueText = ""
    @State private var note = ""
    @FocusState private var valueFocused: Bool

    var body: some View {
        let accent = Accent.named(goal.accentName)

        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        OverlineText("Where are you now?")
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            TextField(GoalFormat.number(goal.currentValue), text: $valueText)
                                .keyboardType(.decimalPad)
                                .focused($valueFocused)
                                .font(.system(size: 56, weight: .heavy, design: .rounded))
                                .monospacedDigit()
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Theme.textPrimary)
                                .fixedSize()
                            if !goal.unit.trimmingCharacters(in: .whitespaces).isEmpty {
                                Text(goal.unit)
                                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                    }
                    .padding(.top, 32)

                    if let preview = parsedValue {
                        Text(previewLine(for: preview, accent: accent))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(accent.primary)
                            .animation(.default, value: valueText)
                    }

                    TextField("Add a note (optional)", text: $note)
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.textPrimary)
                        .padding(16)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.radiusInner))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radiusInner)
                                .strokeBorder(Theme.stroke, lineWidth: 1)
                        )
                        .padding(.horizontal, 24)

                    Spacer()

                    EmberButton(title: "Save", accent: accent, systemImage: "checkmark") {
                        save()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .disabled(parsedValue == nil)
                    .opacity(parsedValue == nil ? 0.4 : 1)
                }
            }
            .navigationTitle("Log progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .onAppear { valueFocused = true }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Theme.bg)
    }

    private var parsedValue: Double? {
        Double(valueText.replacingOccurrences(of: ",", with: "."))
    }

    private func previewLine(for value: Double, accent: Accent) -> String {
        let delta = GoalMath.deltaFromStart(start: goal.startValue, current: value)
        return "That's \(GoalFormat.signedDelta(delta, unit: goal.unit)) from where you started"
    }

    private func save() {
        guard let value = parsedValue else { return }

        let before = Set(goal.milestones.filter { goal.isReached($0) }.map(\.uuid))
        let wasComplete = goal.isComplete

        let entry = ProgressEntry(value: value, note: note.isEmpty ? nil : note)
        entry.goal = goal
        context.insert(entry)

        // Stamp newly crossed milestones.
        var newlyUnlocked: [Milestone] = []
        for milestone in goal.orderedMilestones where !before.contains(milestone.uuid) {
            if goal.isReached(milestone) {
                milestone.unlockedAt = Date()
                newlyUnlocked.append(milestone)
            }
        }
        let justCompleted = !wasComplete && goal.isComplete
        if justCompleted {
            goal.completedAt = Date()
            goal.celebratedCompletion = true
        }

        try? context.save()
        if let allGoals = try? context.fetch(FetchDescriptor<Goal>()) {
            WidgetSnapshotStore.write(from: allGoals)
        }

        dismiss()

        // Completion beats milestone if both crossed in one log.
        if justCompleted {
            onCelebration(CelebrationPayload(
                milestoneLabel: GoalFormat.milestoneLabel(
                    value: goal.targetValue, start: goal.startValue,
                    target: goal.targetValue, unit: goal.unit),
                rewardTitle: goal.rewardTitle,
                rewardImageFile: goal.rewardImageFile,
                accentName: goal.accentName,
                isGoalComplete: true))
        } else if let milestone = newlyUnlocked.last {
            onCelebration(CelebrationPayload(
                milestoneLabel: GoalFormat.milestoneLabel(
                    value: milestone.value, start: goal.startValue,
                    target: goal.targetValue, unit: goal.unit),
                rewardTitle: milestone.rewardTitle,
                rewardImageFile: milestone.rewardImageFile,
                accentName: goal.accentName,
                isGoalComplete: false))
        } else {
            Haptics.success()
        }
    }
}

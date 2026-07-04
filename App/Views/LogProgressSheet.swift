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

        let payload = ProgressLogger.log(
            goal: goal, value: value,
            note: note.isEmpty ? nil : note, context: context)

        dismiss()

        if let payload {
            onCelebration(payload)
        } else {
            Haptics.success()
        }
    }
}

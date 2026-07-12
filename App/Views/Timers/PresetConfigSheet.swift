import SwiftUI

/// Customize a preset chip: bedtime's clock time, a duration preset's
/// default minutes, or the turn timer's kid names + per-turn length.
/// Saved overrides persist with the timers JSON and win over defaults.
struct PresetConfigSheet: View {
    let preset: TimerPreset

    @Environment(TimerStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var minutes = 10
    @State private var clockDate = Date()
    @State private var names: [String] = ["", "", "", ""]

    private var accent: Accent { Accent.named(preset.accentName) }

    private var isClockTime: Bool {
        if case .clockTime = store.mode(for: preset) { return true }
        return false
    }

    private var isTurns: Bool {
        if case .turns = store.mode(for: preset) { return true }
        return false
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text(preset.emoji)
                        .font(.system(size: 40))
                    OverlineText("Customize")
                    Text(preset.name)
                        .font(Theme.display(28))
                        .foregroundStyle(Theme.textPrimary)
                }

                if isClockTime {
                    clockTimeEditor
                } else {
                    minutesEditor
                }

                if isTurns {
                    namesEditor
                }

                Spacer(minLength: 0)

                EmberButton(title: "Save", accent: accent, systemImage: "checkmark") {
                    saveAndDismiss()
                }
            }
            .padding(24)
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear(perform: seed)
    }

    private var clockTimeEditor: some View {
        EmberCard {
            VStack(spacing: 8) {
                OverlineText("Counts down to")
                DatePicker("", selection: $clockDate,
                           displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
            }
            .padding(16)
        }
    }

    private var minutesEditor: some View {
        EmberCard {
            VStack(spacing: 8) {
                OverlineText(isTurns ? "Each turn" : "Default length")
                HStack(spacing: 20) {
                    stepButton("minus") { minutes = max(1, minutes - 1) }
                    Text(TimerMath.windLabel(TimeInterval(minutes * 60)))
                        .font(Theme.display(30))
                        .monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                        .frame(minWidth: 130)
                    stepButton("plus") { minutes = min(240, minutes + 1) }
                }
            }
            .padding(16)
        }
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(accent.primary)
                .frame(width: 44, height: 44)
                .background(Theme.elevated, in: Circle())
                .overlay(Circle().strokeBorder(Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var namesEditor: some View {
        EmberCard {
            VStack(alignment: .leading, spacing: 10) {
                OverlineText("Who's taking turns?")
                ForEach(0..<4, id: \.self) { i in
                    TextField("Kid \(i + 1)", text: $names[i])
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(Theme.elevated,
                                    in: RoundedRectangle(cornerRadius: Theme.radiusInner))
                }
            }
            .padding(16)
        }
    }

    private func seed() {
        switch store.mode(for: preset) {
        case .duration(let seconds):
            minutes = max(1, Int(seconds / 60))
        case .turns(let perTurn):
            minutes = max(1, Int(perTurn / 60))
        case .clockTime(let hour, let minute):
            clockDate = Calendar.current.date(
                bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        }
        let saved = store.config(for: preset)?.turnNames ?? []
        for (i, name) in saved.prefix(4).enumerated() { names[i] = name }
    }

    private func saveAndDismiss() {
        let mode: TimerPresetMode
        switch store.mode(for: preset) {
        case .duration:
            mode = .duration(TimeInterval(minutes * 60))
        case .turns:
            mode = .turns(perTurn: TimeInterval(minutes * 60))
        case .clockTime:
            let parts = Calendar.current.dateComponents([.hour, .minute], from: clockDate)
            mode = .clockTime(hour: parts.hour ?? 20, minute: parts.minute ?? 0)
        }
        let cleanNames = names
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        store.saveConfig(TimerPresetConfig(
            presetID: preset.id, mode: mode,
            turnNames: cleanNames.isEmpty ? nil : cleanNames))
        dismiss()
    }
}

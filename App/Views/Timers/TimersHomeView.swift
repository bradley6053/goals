import SwiftUI

/// Timers tab root: preset chips wind the big dial for you (or start a
/// clock-anchored countdown outright), and a hand-wound timer is always one
/// drag away. Multiple timers can run at once (bedtime counting down while
/// the leave-the-house clock ticks); the list below swaps which one the big
/// dial shows.
struct TimersHomeView: View {
    @Environment(TimerStore.self) private var store

    @State private var windAngle: Double = 0
    @State private var focusedTimerID: UUID?
    /// Chip the dial is currently pre-wound for — start uses its identity.
    @State private var pendingPreset: TimerPreset?
    /// Chip being customized (long-press / context menu).
    @State private var configPreset: TimerPreset?

    private var focusedTimer: EmberTimer? {
        store.timers.first { $0.id == focusedTimerID }
    }

    private var windAccent: Accent {
        Accent.named(pendingPreset?.accentName ?? Accent.ember.name)
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    header
                    presetChips

                    if let timer = focusedTimer {
                        RunningDial(timer: timer, accent: Accent.named(timer.accentName))
                            .padding(.horizontal, 12)
                        runningControls(for: timer)
                    } else {
                        WindingDial(cumulativeAngle: $windAngle, accent: windAccent)
                            .padding(.horizontal, 12)
                        startButton
                    }

                    otherTimersList
                }
                .padding(20)
            }
        }
        .sheet(item: $configPreset) { preset in
            PresetConfigSheet(preset: preset)
        }
        .onAppear { focusFirstRunningTimer() }
    }

    private var header: some View {
        VStack(spacing: 4) {
            OverlineText("Dad clock")
            Text("Timers")
                .font(Theme.display(34))
                .foregroundStyle(Theme.textPrimary)
        }
    }

    // MARK: - Preset chips

    private var presetChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(TimerPreset.all) { preset in
                    presetChip(preset)
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
        }
    }

    private func presetChip(_ preset: TimerPreset) -> some View {
        let accent = Accent.named(preset.accentName)
        let selected = pendingPreset?.id == preset.id && focusedTimer == nil

        return Button {
            tapPreset(preset)
        } label: {
            HStack(spacing: 7) {
                Text(preset.emoji)
                    .font(.system(size: 16))
                Text(preset.name.uppercased())
                    .font(Theme.label(11))
                    .tracking(1.1)
                    .foregroundStyle(selected ? Theme.textPrimary : Theme.textSecondary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(Theme.elevated, in: Capsule())
            .overlay(Capsule().strokeBorder(
                accent.primary.opacity(selected ? 0.9 : 0.35), lineWidth: 1))
            .shadow(color: selected ? accent.primary.opacity(0.35) : .clear, radius: 8)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                configPreset = preset
            } label: {
                Label("Customize", systemImage: "slider.horizontal.3")
            }
        }
    }

    private func tapPreset(_ preset: TimerPreset) {
        Haptics.firm()
        switch store.mode(for: preset) {
        case .duration(let seconds):
            preWind(preset, to: seconds)

        case .clockTime(let hour, let minute):
            // Anchored to the wall clock — no winding, it starts now.
            let end = TimerMath.nextOccurrence(hour: hour, minute: minute, after: Date())
            let timer = store.start(
                seconds: end.timeIntervalSinceNow,
                label: preset.name, emoji: preset.emoji,
                accentName: preset.accentName,
                doneTitle: preset.doneTitle, doneBody: preset.doneBody)
            focusedTimerID = timer.id

        case .turns(let perTurn):
            // Need names before the first turn can start.
            if (store.config(for: preset)?.turnNames ?? []).isEmpty {
                configPreset = preset
            } else {
                preWind(preset, to: perTurn)
            }
        }
    }

    /// The dial visibly spins itself to the preset's duration — the user can
    /// still drag to adjust before starting.
    private func preWind(_ preset: TimerPreset, to seconds: TimeInterval) {
        pendingPreset = preset
        focusedTimerID = nil
        withAnimation(.spring(duration: 0.8, bounce: 0.25)) {
            windAngle = TimerMath.totalAngle(for: seconds)
        }
    }

    // MARK: - Winding

    private var windDuration: TimeInterval {
        TimerMath.duration(forTotalAngle: windAngle)
    }

    private var startButton: some View {
        EmberButton(title: startTitle, accent: windAccent, systemImage: "play.fill") {
            startWoundTimer()
        }
        .disabled(windDuration <= 0)
        .opacity(windDuration <= 0 ? 0.35 : 1)
        .animation(.default, value: windDuration <= 0)
    }

    private var startTitle: String {
        if let preset = pendingPreset,
           case .turns = store.mode(for: preset),
           let first = store.config(for: preset)?.turnNames?.first {
            return "Start · \(first) first"
        }
        return "Start"
    }

    private func startWoundTimer() {
        let preset = pendingPreset
        var kind = TimerKind.countdown
        var turnNames: [String]?
        if let preset, case .turns = store.mode(for: preset) {
            kind = .turns
            turnNames = store.config(for: preset)?.turnNames
        }
        let timer = store.start(
            seconds: windDuration,
            label: preset?.name ?? "Timer",
            emoji: preset?.emoji ?? "⏱️",
            accentName: preset?.accentName ?? Accent.ember.name,
            kind: kind, turnNames: turnNames, turnIndex: turnNames == nil ? nil : 0,
            doneTitle: preset?.doneTitle,
            // Turns keep a nil body so the notification names whoever is next.
            doneBody: kind == .turns ? nil : preset?.doneBody)
        focusedTimerID = timer.id
        pendingPreset = nil
        windAngle = 0
    }

    // MARK: - Running

    @ViewBuilder
    private func runningControls(for timer: EmberTimer) -> some View {
        let accent = Accent.named(timer.accentName)
        let finished = timer.isFinished(at: Date())

        HStack(spacing: 12) {
            if finished {
                if timer.kind == .turns, let next = timer.nextTurnName {
                    EmberButton(title: "Next · \(next)", accent: accent,
                                systemImage: "arrow.triangle.2.circlepath") {
                        let handoff = store.startNextTurn(after: timer)
                        focusedTimerID = handoff.id
                    }
                }
                EmberButton(title: timer.kind == .turns ? "Done" : "Clear",
                            accent: accent, systemImage: "checkmark") {
                    store.cancel(timer.id)
                    focusedTimerID = nil
                }
            } else {
                capsuleButton(timer.isPaused ? "Resume" : "Pause",
                              systemImage: timer.isPaused ? "play.fill" : "pause.fill",
                              accent: accent) {
                    timer.isPaused ? store.resume(timer.id) : store.pause(timer.id)
                }
                capsuleButton("Cancel", systemImage: "xmark", accent: nil) {
                    store.cancel(timer.id)
                    focusedTimerID = nil
                }
            }
        }
    }

    private func capsuleButton(_ title: String, systemImage: String,
                               accent: Accent?, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .bold))
                Text(title.uppercased())
                    .font(Theme.label(13))
                    .tracking(1.2)
            }
            .foregroundStyle(accent == nil ? Theme.textSecondary : Theme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.elevated, in: Capsule())
            .overlay(
                Capsule().strokeBorder(
                    accent?.primary.opacity(0.5) ?? Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Timer list

    /// Every active timer except the one on the big dial. Also the way back
    /// to the winding dial: "New Timer" clears focus.
    @ViewBuilder
    private var otherTimersList: some View {
        let others = store.timers.filter { $0.id != focusedTimerID }

        VStack(spacing: 10) {
            if focusedTimer != nil {
                Button {
                    Haptics.tap()
                    focusedTimerID = nil
                    pendingPreset = nil
                    windAngle = 0
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                        Text("NEW TIMER")
                            .font(Theme.label(13))
                            .tracking(1.2)
                    }
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }

            ForEach(others) { timer in
                timerRow(timer)
            }
        }
    }

    private func timerRow(_ timer: EmberTimer) -> some View {
        let accent = Accent.named(timer.accentName)
        return Button {
            Haptics.tap()
            focusedTimerID = timer.id
        } label: {
            EmberCard {
                HStack(spacing: 12) {
                    Text(timer.emoji)
                        .font(.system(size: 24))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(timer.label)
                            .font(Theme.label(13))
                            .foregroundStyle(Theme.textPrimary)
                        if let turn = timer.currentTurnName {
                            Text(turn)
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                    Spacer()
                    if timer.isPaused {
                        Text(TimerMath.remainingText(timer.remaining(at: Date())))
                            .font(Theme.display(22))
                            .monospacedDigit()
                            .foregroundStyle(Theme.textSecondary)
                    } else {
                        Text(timerInterval: rowInterval(timer), countsDown: true)
                            .font(Theme.display(22))
                            .monospacedDigit()
                            .foregroundStyle(accent.gradient)
                            .frame(maxWidth: 90, alignment: .trailing)
                    }
                }
                .padding(16)
            }
        }
        .buttonStyle(.plain)
    }

    private func rowInterval(_ timer: EmberTimer) -> ClosedRange<Date> {
        let start = timer.endDate.addingTimeInterval(-timer.totalSeconds)
        return start...max(timer.endDate, start)
    }

    private func focusFirstRunningTimer() {
        if focusedTimerID == nil, let first = store.timers.first {
            focusedTimerID = first.id
        }
    }
}

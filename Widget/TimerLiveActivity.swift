import ActivityKit
import WidgetKit
import SwiftUI

/// Lock Screen + Dynamic Island presentation for a running timer. Both the
/// countdown text and the progress views are timer-interval driven, so the
/// system advances them every second — no pushes, no updates while counting.
struct TimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            TimerLockScreenView(context: context)
                .activityBackgroundTint(Theme.bg.opacity(0.85))
                .activitySystemActionForegroundColor(Theme.textPrimary)
        } dynamicIsland: { context in
            let accent = Accent.named(context.attributes.accentName)

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Text(context.attributes.emoji)
                            .font(.system(size: 28))
                        Text(context.attributes.label.uppercased())
                            .font(Theme.label(12))
                            .tracking(1.2)
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(1)
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    countdown(context, size: 28)
                        .foregroundStyle(accent.gradient)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    progressBar(context)
                        .tint(accent.primary)
                        .padding(.horizontal, 4)
                }
            } compactLeading: {
                Text(context.attributes.emoji)
            } compactTrailing: {
                countdown(context, size: 14)
                    .foregroundStyle(accent.primary)
                    // Fixed width — changing digits must not make the island
                    // breathe every second.
                    .frame(width: 44)
            } minimal: {
                minimalRing(context, accent: accent)
            }
            .keylineTint(accent.primary)
        }
    }

    private func interval(_ context: ActivityViewContext<TimerActivityAttributes>) -> ClosedRange<Date> {
        let end = context.state.endDate
        let start = end.addingTimeInterval(-context.attributes.totalSeconds)
        return start...max(end, start)
    }

    /// Ticking digits while running, frozen digits while paused.
    @ViewBuilder
    private func countdown(_ context: ActivityViewContext<TimerActivityAttributes>,
                           size: CGFloat) -> some View {
        if let paused = context.state.pausedRemaining {
            Text(TimerMath.remainingText(paused))
                .font(Theme.display(size))
                .monospacedDigit()
        } else {
            Text(timerInterval: interval(context), countsDown: true)
                .font(Theme.display(size))
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
        }
    }

    @ViewBuilder
    private func progressBar(_ context: ActivityViewContext<TimerActivityAttributes>) -> some View {
        if let paused = context.state.pausedRemaining {
            ProgressView(value: min(1, max(0, paused / max(context.attributes.totalSeconds, 1))))
        } else {
            ProgressView(timerInterval: interval(context), countsDown: true) {
            } currentValueLabel: { EmptyView() }
        }
    }

    @ViewBuilder
    private func minimalRing(_ context: ActivityViewContext<TimerActivityAttributes>,
                             accent: Accent) -> some View {
        if context.state.pausedRemaining != nil {
            Image(systemName: "pause.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(accent.primary)
        } else {
            ProgressView(timerInterval: interval(context), countsDown: true) {
            } currentValueLabel: {
                Text(context.attributes.emoji)
                    .font(.system(size: 9))
            }
            .progressViewStyle(.circular)
            .tint(accent.primary)
        }
    }
}

/// The Lock Screen banner — same Ember card language as the app: dark
/// surface, condensed black digits, glowing accent progress.
struct TimerLockScreenView: View {
    let context: ActivityViewContext<TimerActivityAttributes>

    private var accent: Accent { Accent.named(context.attributes.accentName) }

    private var interval: ClosedRange<Date> {
        let end = context.state.endDate
        let start = end.addingTimeInterval(-context.attributes.totalSeconds)
        return start...max(end, start)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Text(context.attributes.emoji)
                    .font(.system(size: 30))
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.label.uppercased())
                        .font(Theme.label(12))
                        .tracking(1.4)
                        .foregroundStyle(Theme.textSecondary)
                    if context.state.pausedRemaining != nil {
                        Text("PAUSED")
                            .font(Theme.label(10))
                            .tracking(1.2)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                Spacer()
                if let paused = context.state.pausedRemaining {
                    Text(TimerMath.remainingText(paused))
                        .font(Theme.display(34))
                        .monospacedDigit()
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    Text(timerInterval: interval, countsDown: true)
                        .font(Theme.display(34))
                        .monospacedDigit()
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(accent.gradient)
                }
            }

            Group {
                if let paused = context.state.pausedRemaining {
                    ProgressView(value: min(1, max(0, paused / max(context.attributes.totalSeconds, 1))))
                } else {
                    ProgressView(timerInterval: interval, countsDown: true) {
                    } currentValueLabel: { EmptyView() }
                }
            }
            .tint(accent.primary)
        }
        .padding(16)
    }
}

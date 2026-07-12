import SwiftUI

/// The shared ring visual: tick marks, dim track, glowing accent arc, and a
/// knob at the arc tip. Both the winding dial and the running countdown are
/// drawn with this — only the fraction/knob inputs differ.
private struct DialRing<Center: View>: View {
    /// 0…1 fill of the visible ring.
    let fraction: Double
    /// Completed revolutions beyond the visible arc (wound hours).
    var extraRevolutions: Int = 0
    /// Where the knob sits, 0…1 around the ring. Nil hides the knob.
    var knobFraction: Double?
    let accent: Accent
    @ViewBuilder var center: Center

    private let ringWidth: CGFloat = 14

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let radius = side / 2 - 22
            let c = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            ZStack {
                // 60 tick marks, every 5th brighter — the clock face.
                Canvas { context, _ in
                    for tick in 0..<60 {
                        let angle = Double(tick) / 60 * 2 * .pi
                        let major = tick % 5 == 0
                        let inner = radius - ringWidth - (major ? 14 : 9)
                        let outer = radius - ringWidth - 4
                        var path = Path()
                        path.move(to: point(angle: angle, radius: inner, center: c))
                        path.addLine(to: point(angle: angle, radius: outer, center: c))
                        context.stroke(path,
                                       with: .color(.white.opacity(major ? 0.28 : 0.10)),
                                       lineWidth: major ? 2 : 1)
                    }
                }

                // Fully-wound hours sit as a solid inset ring behind the arc.
                if extraRevolutions > 0 {
                    Circle()
                        .stroke(accent.gradient, lineWidth: 3)
                        .frame(width: (radius - ringWidth - 22) * 2,
                               height: (radius - ringWidth - 22) * 2)
                        .opacity(0.7)
                }

                Circle()
                    .stroke(Color.white.opacity(0.07), lineWidth: ringWidth)
                    .frame(width: radius * 2, height: radius * 2)

                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(accent.gradient,
                            style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
                    .frame(width: radius * 2, height: radius * 2)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: accent.primary.opacity(0.55), radius: 10)

                if let knobFraction {
                    let angle = knobFraction * 2 * .pi
                    Circle()
                        .fill(accent.gradient)
                        .frame(width: 26, height: 26)
                        .overlay(Circle().strokeBorder(.white.opacity(0.85), lineWidth: 2))
                        .shadow(color: accent.primary.opacity(0.7), radius: 8)
                        .position(point(angle: angle, radius: radius, center: c))
                }

                center

                if extraRevolutions > 0 {
                    OverlineText("+\(extraRevolutions) HR", color: accent.secondary)
                        .position(x: c.x, y: c.y - radius + ringWidth + 34)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func point(angle: Double, radius: CGFloat, center: CGPoint) -> CGPoint {
        CGPoint(x: center.x + radius * sin(angle),
                y: center.y - radius * cos(angle))
    }
}

/// Interactive dial: drag around the circle to wind time on, like winding a
/// kitchen timer. Clockwise adds, counter-clockwise takes away, and every
/// full lap stacks another hour. All the angle math lives in TimerMath.
struct WindingDial: View {
    @Binding var cumulativeAngle: Double
    let accent: Accent

    /// Baseline for delta tracking; nil until the finger lands (or after it
    /// wanders into the center dead zone, where atan2 goes wild).
    @State private var lastRawAngle: Double?

    private var duration: TimeInterval { TimerMath.duration(forTotalAngle: cumulativeAngle) }
    private var snappedMinutes: Int { Int(duration / 60) }
    private var revolutions: Int { Int(cumulativeAngle / (2 * .pi)) }

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            DialRing(
                fraction: (cumulativeAngle / (2 * .pi)).truncatingRemainder(dividingBy: 1),
                extraRevolutions: revolutions,
                knobFraction: (cumulativeAngle / (2 * .pi)).truncatingRemainder(dividingBy: 1),
                accent: accent
            ) {
                VStack(spacing: 6) {
                    OverlineText("Wind to set")
                    Text(TimerMath.windLabel(duration))
                        .font(Theme.display(46))
                        .monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                        .contentTransition(.numericText())
                        .animation(.snappy(duration: 0.2), value: snappedMinutes)
                }
            }
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let p = value.location
                        // Dead zone: atan2 is unstable near the center.
                        guard hypot(p.x - center.x, p.y - center.y) > 24 else {
                            lastRawAngle = nil
                            return
                        }
                        let raw = TimerMath.angle(of: p, around: center)
                        // First sample only sets the baseline — landing at
                        // 3 o'clock must not teleport the dial there.
                        if let last = lastRawAngle {
                            let before = snappedMinutes
                            let beforeRevs = revolutions
                            cumulativeAngle = TimerMath.accumulate(
                                cumulativeAngle,
                                adding: TimerMath.angleDelta(from: last, to: raw))
                            if revolutions != beforeRevs {
                                Haptics.firm()
                            } else if snappedMinutes != before {
                                Haptics.tap()
                            }
                        }
                        lastRawAngle = raw
                    }
                    .onEnded { _ in
                        lastRawAngle = nil
                        withAnimation(.spring(duration: 0.35)) {
                            cumulativeAngle = TimerMath.totalAngle(for: duration)
                        }
                    }
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// A running timer's dial: the ring drains toward zero and the readout is a
/// system-driven countdown, so it stays correct without any app-side ticking.
struct RunningDial: View {
    let timer: EmberTimer
    let accent: Accent

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20)) { timeline in
            let remaining = timer.remaining(at: timeline.date)
            let fraction = timer.isPaused
                ? min(1, max(0, (timer.pausedRemaining ?? 0) / max(timer.totalSeconds, 1)))
                : TimerMath.fractionRemaining(endDate: timer.endDate,
                                              total: timer.totalSeconds,
                                              now: timeline.date)

            DialRing(fraction: fraction, knobFraction: nil, accent: accent) {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Text(timer.emoji)
                        OverlineText(centerLabel, color: Theme.textSecondary)
                    }
                    if remaining <= 0 {
                        Text("DONE")
                            .font(Theme.display(52))
                            .foregroundStyle(accent.gradient)
                    } else if timer.isPaused {
                        Text(TimerMath.remainingText(remaining))
                            .font(Theme.display(52))
                            .monospacedDigit()
                            .foregroundStyle(Theme.textSecondary)
                    } else {
                        // Self-updating — the system redraws this every second.
                        Text(timerInterval: interval, countsDown: true)
                            .font(Theme.display(52))
                            .monospacedDigit()
                            .foregroundStyle(Theme.textPrimary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        // Haptic fanfare if the timer hits zero while we're watching it.
        // Re-arms whenever the end date moves (resume) or pause state flips.
        .task(id: "\(timer.id)-\(timer.endDate.timeIntervalSinceReferenceDate)-\(timer.isPaused)") {
            guard !timer.isPaused else { return }
            let wait = timer.endDate.timeIntervalSinceNow
            guard wait > 0 else { return }
            try? await Task.sleep(for: .seconds(wait))
            Haptics.unlock()
        }
    }

    private var interval: ClosedRange<Date> {
        let start = timer.endDate.addingTimeInterval(-timer.totalSeconds)
        return start...max(timer.endDate, start)
    }

    private var centerLabel: String {
        if let turn = timer.currentTurnName {
            return "\(timer.label) · \(turn)"
        }
        return timer.label
    }
}

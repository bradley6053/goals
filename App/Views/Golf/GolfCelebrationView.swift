import SwiftUI

/// Presented when a finished round beats the personal best on that course.
struct GolfCelebrationPayload: Identifiable {
    let id = UUID()
    let courseName: String
    let score: Int
    let vsPar: Int
    let previousBest: Int
    let holeCount: Int
}

/// The golf twin of CelebrationView — cream room, a stamp thunking in,
/// confetti in club colors.
struct GolfCelebrationView: View {
    @Environment(\.dismiss) private var dismiss
    let payload: GolfCelebrationPayload

    @State private var revealed = false

    var body: some View {
        ZStack {
            GolfTheme.bg.ignoresSafeArea()

            ConfettiView(particleCount: 70, duration: 2.6)
                .ignoresSafeArea()

            VStack(spacing: 26) {
                Spacer()

                VStack(spacing: 8) {
                    GolfOverline("New course record", color: GolfTheme.flag)
                    Text("\(payload.score)")
                        .font(GolfTheme.display(96))
                        .foregroundStyle(GolfTheme.ink)
                    Text("\(GolfFormat.vsPar(payload.vsPar)) · \(payload.holeCount) holes")
                        .font(GolfTheme.score(16))
                        .foregroundStyle(GolfTheme.inkSoft)
                }
                .opacity(revealed ? 1 : 0)
                .offset(y: revealed ? 0 : 14)

                ZStack {
                    Circle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 3, dash: [7, 5]))
                        .foregroundStyle(GolfTheme.flag)
                    VStack(spacing: 4) {
                        Text("PB")
                            .font(GolfTheme.display(44))
                            .foregroundStyle(GolfTheme.flag)
                        Text("BEATS \(payload.previousBest)")
                            .font(GolfTheme.label(10))
                            .tracking(1.4)
                            .foregroundStyle(GolfTheme.flag.opacity(0.8))
                    }
                }
                .frame(width: 170, height: 170)
                .rotationEffect(.degrees(revealed ? -8 : 20))
                .scaleEffect(revealed ? 1 : 2.2)
                .opacity(revealed ? 1 : 0)

                VStack(spacing: 6) {
                    Text(payload.courseName)
                        .font(GolfTheme.serif(24))
                        .foregroundStyle(GolfTheme.ink)
                        .multilineTextAlignment(.center)
                    Text("Golf is supposed to be fun. That was fun.")
                        .font(.system(size: 15))
                        .foregroundStyle(GolfTheme.inkSoft)
                }
                .opacity(revealed ? 1 : 0)
                .offset(y: revealed ? 0 : 10)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("TO THE 19TH HOLE")
                        .font(GolfTheme.label(14))
                        .tracking(1.4)
                        .foregroundStyle(GolfTheme.card)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(GolfTheme.fairway, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 48)
                .padding(.bottom, 24)
                .opacity(revealed ? 1 : 0)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            Haptics.unlock()
            withAnimation(.spring(duration: 0.7, bounce: 0.4).delay(0.15)) {
                revealed = true
            }
        }
    }
}

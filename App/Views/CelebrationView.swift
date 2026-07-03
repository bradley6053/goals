import SwiftUI

/// Full-screen reward reveal. Dark room, a pulse of accent light, the reward
/// photo scaling in like a title card. Heavy haptics, no confetti.
struct CelebrationView: View {
    @Environment(\.dismiss) private var dismiss
    let payload: CelebrationPayload

    @State private var revealed = false
    @State private var glowPulse = false

    var body: some View {
        let accent = Accent.named(payload.accentName)

        ZStack {
            Color.black.ignoresSafeArea()

            // Ambient light behind the reveal
            RadialGradient(
                colors: [accent.primary.opacity(glowPulse ? 0.45 : 0.2), .clear],
                center: .center, startRadius: 20, endRadius: 420)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true),
                           value: glowPulse)

            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 10) {
                    OverlineText(payload.isGoalComplete ? "Goal complete" : "Milestone unlocked",
                                 color: accent.primary)
                    Text(payload.milestoneLabel)
                        .font(Theme.display(64))
                        .foregroundStyle(Theme.textPrimary)
                        .monospacedDigit()
                }
                .opacity(revealed ? 1 : 0)
                .offset(y: revealed ? 0 : 14)

                RewardImageView(imageFile: payload.rewardImageFile, accent: accent, locked: false,
                                cornerRadius: 28)
                    .frame(width: 260, height: 300)
                    .scaleEffect(revealed ? 1 : 0.7)
                    .opacity(revealed ? 1 : 0)
                    .rotation3DEffect(.degrees(revealed ? 0 : 8), axis: (x: 1, y: 0, z: 0))

                VStack(spacing: 6) {
                    Text(payload.rewardTitle)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.center)
                    Text(payload.isGoalComplete ? "You finished what you started. Go get it."
                                                : "You earned this one. Claim it.")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.textSecondary)
                }
                .opacity(revealed ? 1 : 0)
                .offset(y: revealed ? 0 : 10)

                Spacer()

                EmberButton(title: payload.isGoalComplete ? "Take a bow" : "Back to work",
                            accent: accent) {
                    dismiss()
                }
                .padding(.horizontal, 48)
                .padding(.bottom, 24)
                .opacity(revealed ? 1 : 0)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            glowPulse = true
            Haptics.unlock()
            withAnimation(.spring(duration: 0.9, bounce: 0.35).delay(0.25)) {
                revealed = true
            }
        }
    }
}

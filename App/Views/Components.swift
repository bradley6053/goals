import SwiftUI

/// Gradient progress bar with a soft glow under the filled portion.
struct GlowProgressBar: View {
    let fraction: Double
    let accent: Accent
    var height: CGFloat = 10

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.07))
                Capsule()
                    .fill(accent.gradient)
                    .frame(width: max(height, geo.size.width * fraction))
                    .shadow(color: accent.primary.opacity(0.55), radius: 8, y: 2)
            }
        }
        .frame(height: height)
        .animation(.spring(duration: 0.7), value: fraction)
    }
}

/// Small over-line label, e.g. "NEXT REWARD".
struct OverlineText: View {
    let text: String
    var color: Color = Theme.textTertiary

    init(_ text: String, color: Color = Theme.textTertiary) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text.uppercased())
            .font(Theme.label(11))
            .tracking(1.6)
            .foregroundStyle(color)
    }
}

/// Standard dark card container.
struct EmberCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.radiusCard))
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusCard)
                    .strokeBorder(Theme.stroke, lineWidth: 1)
            )
    }
}

/// Reward photo styled for its state: unlocked photos glow, locked photos
/// sit dim and blurred behind a lock badge — visible enough to want.
struct RewardImageView: View {
    let imageFile: String?
    let accent: Accent
    let locked: Bool
    var cornerRadius: CGFloat = Theme.radiusInner

    var body: some View {
        ZStack {
            if let image = ImageStore.image(imageFile) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Theme.elevated)
                Image(systemName: "gift.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(locked ? AnyShapeStyle(Theme.textTertiary)
                                            : AnyShapeStyle(accent.gradient))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay {
            if locked {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.black.opacity(0.55))
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(locked ? Theme.stroke : accent.primary.opacity(0.45), lineWidth: 1)
        )
        .shadow(color: locked ? .clear : accent.primary.opacity(0.35), radius: 14, y: 4)
        .blur(radius: 0)
        .saturation(locked ? 0.55 : 1)
    }
}

/// Primary action button — gradient fill, condensed uppercase title.
struct EmberButton: View {
    let title: String
    let accent: Accent
    var systemImage: String?
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .bold))
                }
                Text(title.uppercased())
                    .font(Theme.label(14))
                    .tracking(1.2)
            }
            .foregroundStyle(.black.opacity(0.85))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(accent.gradient, in: Capsule())
            .shadow(color: accent.primary.opacity(0.4), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }
}

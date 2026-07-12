import SwiftUI

/// Reflection tab root — the chapel. Candlelit umber world, deliberately
/// the quietest tab in the app: one quote a day, one tap to say you sat
/// with it. The quote is re-derived from the calendar on every render, so
/// midnight rolls the page with no timers or observers.
struct ReflectionHomeView: View {
    @Environment(ReflectionStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header
                    quoteCard
                    checkInButton
                    streakCard
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(ReflectionTheme.bg.ignoresSafeArea())
            .toolbarBackground(ReflectionTheme.card, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .tint(ReflectionTheme.candle)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 6) {
            Text("Daily Reflection".uppercased())
                .font(ReflectionTheme.label(11))
                .tracking(1.6)
                .foregroundStyle(ReflectionTheme.candle)
            Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(ReflectionTheme.serif(17))
                .foregroundStyle(ReflectionTheme.textSecondary)
        }
    }

    // MARK: - Quote of the day

    private var quoteCard: some View {
        let quote = ReflectionMath.quote(on: Date())
        return VStack(alignment: .leading, spacing: 18) {
            Text(quote.category.displayName.uppercased())
                .font(ReflectionTheme.label(11))
                .tracking(1.6)
                .foregroundStyle(ReflectionTheme.candle)

            Text(quote.text)
                .font(ReflectionTheme.quote(26))
                .lineSpacing(6)
                .foregroundStyle(ReflectionTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("— \(quote.attribution)")
                .font(ReflectionTheme.serif(15))
                .foregroundStyle(ReflectionTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: ReflectionTheme.radiusCard, style: .continuous)
                .fill(ReflectionTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: ReflectionTheme.radiusCard,
                                     style: .continuous)
                        .strokeBorder(ReflectionTheme.stroke, lineWidth: 1)
                )
        )
        // The candle: one quiet radial glow bleeding past the card, no motion.
        .background(
            RadialGradient(colors: [ReflectionTheme.glow.opacity(0.18), .clear],
                           center: .center, startRadius: 0, endRadius: 280)
            .padding(-70)
        )
    }

    // MARK: - Check-in

    private var checkInButton: some View {
        Group {
            if store.hasCheckedIn() {
                Button {
                    Haptics.tap()
                    withAnimation(.spring(duration: 0.3)) { store.undoCheckIn() }
                } label: {
                    Label("Reflected today", systemImage: "checkmark")
                        .font(ReflectionTheme.label(14))
                        .foregroundStyle(ReflectionTheme.candle)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule().strokeBorder(
                                ReflectionTheme.candle.opacity(0.45), lineWidth: 1)
                        )
                }
            } else {
                Button {
                    Haptics.success()
                    withAnimation(.spring(duration: 0.3)) { store.checkIn() }
                } label: {
                    Text("I reflected today")
                        .font(ReflectionTheme.label(14))
                        .foregroundStyle(ReflectionTheme.bg)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(ReflectionTheme.candle))
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Streak

    private var streakCard: some View {
        let streak = store.currentStreak()
        let dots = store.recentDays()
        return HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 8) {
                overline("Streak")
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(ReflectionTheme.candle)
                    Text(streak == 1 ? "1 day" : "\(streak) days")
                        .font(ReflectionTheme.serif(20))
                        .foregroundStyle(ReflectionTheme.textPrimary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 10) {
                overline("Last 7 days")
                HStack(spacing: 8) {
                    ForEach(Array(dots.enumerated()), id: \.offset) { _, filled in
                        Circle()
                            .fill(filled ? ReflectionTheme.candle
                                         : ReflectionTheme.textPrimary.opacity(0.12))
                            .frame(width: 10, height: 10)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: ReflectionTheme.radiusCard, style: .continuous)
                .fill(ReflectionTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: ReflectionTheme.radiusCard,
                                     style: .continuous)
                        .strokeBorder(ReflectionTheme.stroke, lineWidth: 1)
                )
        )
    }

    private func overline(_ text: String) -> some View {
        Text(text.uppercased())
            .font(ReflectionTheme.label(11))
            .tracking(1.6)
            .foregroundStyle(ReflectionTheme.textTertiary)
    }
}

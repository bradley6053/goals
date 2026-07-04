import SwiftUI
import SwiftData

/// Hole-by-hole entry: swipe through holes, big steppers, live totals.
/// Committing a birdie-or-better hole earns confetti; streaks earn banners.
struct RoundEntryView: View {
    @Bindable var round: GolfRound
    @Environment(\.modelContext) private var context

    @State private var currentHole = 1
    @State private var confettiTrigger = 0
    @State private var celebration: GolfCelebrationPayload?

    var body: some View {
        VStack(spacing: 0) {
            vibeBanner

            TabView(selection: $currentHole) {
                ForEach(round.orderedScores) { score in
                    HoleEntryCard(score: score,
                                  isLast: score.holeNumber == round.holeCount,
                                  onFinish: finishRound)
                        .tag(score.holeNumber)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onChange(of: currentHole) { previous, _ in
                commitHole(number: previous)
            }

            holeDots
            totalsFooter
        }
        .background(GolfTheme.bg.ignoresSafeArea())
        .navigationTitle(round.course?.name ?? "Round")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GolfTheme.card, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .overlay {
            if confettiTrigger > 0 {
                ConfettiView()
                    .id(confettiTrigger)   // re-fire on every new burst
                    .ignoresSafeArea()
            }
        }
        .fullScreenCover(item: $celebration) { payload in
            GolfCelebrationView(payload: payload)
        }
        .onAppear {
            // Resume where the golfer left off.
            let firstUncommitted = round.orderedScores.first { !$0.committed }
            currentHole = firstUncommitted?.holeNumber ?? round.holeCount
        }
    }

    // MARK: - Pieces

    private var vibeBanner: some View {
        let vibe = GolfMath.vibe(recent: round.committedResults)
        return Group {
            switch vibe {
            case .hot:
                banner("You're cooking. Keep it rolling.", icon: "flame.fill",
                       color: GolfTheme.flag)
            case .cold:
                banner("One hole at a time.", icon: "snowflake",
                       color: GolfTheme.sky)
            case .neutral:
                EmptyView()
            }
        }
    }

    private func banner(_ text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
            Text(text)
                .font(GolfTheme.label(11))
                .tracking(0.6)
        }
        .foregroundStyle(color)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.12))
    }

    private var holeDots: some View {
        HStack(spacing: 5) {
            ForEach(round.orderedScores) { score in
                Circle()
                    .fill(dotColor(score))
                    .frame(width: 7, height: 7)
                    .onTapGesture {
                        withAnimation { currentHole = score.holeNumber }
                    }
            }
        }
        .padding(.vertical, 10)
    }

    private func dotColor(_ score: GolfHoleScore) -> Color {
        if score.holeNumber == currentHole { return GolfTheme.fairway }
        if score.committed {
            switch score.scoreType {
            case .albatross, .eagle, .birdie: return GolfTheme.birdie
            case .par: return GolfTheme.inkSoft
            default: return GolfTheme.bogey.opacity(0.7)
            }
        }
        return GolfTheme.inkFaint.opacity(0.4)
    }

    private var totalsFooter: some View {
        let results = round.committedResults
        return HStack {
            StatTile(value: "\(GolfMath.outTotal(results))", label: "Out")
            if round.holeCount > 9 {
                StatTile(value: "\(GolfMath.inTotal(results))", label: "In")
            }
            StatTile(value: "\(GolfMath.totalStrokes(results))", label: "Total")
            StatTile(value: GolfFormat.vsPar(GolfMath.totalToPar(results)),
                     label: "vs Par",
                     color: GolfMath.totalToPar(results) < 0 ? GolfTheme.birdie : GolfTheme.ink)
            StatTile(value: "\(GolfMath.totalPutts(results))", label: "Putts")
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(GolfTheme.card)
        .overlay(Rectangle().fill(GolfTheme.stroke).frame(height: 1), alignment: .top)
    }

    // MARK: - Actions

    private func commitHole(number: Int) {
        guard let score = round.orderedScores.first(where: { $0.holeNumber == number }),
              !score.committed else { return }
        score.committed = true

        switch score.scoreType {
        case .albatross, .eagle:
            confettiTrigger += 1
            Haptics.unlock()
        case .birdie:
            confettiTrigger += 1
            Haptics.success()
        default:
            break
        }
    }

    private func finishRound() {
        // Commit every hole (including the last one being viewed).
        round.orderedScores.filter { !$0.committed }.forEach { $0.committed = true }

        // Personal best check happens against rounds finished BEFORE this one.
        let previousBest = round.course?.bestScore(holeCount: round.holeCount)

        round.completedAt = Date()
        try? context.save()

        let total = round.totalStrokes
        if let best = previousBest, total < best {
            celebration = GolfCelebrationPayload(
                courseName: round.course?.name ?? "This course",
                score: total,
                vsPar: round.totalToPar,
                previousBest: best,
                holeCount: round.holeCount)
        } else {
            Haptics.success()
        }
        // completedAt is set, so the navigation destination flips this
        // push from entry to RoundSummaryView automatically.
    }
}

// MARK: - Single hole card

private struct HoleEntryCard: View {
    @Bindable var score: GolfHoleScore
    let isLast: Bool
    let onFinish: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            GolfCard {
                VStack(spacing: 18) {
                    header

                    GolfStepper(title: "Strokes", value: $score.strokes, range: 1...15) { value in
                        "\(value)"
                    }

                    vsParReadout

                    Divider().overlay(GolfTheme.stroke)

                    GolfStepper(title: "Putts", value: $score.putts, range: 0...9)

                    if score.par >= 4 {
                        GolfToggle(title: "Fairway hit", isOn: fairwayBinding)
                    }

                    GolfToggle(title: "Green in reg.", isOn: $score.greenInRegulation)

                    GolfStepper(title: "Penalties", value: $score.penalties, range: 0...5)

                    if isLast {
                        finishButton
                    }
                }
                .padding(20)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            GolfOverline("Hole \(score.holeNumber)", color: GolfTheme.sky)
            Text("Par \(score.par)")
                .font(GolfTheme.display(34))
                .foregroundStyle(GolfTheme.ink)
        }
    }

    private var vsParReadout: some View {
        let delta = score.strokes - score.par
        let type = score.scoreType
        return Text(delta == 0 ? "Par" : "\(type.label) · \(GolfFormat.vsPar(delta))")
            .font(GolfTheme.score(15))
            .foregroundStyle(delta < 0 ? GolfTheme.birdie
                             : delta == 0 ? GolfTheme.inkSoft : GolfTheme.bogey)
    }

    private var fairwayBinding: Binding<Bool> {
        Binding(get: { score.fairwayHit ?? false },
                set: { score.fairwayHit = $0 })
    }

    private var finishButton: some View {
        Button {
            onFinish()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 15, weight: .bold))
                Text("FINISH ROUND")
                    .font(GolfTheme.label(14))
                    .tracking(1.4)
            }
            .foregroundStyle(GolfTheme.card)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(GolfTheme.sky, in: Capsule())
        }
        .buttonStyle(.plain)
        .padding(.top, 6)
    }
}

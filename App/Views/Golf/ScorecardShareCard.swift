import SwiftUI

/// Fixed-size render-only scorecard for sharing — cream cardstock, serif
/// course name, the classic grid. Rendered via ImageRenderer at 3x.
struct ScorecardShareCard: View {
    let round: GolfRound

    private var results: [HoleResult] {
        round.orderedScores.map(\.asResult)
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text("· THE GOLF LOG ·")
                    .font(GolfTheme.label(11))
                    .tracking(3.0)
                    .foregroundStyle(GolfTheme.sky)
                Text(round.course?.name ?? "Unknown course")
                    .font(GolfTheme.serif(30))
                    .foregroundStyle(GolfTheme.ink)
                    .multilineTextAlignment(.center)
                Text(round.startedAt.formatted(.dateTime.month(.wide).day().year())
                     + (round.teeName.isEmpty ? "" : " · \(round.teeName) tees"))
                    .font(GolfTheme.label(11))
                    .tracking(1.0)
                    .foregroundStyle(GolfTheme.inkFaint)
            }

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("\(round.totalStrokes)")
                    .font(GolfTheme.display(72))
                    .foregroundStyle(GolfTheme.ink)
                Text(GolfFormat.vsPar(round.totalToPar))
                    .font(GolfTheme.score(30))
                    .foregroundStyle(round.totalToPar < 0 ? GolfTheme.birdie : GolfTheme.flag)
            }

            ScorecardGrid(results: results)

            HStack(spacing: 24) {
                shareStat("\(GolfMath.totalPutts(results))", "PUTTS")
                shareStat(GolfFormat.percent(GolfMath.firPercent(results)), "FAIRWAYS")
                shareStat(GolfFormat.percent(GolfMath.girPercent(results)), "GREENS")
            }

            Text("Golf is supposed to be fun.")
                .font(GolfTheme.serif(14))
                .italic()
                .foregroundStyle(GolfTheme.inkFaint)
        }
        .padding(28)
        .frame(width: 420)
        .background(GolfTheme.bg)
    }

    private func shareStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(GolfTheme.score(20))
                .foregroundStyle(GolfTheme.ink)
            Text(label)
                .font(GolfTheme.label(9))
                .tracking(1.2)
                .foregroundStyle(GolfTheme.inkFaint)
        }
    }
}

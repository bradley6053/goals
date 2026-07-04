import SwiftUI
import SwiftData

/// Post-round scorecard: classic grid, stat chips, distribution, share.
struct RoundSummaryView: View {
    let round: GolfRound

    @State private var shareImage: Image?

    private var results: [HoleResult] {
        round.orderedScores.map(\.asResult)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                scorecardCard
                statsCard
                distributionCard
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(GolfTheme.bg.ignoresSafeArea())
        .navigationTitle("Scorecard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GolfTheme.card, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let shareImage {
                    ShareLink(
                        item: shareImage,
                        preview: SharePreview(
                            "\(round.course?.name ?? "Round") — \(round.totalStrokes)",
                            image: shareImage)) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(GolfTheme.sky)
                    }
                }
            }
        }
        .onAppear(perform: renderShareCard)
    }

    private var headerCard: some View {
        GolfCard {
            VStack(spacing: 8) {
                GolfOverline(round.startedAt.formatted(
                    .dateTime.weekday(.wide).month(.abbreviated).day()),
                    color: GolfTheme.sky)
                Text(round.course?.name ?? "Unknown course")
                    .font(GolfTheme.serif(24))
                    .foregroundStyle(GolfTheme.ink)
                    .multilineTextAlignment(.center)

                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("\(round.totalStrokes)")
                        .font(GolfTheme.display(58))
                        .foregroundStyle(GolfTheme.ink)
                    Text(GolfFormat.vsPar(round.totalToPar))
                        .font(GolfTheme.score(24))
                        .foregroundStyle(round.totalToPar < 0 ? GolfTheme.birdie : GolfTheme.flag)
                }

                if !round.teeName.isEmpty {
                    Text("\(round.teeName) tees · \(round.holeCount) holes")
                        .font(GolfTheme.label(10))
                        .tracking(1.0)
                        .foregroundStyle(GolfTheme.inkFaint)
                }

                if isCourseRecord {
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                        Text("COURSE RECORD")
                            .tracking(1.4)
                    }
                    .font(GolfTheme.label(11))
                    .foregroundStyle(GolfTheme.gold)
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
        }
        .padding(.top, 12)
    }

    private var isCourseRecord: Bool {
        round.course?.bestScore(holeCount: round.holeCount) == round.totalStrokes
    }

    private var scorecardCard: some View {
        GolfCard {
            VStack(spacing: 12) {
                GolfOverline("The card")
                ScorecardGrid(results: results)
            }
            .padding(16)
        }
    }

    private var statsCard: some View {
        GolfCard {
            VStack(spacing: 14) {
                GolfOverline("The numbers")
                HStack {
                    StatTile(value: "\(GolfMath.totalPutts(results))", label: "Putts")
                    StatTile(value: GolfFormat.percent(GolfMath.firPercent(results)),
                             label: "Fairways")
                    StatTile(value: GolfFormat.percent(GolfMath.girPercent(results)),
                             label: "Greens")
                }
                HStack {
                    StatTile(value: "\(GolfMath.threePuttCount(results))", label: "3-putts")
                    StatTile(value: "\(GolfMath.totalPenalties(results))", label: "Penalties")
                    StatTile(value: "\(GolfMath.longestBirdieStreak(results))",
                             label: "Birdie streak")
                }
            }
            .padding(16)
        }
    }

    private var distributionCard: some View {
        let dist = GolfMath.distribution(results)
        let shown: [ScoreType] = [.eagle, .birdie, .par, .bogey, .doubleBogey, .worse]
        let maxCount = shown.compactMap { dist[$0] }.max() ?? 1

        return GolfCard {
            VStack(spacing: 10) {
                GolfOverline("How it happened")
                ForEach(shown, id: \.rawValue) { type in
                    let count = dist[type] ?? 0
                    HStack(spacing: 10) {
                        Text(type.label.uppercased())
                            .font(GolfTheme.label(9))
                            .tracking(0.8)
                            .foregroundStyle(GolfTheme.inkSoft)
                            .frame(width: 64, alignment: .leading)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(GolfTheme.sand.opacity(0.5))
                                Capsule()
                                    .fill(barColor(type))
                                    .frame(width: count == 0 ? 0
                                           : max(12, geo.size.width * Double(count) / Double(maxCount)))
                            }
                        }
                        .frame(height: 12)
                        Text("\(count)")
                            .font(GolfTheme.score(13))
                            .foregroundStyle(GolfTheme.ink)
                            .frame(width: 22, alignment: .trailing)
                    }
                }
            }
            .padding(16)
        }
    }

    private func barColor(_ type: ScoreType) -> Color {
        switch type {
        case .albatross, .eagle, .birdie: return GolfTheme.birdie
        case .par: return GolfTheme.fairway
        case .bogey: return GolfTheme.bogey.opacity(0.75)
        case .doubleBogey, .worse: return GolfTheme.bogey
        }
    }

    private func renderShareCard() {
        let card = ScorecardShareCard(round: round)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        if let uiImage = renderer.uiImage {
            shareImage = Image(uiImage: uiImage)
        }
    }
}

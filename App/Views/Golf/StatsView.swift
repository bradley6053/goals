import SwiftUI
import SwiftData

/// All-time numbers across every completed round. 9- and 18-hole scoring
/// averages stay separate — no fudged normalization.
struct StatsView: View {
    @Query(filter: #Predicate<GolfRound> { $0.completedAt != nil },
           sort: \GolfRound.startedAt, order: .reverse)
    private var rounds: [GolfRound]

    private var allResults: [HoleResult] {
        rounds.flatMap(\.committedResults)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if rounds.isEmpty {
                    emptyState
                } else {
                    scoringCard
                    perRoundCard
                    holesCard
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(GolfTheme.bg.ignoresSafeArea())
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GolfTheme.card, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar")
                .font(.system(size: 34))
                .foregroundStyle(GolfTheme.inkFaint)
            Text("Numbers show up after your first round.")
                .font(.system(size: 15))
                .foregroundStyle(GolfTheme.inkSoft)
        }
        .padding(.top, 80)
    }

    private var scoringCard: some View {
        let eighteens = rounds.filter { $0.holeCount == 18 }.map(\.totalStrokes)
        let nines = rounds.filter { $0.holeCount == 9 }.map(\.totalStrokes)

        return GolfCard {
            VStack(spacing: 14) {
                GolfOverline("Scoring average")
                HStack {
                    StatTile(value: GolfFormat.average(GolfMath.scoringAverage(totals: eighteens)),
                             label: "18 holes (\(eighteens.count))")
                    StatTile(value: GolfFormat.average(GolfMath.scoringAverage(totals: nines)),
                             label: "9 holes (\(nines.count))")
                }
            }
            .padding(16)
        }
        .padding(.top, 12)
    }

    private var perRoundCard: some View {
        let perRound = rounds.map(\.committedResults)
        let puttsPerRound = GolfMath.scoringAverage(totals: perRound.map { GolfMath.totalPutts($0) })
        let threePutts = perRound.map { GolfMath.threePuttCount($0) }.reduce(0, +)
        let penalties = perRound.map { GolfMath.totalPenalties($0) }.reduce(0, +)

        return GolfCard {
            VStack(spacing: 14) {
                GolfOverline("Per round")
                HStack {
                    StatTile(value: GolfFormat.average(puttsPerRound), label: "Putts")
                    StatTile(value: "\(threePutts)", label: "3-putts total")
                    StatTile(value: "\(penalties)", label: "Penalties total")
                }
            }
            .padding(16)
        }
    }

    private var holesCard: some View {
        let dist = GolfMath.distribution(allResults)
        let birdiesOrBetter = (dist[.albatross] ?? 0) + (dist[.eagle] ?? 0) + (dist[.birdie] ?? 0)

        return GolfCard {
            VStack(spacing: 14) {
                GolfOverline("Ball striking")
                HStack {
                    StatTile(value: GolfFormat.percent(GolfMath.firPercent(allResults)),
                             label: "Fairways")
                    StatTile(value: GolfFormat.percent(GolfMath.girPercent(allResults)),
                             label: "Greens")
                    StatTile(value: "\(birdiesOrBetter)", label: "Birdies+",
                             color: GolfTheme.birdie)
                }
                HStack {
                    StatTile(value: "\(dist[.par] ?? 0)", label: "Pars")
                    StatTile(value: "\(dist[.bogey] ?? 0)", label: "Bogeys")
                    StatTile(value: "\((dist[.doubleBogey] ?? 0) + (dist[.worse] ?? 0))",
                             label: "Doubles+")
                }
            }
            .padding(16)
        }
    }
}

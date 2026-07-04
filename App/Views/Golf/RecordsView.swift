import SwiftUI
import SwiftData

/// Trophy wall — best score on every course you've played, plus the
/// longest birdie streak you've ever put together.
struct RecordsView: View {
    @Query(sort: \GolfCourse.name) private var courses: [GolfCourse]

    private var playedCourses: [GolfCourse] {
        courses.filter { !$0.completedRounds.isEmpty }
    }

    private var longestStreak: (length: Int, course: String)? {
        let best = playedCourses
            .flatMap(\.completedRounds)
            .map { round in
                (length: GolfMath.longestBirdieStreak(round.committedResults),
                 course: round.course?.name ?? "")
            }
            .max { $0.length < $1.length }
        guard let best, best.length > 0 else { return nil }
        return best
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if playedCourses.isEmpty {
                    emptyState
                } else {
                    if let streak = longestStreak {
                        streakCard(streak)
                    }
                    ForEach(playedCourses) { course in
                        recordCard(course)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(GolfTheme.bg.ignoresSafeArea())
        .navigationTitle("Records")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GolfTheme.card, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "trophy")
                .font(.system(size: 34))
                .foregroundStyle(GolfTheme.inkFaint)
            Text("Finish a round to hang your first trophy.")
                .font(.system(size: 15))
                .foregroundStyle(GolfTheme.inkSoft)
        }
        .padding(.top, 80)
    }

    private func streakCard(_ streak: (length: Int, course: String)) -> some View {
        GolfCard {
            HStack(spacing: 16) {
                Image(systemName: "bird.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(GolfTheme.birdie)
                VStack(alignment: .leading, spacing: 3) {
                    GolfOverline("Longest birdie streak", color: GolfTheme.sky)
                    Text("\(streak.length) in a row")
                        .font(GolfTheme.serif(22))
                        .foregroundStyle(GolfTheme.ink)
                    if !streak.course.isEmpty {
                        Text(streak.course)
                            .font(GolfTheme.label(10))
                            .foregroundStyle(GolfTheme.inkFaint)
                    }
                }
                Spacer()
            }
            .padding(16)
        }
        .padding(.top, 12)
    }

    private func recordCard(_ course: GolfCourse) -> some View {
        GolfCard {
            HStack(spacing: 14) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(GolfTheme.gold)

                VStack(alignment: .leading, spacing: 3) {
                    Text(course.name)
                        .font(GolfTheme.serif(17))
                        .foregroundStyle(GolfTheme.ink)
                        .lineLimit(1)
                    Text("\(course.completedRounds.count) round\(course.completedRounds.count == 1 ? "" : "s") played")
                        .font(GolfTheme.label(10))
                        .foregroundStyle(GolfTheme.inkFaint)
                }
                Spacer()

                HStack(spacing: 14) {
                    if let best18 = course.bestScore(holeCount: 18) {
                        bestBadge(best18, label: "18")
                    }
                    if let best9 = course.bestScore(holeCount: 9) {
                        bestBadge(best9, label: "9")
                    }
                }
            }
            .padding(16)
        }
    }

    private func bestBadge(_ score: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(score)")
                .font(GolfTheme.score(22))
                .foregroundStyle(GolfTheme.ink)
            Text("\(label) HOLES")
                .font(GolfTheme.label(8))
                .tracking(0.8)
                .foregroundStyle(GolfTheme.inkFaint)
        }
    }
}

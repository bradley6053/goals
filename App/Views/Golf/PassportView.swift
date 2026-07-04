import SwiftUI
import SwiftData
import MapKit

/// Course passport — a stamp for every course you've played, milestone
/// progress, and a pin map of everywhere golf has taken you.
struct PassportView: View {
    @Query(sort: \GolfCourse.name) private var courses: [GolfCourse]

    private var playedCourses: [GolfCourse] {
        courses
            .filter { !$0.completedRounds.isEmpty }
            .sorted { firstPlayed($0) < firstPlayed($1) }
    }

    private func firstPlayed(_ course: GolfCourse) -> Date {
        course.completedRounds.map(\.startedAt).min() ?? course.addedAt
    }

    private let milestones = [5, 10, 25]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if playedCourses.isEmpty {
                    emptyState
                } else {
                    stampsCard
                    milestoneCard
                    mapCard
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(GolfTheme.bg.ignoresSafeArea())
        .navigationTitle("Passport")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GolfTheme.card, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "map")
                .font(.system(size: 34))
                .foregroundStyle(GolfTheme.inkFaint)
            Text("Your passport gets its first stamp\nafter your first round.")
                .font(.system(size: 15))
                .foregroundStyle(GolfTheme.inkSoft)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 80)
    }

    private var stampsCard: some View {
        GolfCard {
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    GolfOverline("Course passport", color: GolfTheme.sky)
                    Text("\(playedCourses.count) course\(playedCourses.count == 1 ? "" : "s") played")
                        .font(GolfTheme.serif(20))
                        .foregroundStyle(GolfTheme.ink)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 86), spacing: 12)],
                          spacing: 16) {
                    ForEach(playedCourses) { course in
                        StampView(courseName: course.name,
                                  state: course.state.isEmpty ? "—" : course.state,
                                  date: firstPlayed(course),
                                  color: stampColor(for: course))
                    }
                    // The next empty slot — something to chase.
                    nextSlot
                }
            }
            .padding(16)
        }
        .padding(.top, 12)
    }

    private var nextSlot: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [3, 5]))
                    .foregroundStyle(GolfTheme.inkFaint.opacity(0.5))
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(GolfTheme.inkFaint.opacity(0.6))
            }
            .frame(width: 76, height: 76)
            Text("NEXT")
                .font(GolfTheme.label(9))
                .tracking(1.0)
                .foregroundStyle(GolfTheme.inkFaint.opacity(0.6))
        }
    }

    private func stampColor(for course: GolfCourse) -> Color {
        let palette = [GolfTheme.fairway, GolfTheme.sky, GolfTheme.flag, GolfTheme.gold]
        return palette[abs(course.name.hashValue) % palette.count]
    }

    private var milestoneCard: some View {
        GolfCard {
            VStack(spacing: 12) {
                GolfOverline("Milestones")
                HStack(spacing: 10) {
                    ForEach(milestones, id: \.self) { target in
                        let reached = playedCourses.count >= target
                        VStack(spacing: 5) {
                            Image(systemName: reached ? "medal.fill" : "medal")
                                .font(.system(size: 22))
                                .foregroundStyle(reached ? GolfTheme.gold : GolfTheme.inkFaint)
                            Text("\(target) COURSES")
                                .font(GolfTheme.label(8))
                                .tracking(0.8)
                                .foregroundStyle(reached ? GolfTheme.ink : GolfTheme.inkFaint)
                            if !reached {
                                Text("\(playedCourses.count)/\(target)")
                                    .font(GolfTheme.score(11))
                                    .foregroundStyle(GolfTheme.inkFaint)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(16)
        }
    }

    private var mapCard: some View {
        let pinned = playedCourses.filter { $0.latitude != nil && $0.longitude != nil }

        return GolfCard {
            VStack(spacing: 12) {
                GolfOverline("Everywhere golf has taken you")
                if pinned.isEmpty {
                    Text("No course locations yet.")
                        .font(.system(size: 14))
                        .foregroundStyle(GolfTheme.inkSoft)
                        .padding(.vertical, 24)
                } else {
                    Map(initialPosition: .automatic) {
                        ForEach(pinned) { course in
                            Marker(course.name, systemImage: "flag.fill",
                                   coordinate: CLLocationCoordinate2D(
                                       latitude: course.latitude ?? 0,
                                       longitude: course.longitude ?? 0))
                                .tint(GolfTheme.fairway)
                        }
                    }
                    .mapStyle(.standard(pointsOfInterest: .excludingAll))
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: GolfTheme.radiusInner))
                }
            }
            .padding(16)
        }
    }
}

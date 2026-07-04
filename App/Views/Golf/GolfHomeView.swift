import SwiftUI
import SwiftData

/// Pages reachable from the golf home screen.
enum GolfPage: Hashable {
    case stats, records, passport
}

/// Golf tab root — the clubhouse. Cream Sweetens Cove world, completely
/// different personality from the dark Goals tab.
struct GolfHomeView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<GolfRound> { $0.completedAt == nil },
           sort: \GolfRound.startedAt, order: .reverse)
    private var inProgressRounds: [GolfRound]

    @Query(filter: #Predicate<GolfRound> { $0.completedAt != nil },
           sort: \GolfRound.startedAt, order: .reverse)
    private var completedRounds: [GolfRound]

    @State private var path = NavigationPath()
    @State private var showingNewRound = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 16) {
                    header

                    if let live = inProgressRounds.first {
                        resumeCard(live)
                    }

                    teeItUpButton

                    quickLinks

                    if !completedRounds.isEmpty {
                        recentRounds
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(GolfTheme.bg.ignoresSafeArea())
            .toolbarBackground(GolfTheme.card, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            // The app forces dark mode; the golf world is cream, so nav bar
            // text/buttons must flip to light-scheme (dark ink) rendering.
            .toolbarColorScheme(.light, for: .navigationBar)
            .tint(GolfTheme.sky)
            .navigationDestination(for: GolfRound.self) { round in
                // One destination for both states: entry flips to summary the
                // moment the round is finished (models are Observable).
                Group {
                    if round.isComplete {
                        RoundSummaryView(round: round)
                    } else {
                        RoundEntryView(round: round)
                    }
                }
            }
            .navigationDestination(for: GolfPage.self) { page in
                switch page {
                case .stats: StatsView()
                case .records: RecordsView()
                case .passport: PassportView()
                }
            }
            .sheet(isPresented: $showingNewRound) {
                CourseSearchSheet { round in
                    showingNewRound = false
                    path.append(round)
                }
            }
            .onAppear(perform: openDebugScreen)
        }
    }

    /// GOLF_OPEN env var jumps straight to a screen — simulator
    /// screenshots only (launched via SIMCTL_CHILD_GOLF_OPEN).
    private func openDebugScreen() {
        switch ProcessInfo.processInfo.environment["GOLF_OPEN"] {
        case "round": inProgressRounds.first.map { path.append($0) }
        case "summary": completedRounds.first.map { path.append($0) }
        case "stats": path.append(GolfPage.stats)
        case "records": path.append(GolfPage.records)
        case "passport": path.append(GolfPage.passport)
        case "search": showingNewRound = true
        default: break
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            GolfOverline("It's different here", color: GolfTheme.sky)
            Text("The Golf Log")
                .font(GolfTheme.serif(36))
                .foregroundStyle(GolfTheme.ink)
            Text("Golf is supposed to be fun.")
                .font(GolfTheme.label(11))
                .tracking(1.2)
                .foregroundStyle(GolfTheme.inkFaint)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }

    private func resumeCard(_ round: GolfRound) -> some View {
        Button {
            path.append(round)
        } label: {
            GolfCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        GolfOverline("Round in progress", color: GolfTheme.flag)
                        Text(round.course?.name ?? "Unknown course")
                            .font(GolfTheme.serif(19))
                            .foregroundStyle(GolfTheme.ink)
                        Text("Thru \(round.holesPlayed) · \(GolfFormat.vsPar(round.totalToPar))")
                            .font(GolfTheme.score(14))
                            .foregroundStyle(GolfTheme.inkSoft)
                    }
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(GolfTheme.flag)
                }
                .padding(16)
            }
        }
        .buttonStyle(.plain)
    }

    private var teeItUpButton: some View {
        Button {
            Haptics.tap()
            showingNewRound = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "figure.golf")
                    .font(.system(size: 16, weight: .bold))
                Text("TEE IT UP")
                    .font(GolfTheme.label(14))
                    .tracking(1.4)
            }
            .foregroundStyle(GolfTheme.card)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(GolfTheme.fairway, in: Capsule())
            .shadow(color: GolfTheme.fairway.opacity(0.35), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var quickLinks: some View {
        HStack(spacing: 10) {
            quickLink("Stats", icon: "chart.bar.fill", page: .stats)
            quickLink("Records", icon: "trophy.fill", page: .records)
            quickLink("Passport", icon: "map.fill", page: .passport)
        }
    }

    private func quickLink(_ title: String, icon: String, page: GolfPage) -> some View {
        Button {
            path.append(page)
        } label: {
            GolfCard {
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(GolfTheme.sky)
                    Text(title.uppercased())
                        .font(GolfTheme.label(10))
                        .tracking(1.0)
                        .foregroundStyle(GolfTheme.inkSoft)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
        }
        .buttonStyle(.plain)
    }

    private var recentRounds: some View {
        VStack(alignment: .leading, spacing: 10) {
            GolfOverline("Recent rounds")
                .padding(.leading, 4)

            ForEach(completedRounds.prefix(10)) { round in
                Button {
                    path.append(round)
                } label: {
                    GolfCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(round.course?.name ?? "Unknown course")
                                    .font(GolfTheme.serif(16))
                                    .foregroundStyle(GolfTheme.ink)
                                    .lineLimit(1)
                                Text(round.startedAt, format: .dateTime.month(.abbreviated).day().year())
                                    .font(GolfTheme.label(10))
                                    .foregroundStyle(GolfTheme.inkFaint)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 3) {
                                Text("\(round.totalStrokes)")
                                    .font(GolfTheme.score(22))
                                    .foregroundStyle(GolfTheme.ink)
                                Text(GolfFormat.vsPar(round.totalToPar))
                                    .font(GolfTheme.score(12))
                                    .foregroundStyle(round.totalToPar < 0 ? GolfTheme.birdie : GolfTheme.inkSoft)
                            }
                        }
                        .padding(14)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

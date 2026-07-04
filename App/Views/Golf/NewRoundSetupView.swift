import SwiftUI
import SwiftData

/// Pick a tee and round length, then head to the first tee. Creates the
/// round with score rows pre-seeded to par so entry is fast.
struct NewRoundSetupView: View {
    let course: GolfCourse
    let onStart: (GolfRound) -> Void

    @Environment(\.modelContext) private var context
    @State private var selectedTee: GolfTee?
    @State private var holeCount = 18
    @State private var editingCourse = false

    private var canPlayEighteen: Bool { course.holeCount >= 18 }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                courseCard

                if !course.tees.isEmpty {
                    teePicker
                }

                if canPlayEighteen {
                    lengthPicker
                }

                startButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(GolfTheme.bg.ignoresSafeArea())
        .navigationTitle("New round")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editingCourse = true
                } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(GolfTheme.sky)
                }
            }
        }
        .sheet(isPresented: $editingCourse) {
            CourseEditSheet(course: course)
        }
        .onAppear {
            holeCount = min(course.holeCount, 18) == 9 ? 9 : 18
            if selectedTee == nil {
                selectedTee = course.tees.sorted { ($0.yardage ?? 0) > ($1.yardage ?? 0) }
                    .dropFirst(course.tees.count / 2).first ?? course.tees.first
            }
        }
    }

    private var courseCard: some View {
        GolfCard {
            VStack(spacing: 6) {
                GolfOverline("The course", color: GolfTheme.sky)
                Text(course.name)
                    .font(GolfTheme.serif(24))
                    .foregroundStyle(GolfTheme.ink)
                    .multilineTextAlignment(.center)
                let location = [course.city, course.state]
                    .filter { !$0.isEmpty }.joined(separator: ", ")
                if !location.isEmpty {
                    Text(location)
                        .font(GolfTheme.label(10))
                        .tracking(0.8)
                        .foregroundStyle(GolfTheme.inkFaint)
                }
                Text("\(course.holeCount) holes · Par \(course.par)"
                     + (course.totalYardage.map { " · \($0) yds" } ?? ""))
                    .font(GolfTheme.label(11))
                    .tracking(0.8)
                    .foregroundStyle(GolfTheme.inkSoft)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
        }
        .padding(.top, 12)
    }

    private var teePicker: some View {
        GolfCard {
            VStack(alignment: .leading, spacing: 10) {
                GolfOverline("Tees")
                ForEach(course.tees.sorted { ($0.yardage ?? 0) > ($1.yardage ?? 0) }) { tee in
                    Button {
                        Haptics.tap()
                        selectedTee = tee
                    } label: {
                        HStack {
                            Image(systemName: selectedTee === tee
                                  ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(GolfTheme.fairway)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tee.teeName + (tee.gender == "Female" ? " (W)" : ""))
                                    .font(GolfTheme.score(15))
                                    .foregroundStyle(GolfTheme.ink)
                                Text(teeDetail(tee))
                                    .font(GolfTheme.label(9))
                                    .foregroundStyle(GolfTheme.inkFaint)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
    }

    private func teeDetail(_ tee: GolfTee) -> String {
        var parts: [String] = []
        if let yardage = tee.yardage { parts.append("\(yardage) yds") }
        if let rating = tee.courseRating { parts.append(String(format: "%.1f", rating)) }
        if let slope = tee.slope { parts.append("slope \(slope)") }
        return parts.isEmpty ? "No rating data" : parts.joined(separator: " · ")
    }

    private var lengthPicker: some View {
        GolfCard {
            VStack(spacing: 12) {
                GolfOverline("Round length")
                Picker("Holes", selection: $holeCount) {
                    Text("Front 9").tag(9)
                    Text("18 holes").tag(18)
                }
                .pickerStyle(.segmented)
            }
            .padding(16)
        }
    }

    private var startButton: some View {
        Button {
            start()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "flag.fill")
                    .font(.system(size: 15, weight: .bold))
                Text("TO THE FIRST TEE")
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
        .padding(.top, 8)
    }

    private func start() {
        let round = GolfRound(holeCount: holeCount,
                              teeName: selectedTee?.teeName ?? "",
                              courseRating: selectedTee?.courseRating,
                              slope: selectedTee?.slope)
        round.course = course

        let holesByNumber = Dictionary(uniqueKeysWithValues:
            course.orderedHoles.map { ($0.number, $0) })
        round.scores = (1...holeCount).map { number in
            let par = holesByNumber[number]?.par ?? 4
            let score = GolfHoleScore(holeNumber: number, par: par)
            // No fairway to hit on a par 3 — keep FIR stats honest.
            score.fairwayHit = par >= 4 ? false : nil
            return score
        }

        context.insert(round)
        Haptics.firm()
        onStart(round)
    }
}

import SwiftUI
import SwiftData

/// Fallback for courses the API doesn't know (or knows without hole data):
/// name it, pick 9 or 18, set par per hole, done.
struct ManualCourseEntryView: View {
    var prefillName: String = ""
    let onSave: (GolfCourse) -> Void

    @Environment(\.modelContext) private var context
    @State private var name = ""
    @State private var city = ""
    @State private var state = "IN"
    @State private var holeCount = 18
    @State private var pars: [Int] = Array(repeating: 4, count: 18)

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                GolfCard {
                    VStack(spacing: 12) {
                        field("Course name", text: $name)
                        HStack(spacing: 12) {
                            field("City", text: $city)
                            field("State", text: $state)
                                .frame(width: 90)
                        }
                    }
                    .padding(16)
                }

                GolfCard {
                    VStack(spacing: 12) {
                        GolfOverline("Holes")
                        Picker("Holes", selection: $holeCount) {
                            Text("9").tag(9)
                            Text("18").tag(18)
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(16)
                }

                GolfCard {
                    VStack(spacing: 4) {
                        GolfOverline("Par per hole")
                            .padding(.bottom, 8)
                        ForEach(0..<holeCount, id: \.self) { index in
                            HStack {
                                Text("Hole \(index + 1)")
                                    .font(GolfTheme.score(14))
                                    .foregroundStyle(GolfTheme.inkSoft)
                                Spacer()
                                Picker("Par", selection: $pars[index]) {
                                    ForEach(3...5, id: \.self) { par in
                                        Text("\(par)").tag(par)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 140)
                            }
                            .padding(.vertical, 2)
                        }
                        HStack {
                            GolfOverline("Total par")
                            Spacer()
                            Text("\(pars.prefix(holeCount).reduce(0, +))")
                                .font(GolfTheme.score(18))
                                .foregroundStyle(GolfTheme.ink)
                        }
                        .padding(.top, 10)
                    }
                    .padding(16)
                }

                Button {
                    save()
                } label: {
                    Text("SAVE COURSE")
                        .font(GolfTheme.label(14))
                        .tracking(1.4)
                        .foregroundStyle(GolfTheme.card)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(name.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? AnyShapeStyle(GolfTheme.inkFaint)
                                    : AnyShapeStyle(GolfTheme.fairway),
                                    in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(GolfTheme.bg.ignoresSafeArea())
        .navigationTitle("New course")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if name.isEmpty { name = prefillName }
        }
    }

    private func field(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(.system(size: 16))
            .foregroundStyle(GolfTheme.ink)
            .padding(12)
            .background(GolfTheme.bg, in: RoundedRectangle(cornerRadius: GolfTheme.radiusInner))
    }

    private func save() {
        let activePars = Array(pars.prefix(holeCount))
        let course = GolfCourse(
            name: name.trimmingCharacters(in: .whitespaces),
            city: city.trimmingCharacters(in: .whitespaces),
            state: state.trimmingCharacters(in: .whitespaces).uppercased(),
            holeCount: holeCount,
            par: activePars.reduce(0, +))
        course.holes = activePars.enumerated().map { index, par in
            GolfHole(number: index + 1, par: par)
        }
        context.insert(course)
        GolfCourseImporter.geocodeIfNeeded(course)
        Haptics.success()
        onSave(course)
    }
}

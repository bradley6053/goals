import SwiftUI
import SwiftData

/// Fix a cached course's name/city/state — the API's location data is
/// occasionally wrong even when the scorecard is right (looking at you,
/// "Winterrowd, IL"). Saving re-geocodes so the passport pin moves too.
struct CourseEditSheet: View {
    let course: GolfCourse

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var city = ""
    @State private var state = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    GolfCard {
                        VStack(spacing: 12) {
                            GolfOverline("Course info")
                            field("Course name", text: $name)
                            HStack(spacing: 12) {
                                field("City", text: $city)
                                field("State", text: $state)
                                    .frame(width: 90)
                            }
                        }
                        .padding(16)
                    }

                    Text("Scores and scorecard data stay untouched — this only fixes the name and where the course shows up on your passport map.")
                        .font(.system(size: 13))
                        .foregroundStyle(GolfTheme.inkSoft)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)

                    Button {
                        save()
                    } label: {
                        Text("SAVE")
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
                .padding(.top, 12)
            }
            .background(GolfTheme.bg.ignoresSafeArea())
            .navigationTitle("Fix course info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .tint(GolfTheme.sky)
                }
            }
        }
        .preferredColorScheme(.light)
        .presentationDetents([.medium])
        .onAppear {
            name = course.name
            city = course.city
            state = course.state
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
        course.name = name.trimmingCharacters(in: .whitespaces)
        course.city = city.trimmingCharacters(in: .whitespaces)
        course.state = state.trimmingCharacters(in: .whitespaces).uppercased()
        // Drop the old (possibly wrong) coordinates and geocode fresh from
        // the corrected city/state so the passport pin lands right.
        course.latitude = nil
        course.longitude = nil
        GolfCourseImporter.geocodeIfNeeded(course)
        Haptics.success()
        dismiss()
    }
}

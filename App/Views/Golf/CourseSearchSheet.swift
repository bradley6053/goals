import SwiftUI
import SwiftData

/// Course picker: cached courses up top, live OpenGolfAPI search below,
/// manual entry as the escape hatch. Selecting a course pushes round setup;
/// starting the round hands it back to the home screen via `onStart`.
struct CourseSearchSheet: View {
    let onStart: (GolfRound) -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \GolfCourse.addedAt, order: .reverse)
    private var cachedCourses: [GolfCourse]

    @State private var query = ""
    @State private var results: [CourseSummaryDTO] = []
    @State private var searchState: SearchState = .idle
    @State private var path = NavigationPath()
    @State private var loadingCourseID: String?
    @State private var searchTask: Task<Void, Never>?
    @State private var editingCourse: GolfCourse?

    private enum SearchState: Equatable {
        case idle, loading, loaded, empty
        case failed(String)
    }

    private enum SearchRoute: Hashable {
        case manualEntry
    }

    private let client = GolfAPIClient()

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 16) {
                    searchField

                    switch searchState {
                    case .loading:
                        EmptyView() // spinner lives in the search field
                    case .failed(let message):
                        statusText(message, color: GolfTheme.flag)
                    case .empty:
                        statusText("No courses found — try the city name, or add it manually below.")
                    case .idle, .loaded:
                        EmptyView()
                    }

                    if !results.isEmpty {
                        resultsSection
                    }

                    if !cachedCourses.isEmpty && results.isEmpty && searchState != .loading {
                        cachedSection
                    }

                    manualEntryLink
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(GolfTheme.bg.ignoresSafeArea())
            .navigationTitle("Pick a course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .tint(GolfTheme.sky)
                }
            }
            .navigationDestination(for: GolfCourse.self) { course in
                NewRoundSetupView(course: course, onStart: onStart)
            }
            .navigationDestination(for: SearchRoute.self) { _ in
                ManualCourseEntryView(prefillName: query) { course in
                    path.append(course)
                }
            }
            .sheet(item: $editingCourse) { course in
                CourseEditSheet(course: course)
            }
        }
        .preferredColorScheme(.light)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(GolfTheme.inkFaint)
            TextField("Course name…", text: $query)
                .font(.system(size: 16))
                .foregroundStyle(GolfTheme.ink)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit {
                    searchTask?.cancel()
                    Task { await search() }
                }
                .onChange(of: query) { _, newValue in
                    scheduleSearch(for: newValue)
                }
            if searchState == .loading {
                ProgressView().tint(GolfTheme.fairway)
            } else if !query.isEmpty {
                Button {
                    searchTask?.cancel()
                    query = ""
                    results = []
                    searchState = .idle
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(GolfTheme.inkFaint)
                }
            }
        }
        .padding(14)
        .background(GolfTheme.card, in: RoundedRectangle(cornerRadius: GolfTheme.radiusInner))
        .overlay(
            RoundedRectangle(cornerRadius: GolfTheme.radiusInner)
                .strokeBorder(GolfTheme.stroke, lineWidth: 1)
        )
        .padding(.top, 12)
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            GolfOverline("Search results").padding(.leading, 4)
            ForEach(results) { summary in
                Button {
                    Task { await select(summary) }
                } label: {
                    courseRow(name: summary.displayName,
                              subtitle: summary.location,
                              detail: summary.par.map { "Par \($0)" },
                              loading: loadingCourseID == summary.id)
                }
                .buttonStyle(.plain)
                .disabled(loadingCourseID != nil)
            }
        }
    }

    private var cachedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            GolfOverline("Your courses").padding(.leading, 4)
            ForEach(cachedCourses) { course in
                Button {
                    path.append(course)
                } label: {
                    courseRow(name: course.name,
                              subtitle: [course.city, course.state]
                                .filter { !$0.isEmpty }.joined(separator: ", "),
                              detail: "Par \(course.par)",
                              loading: false)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button {
                        editingCourse = course
                    } label: {
                        Label("Fix course info", systemImage: "pencil")
                    }
                }
            }
            Text("Wrong city or state? Press and hold a course to fix it.")
                .font(GolfTheme.label(10))
                .foregroundStyle(GolfTheme.inkFaint)
                .frame(maxWidth: .infinity)
                .padding(.top, 2)
        }
    }

    private func courseRow(name: String, subtitle: String, detail: String?,
                           loading: Bool) -> some View {
        GolfCard {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(name)
                        .font(GolfTheme.serif(16))
                        .foregroundStyle(GolfTheme.ink)
                        .multilineTextAlignment(.leading)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(GolfTheme.label(10))
                            .foregroundStyle(GolfTheme.inkFaint)
                    }
                }
                Spacer()
                if loading {
                    ProgressView().tint(GolfTheme.fairway)
                } else if let detail {
                    Text(detail)
                        .font(GolfTheme.score(13))
                        .foregroundStyle(GolfTheme.inkSoft)
                }
            }
            .padding(14)
        }
    }

    private func statusText(_ message: String,
                            color: Color = GolfTheme.inkSoft) -> some View {
        Text(message)
            .font(.system(size: 14))
            .foregroundStyle(color)
            .multilineTextAlignment(.center)
            .padding(.top, 16)
    }

    private var manualEntryLink: some View {
        Button {
            path.append(SearchRoute.manualEntry)
        } label: {
            Text("Can't find it? Enter the course manually")
                .font(GolfTheme.label(12))
                .foregroundStyle(GolfTheme.sky)
                .underline()
        }
        .padding(.top, 8)
    }

    // MARK: - Actions

    /// Type-ahead: wait for a pause in typing, then search. Each keystroke
    /// cancels the previous in-flight request.
    private func scheduleSearch(for text: String) {
        searchTask?.cancel()
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 3 else {
            results = []
            searchState = .idle
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            await search()
        }
    }

    private func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        searchState = .loading
        do {
            let found = try await client.searchCourses(query: trimmed)
            guard !Task.isCancelled else { return }
            results = found
            searchState = found.isEmpty ? .empty : .loaded
        } catch is CancellationError {
            // A newer keystroke took over — keep whatever is on screen.
        } catch {
            guard !Task.isCancelled else { return }
            searchState = .failed(error.localizedDescription)
        }
    }

    private func select(_ summary: CourseSummaryDTO) async {
        // Already cached → skip the network entirely (offline replay works).
        if let cached = GolfCourseImporter.cachedCourse(apiID: summary.id, in: context) {
            path.append(cached)
            return
        }
        loadingCourseID = summary.id
        defer { loadingCourseID = nil }
        do {
            let detail = try await client.courseDetail(id: summary.id)
            let course = GolfCourseImporter.importCourse(summary: summary, detail: detail,
                                                         into: context)
            path.append(course)
        } catch {
            searchState = .failed(error.localizedDescription)
        }
    }
}

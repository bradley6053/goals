import WidgetKit
import SwiftUI

@main
struct EmberWidgetBundle: WidgetBundle {
    var body: some Widget {
        EmberWidget()
        TimerLiveActivity()
    }
}

struct EmberEntry: TimelineEntry {
    let date: Date
    let snapshot: GoalSnapshot?
}

struct EmberProvider: TimelineProvider {
    func placeholder(in context: Context) -> EmberEntry {
        EmberEntry(date: Date(), snapshot: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (EmberEntry) -> Void) {
        completion(EmberEntry(date: Date(), snapshot: WidgetSnapshotStore.read().first ?? .preview))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EmberEntry>) -> Void) {
        let snapshot = WidgetSnapshotStore.read().first
        var entries = [EmberEntry(date: Date(), snapshot: snapshot)]

        // Streaks change meaning at midnight (a lapsed streak should show 0
        // and the check-in nudge) even if the app never opens, so schedule a
        // second entry at the day boundary. Other kinds only change when the
        // app writes a new snapshot, which reloads timelines anyway.
        if snapshot?.kindName == GoalKind.streak.rawValue,
           let midnight = Calendar.current.date(
               byAdding: .day, value: 1,
               to: Calendar.current.startOfDay(for: Date())) {
            entries.append(EmberEntry(date: midnight, snapshot: snapshot))
            completion(Timeline(entries: entries, policy: .after(midnight)))
            return
        }
        completion(Timeline(entries: entries,
                            policy: .after(Date().addingTimeInterval(3600))))
    }
}

extension GoalSnapshot {
    static let preview = GoalSnapshot(
        id: UUID(), title: "Lose 20 lbs", accentName: "ember", unit: "lbs",
        fraction: 0.6, headline: "−12 lbs", subline: "3 lbs to next reward",
        nextRewardTitle: "New golf shoes", nextRewardImageFile: nil,
        isComplete: false, updatedAt: Date())
}

struct EmberWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "EmberGoalWidget", provider: EmberProvider()) { entry in
            EmberWidgetView(entry: entry)
                .containerBackground(for: .widget) { Theme.bg }
        }
        .configurationDisplayName("Goal progress")
        .description("Your goal, your next reward, how close you are.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

struct EmberWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: EmberEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            content(displaySnapshot(snapshot))
                .widgetURL(URL(string: "ember://goal/\(snapshot.id.uuidString)"))
        } else {
            emptyContent
        }
    }

    /// Re-derives streak text for this entry's date so the midnight timeline
    /// entry shows a lapsed streak (and the check-in nudge) without the app
    /// having written a fresh snapshot. Non-streak snapshots pass through.
    private func displaySnapshot(_ snapshot: GoalSnapshot) -> GoalSnapshot {
        guard snapshot.kindName == GoalKind.streak.rawValue, !snapshot.isComplete
        else { return snapshot }

        let calendar = Calendar.current
        let displayed = StreakMath.displayedStreak(
            storedStreak: snapshot.streakCount ?? 0,
            lastCheckInDay: snapshot.lastCheckInDay,
            asOf: entry.date, calendar: calendar)

        var adjusted = snapshot
        adjusted.headline = GoalFormat.streakHeadline(displayed)
        let checkedInToday = snapshot.lastCheckInDay.map {
            calendar.isDate($0, inSameDayAs: entry.date)
        } ?? false
        if !checkedInToday {
            adjusted.subline = "Check in to keep the flame"
        }
        if displayed == 0 {
            adjusted.fraction = 0
        }
        return adjusted
    }

    @ViewBuilder
    private func content(_ snapshot: GoalSnapshot) -> some View {
        let accent = Accent.named(snapshot.accentName)
        switch family {
        case .systemMedium:
            mediumView(snapshot, accent: accent)
        case .accessoryCircular:
            Gauge(value: snapshot.fraction) {
                Image(systemName: "flame.fill")
            } currentValueLabel: {
                Text("\(Int((snapshot.fraction * 100).rounded()))")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            .gaugeStyle(.accessoryCircularCapacity)
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.title.uppercased())
                    .font(.system(size: 13, weight: .heavy).width(.condensed))
                    .lineLimit(1)
                Text(snapshot.headline)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .monospacedDigit()
                ProgressView(value: snapshot.fraction)
                    .progressViewStyle(.linear)
                    .tint(.white)
            }
        default:
            smallView(snapshot, accent: accent)
        }
    }

    private func smallView(_ snapshot: GoalSnapshot, accent: Accent) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(snapshot.title.uppercased())
                    .font(.system(size: 13, weight: .heavy).width(.condensed))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                Spacer(minLength: 0)
                if snapshot.isComplete {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(accent.gradient)
                }
            }
            Spacer(minLength: 0)
            Text(snapshot.headline)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(accent.gradient)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(snapshot.subline)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(2)
            GlowBar(fraction: snapshot.fraction, accent: accent)
        }
    }

    private func mediumView(_ snapshot: GoalSnapshot, accent: Accent) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text(snapshot.title.uppercased())
                    .font(.system(size: 15, weight: .heavy).width(.condensed))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text(snapshot.headline)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(accent.gradient)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(snapshot.subline)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                GlowBar(fraction: snapshot.fraction, accent: accent)
            }
            rewardThumb(snapshot, accent: accent)
        }
    }

    private func rewardThumb(_ snapshot: GoalSnapshot, accent: Accent) -> some View {
        ZStack {
            if let file = snapshot.nextRewardImageFile,
               let image = ImageStore.thumbnail(file) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.elevated)
                Image(systemName: "gift.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(accent.gradient)
            }
        }
        .frame(width: 96, height: 96)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(accent.primary.opacity(0.4), lineWidth: 1)
        )
    }

    private var emptyContent: some View {
        VStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 22))
                .foregroundStyle(Accent.ember.gradient)
            Text("SET A GOAL")
                .font(.system(size: 12, weight: .heavy).width(.condensed))
                .foregroundStyle(Theme.textPrimary)
        }
    }
}

/// Widget-safe version of the app's glowing progress bar.
struct GlowBar: View {
    let fraction: Double
    let accent: Accent

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.1))
                Capsule()
                    .fill(accent.gradient)
                    .frame(width: max(6, geo.size.width * fraction))
            }
        }
        .frame(height: 6)
    }
}

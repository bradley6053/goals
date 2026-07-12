import Foundation
import ActivityKit

/// Starts, updates, and ends the Live Activity for each timer. App target
/// only — Activity.request is unavailable in extensions. The activity needs
/// no updates while counting (the widget's timer-interval views self-advance);
/// we only touch it on pause/resume/cancel and cleanup.
enum TimerActivityController {
    static func start(for timer: EmberTimer) -> String? {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return nil }
        // The system won't keep an activity live past ~8 h; a far-off
        // bedtime still counts down in-app and alerts via notification.
        guard timer.totalSeconds <= 8 * 3600 else { return nil }
        let attributes = TimerActivityAttributes(
            timerID: timer.id, label: timer.label, emoji: timer.emoji,
            accentName: timer.accentName, totalSeconds: timer.totalSeconds)
        let content = ActivityContent(
            state: TimerActivityAttributes.ContentState(
                endDate: timer.endDate, pausedRemaining: timer.pausedRemaining),
            // Dims the activity once it fires — the notification alerts,
            // the activity just stops pretending to be live.
            staleDate: timer.endDate)
        return try? Activity.request(
            attributes: attributes, content: content, pushType: nil).id
    }

    static func update(for timer: EmberTimer) {
        guard let activity = activity(id: timer.activityID) else { return }
        let content = ActivityContent(
            state: TimerActivityAttributes.ContentState(
                endDate: timer.endDate, pausedRemaining: timer.pausedRemaining),
            staleDate: timer.isPaused ? nil : timer.endDate)
        Task { await activity.update(content) }
    }

    static func end(activityID: String?, immediately: Bool) {
        guard let activity = activity(id: activityID) else { return }
        let dismissal: ActivityUIDismissalPolicy = immediately
            ? .immediate
            // Natural fire: linger a few minutes reading 0:00 so a glance
            // still explains what just went off, then leave.
            : .after(.now + 4 * 60)
        Task { await activity.end(activity.content, dismissalPolicy: dismissal) }
    }

    /// Launch-time hygiene: end any activity whose timer no longer exists
    /// (crash orphans, timers finished and swept while we were dead).
    static func cleanUpOrphans(existingTimerIDs: Set<UUID>) {
        for activity in Activity<TimerActivityAttributes>.activities
        where !existingTimerIDs.contains(activity.attributes.timerID) {
            Task { await activity.end(activity.content, dismissalPolicy: .immediate) }
        }
    }

    private static func activity(id: String?) -> Activity<TimerActivityAttributes>? {
        guard let id else { return nil }
        return Activity<TimerActivityAttributes>.activities.first { $0.id == id }
    }
}

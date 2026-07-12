import Foundation
import UserNotifications

/// Local notifications are the only alert path once the app leaves the
/// foreground — no app code runs when a timer fires, so everything is
/// pre-scheduled at the end date and cancelled/rescheduled on pause/resume.
enum TimerNotifications {
    /// Ask the first time a timer starts (contextual beats an app-launch
    /// prompt). Denial is non-fatal: the dial and Live Activity still work,
    /// only the audible alert is lost.
    static func requestAuthorizationIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }

    static func schedule(for timer: EmberTimer) {
        guard !timer.isPaused else { return }
        let interval = timer.endDate.timeIntervalSinceNow
        guard interval > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = timer.doneTitle ?? "Time's up! \(timer.emoji)"
        content.body = timer.doneBody ?? defaultBody(for: timer)
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: interval, repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(
            identifier: timer.id.uuidString, content: content, trigger: trigger))
    }

    static func cancel(_ id: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [id.uuidString])
    }

    static func clearDelivered(_ ids: [UUID]) {
        UNUserNotificationCenter.current()
            .removeDeliveredNotifications(withIdentifiers: ids.map(\.uuidString))
    }

    private static func defaultBody(for timer: EmberTimer) -> String {
        if let next = timer.nextTurnName {
            return "Switch! It's \(next)'s turn."
        }
        return "Your \(TimerMath.windLabel(timer.totalSeconds)) timer is done."
    }
}

/// Shows timer banners with sound even while the app is foregrounded —
/// without a delegate, iOS silences notifications for the frontmost app.
final class TimerNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = TimerNotificationDelegate()

    func install() {
        UNUserNotificationCenter.current().delegate = self
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}

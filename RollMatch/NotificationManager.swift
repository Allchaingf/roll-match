//
//  NotificationManager.swift
//  RollMatch
//
//  Thin wrapper around UNUserNotificationCenter for real local reminders:
//  paste-soak timers, "restock the same batch", next-day seam checks.
//

import Foundation
import UserNotifications
import Combine

final class NotificationManager: ObservableObject {
    @Published var authorized: Bool = false

    init() {
        refreshAuthStatus()
    }

    func refreshAuthStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorized = (settings.authorizationStatus == .authorized
                                   || settings.authorizationStatus == .provisional)
            }
        }
    }

    func requestAuthorization(_ completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                self.authorized = granted
                completion?(granted)
            }
        }
    }

    /// Schedule a one-off reminder at a specific date. Returns the notification identifier.
    @discardableResult
    func schedule(id: String = UUID().uuidString,
                  title: String,
                  body: String,
                  at date: Date,
                  repeats: Bool = false) -> String {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let interval = max(date.timeIntervalSinceNow, 1)
        let trigger: UNNotificationTrigger
        if repeats {
            // Daily repeating reminder at the chosen time-of-day.
            let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
            trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        } else {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        }
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        return id
    }

    /// Convenience: soak timer in N minutes from now.
    @discardableResult
    func scheduleSoak(minutes: Int, wall: String) -> String {
        let fire = Date().addingTimeInterval(TimeInterval(max(minutes, 1) * 60))
        return schedule(title: "Soak complete",
                        body: "Paste on \(wall) has soaked \(minutes) min — hang the strip now.",
                        at: fire)
    }

    func cancel(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

//
//  NotificationDelegate.swift
//  FinanceTracker
//

import UserNotifications

/// Without a delegate, iOS silently drops notifications that fire while the app is foreground.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}

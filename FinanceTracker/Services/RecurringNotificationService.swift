//
//  RecurringNotificationService.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 6/6/26.
//

import Foundation
import UserNotifications
import BackgroundTasks
import SwiftData

enum RecurringNotificationService {
    static let bgTaskIdentifier = "me.enzottic.sage.recurringRefresh"
    private static let center = UNUserNotificationCenter.current()

    // MARK: - Authorization

    static func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    // MARK: - Scheduling

    /// Cancels all pending recurring notifications and re-schedules one per active rule.
    /// Using one slot per rule keeps total pending notifications well under the 64-notification system cap.
    static func scheduleAll(rules: [RecurringExpenseRule], enabled: Bool) async {
        let ids = rules.map { notificationID(for: $0) }
        center.removePendingNotificationRequests(withIdentifiers: ids)

        guard enabled else { return }

        let status = await authorizationStatus()
        guard status == .authorized || status == .provisional else { return }

        for rule in rules {
            await scheduleNext(for: rule)
        }
    }

    /// Cancels the pending notification for a specific rule. Call when a rule is deleted.
    static func cancel(for rule: RecurringExpenseRule) {
        center.removePendingNotificationRequests(withIdentifiers: [notificationID(for: rule)])
    }

    // MARK: - Background Task

    /// Register the BGAppRefreshTask handler. Must be called before the app finishes launching.
    static func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: bgTaskIdentifier, using: nil) { task in
            guard let bgTask = task as? BGAppRefreshTask else { return }

            bgTask.expirationHandler = { bgTask.setTaskCompleted(success: false) }

            Task {
                do {
                    let container = try SageModelContainer.make()
                    let context = ModelContext(container)

                    let service = RecurringExpenseService(modelContext: context)
                    service.generateAllExpenses(through: Date())

                    let rules = (try? context.fetch(FetchDescriptor<RecurringExpenseRule>())) ?? []
                    let enabled = UserDefaults(suiteName: SageModelContainer.appGroupIdentifier)?
                        .bool(forKey: "billRemindersEnabled") ?? false
                    await scheduleAll(rules: rules, enabled: enabled)
                } catch {}

                scheduleNextBackgroundRefresh()
                bgTask.setTaskCompleted(success: true)
            }
        }
    }

    static func scheduleNextBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: bgTaskIdentifier)
        request.earliestBeginDate = Calendar.current.date(byAdding: .hour, value: 12, to: Date())
        try? BGTaskScheduler.shared.submit(request)
    }

    // MARK: - Private

    private static func scheduleNext(for rule: RecurringExpenseRule) async {
        guard let nextDate = nextOccurrence(for: rule) else { return }

        // Notify at 9 AM the day before the due date
        guard let notifyDay = Calendar.current.date(byAdding: .day, value: -1, to: nextDate),
              notifyDay > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Bill Due Tomorrow"
        content.body = "\(rule.name) (\(rule.amount.currencyStringWithFraction)) is due tomorrow."
        content.sound = .default

        var components = Calendar.current.dateComponents([.year, .month, .day], from: notifyDay)
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: notificationID(for: rule),
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    private static func notificationID(for rule: RecurringExpenseRule) -> String {
        "recurring-\(rule.id.uuidString)"
    }

    private static func nextOccurrence(for rule: RecurringExpenseRule) -> Date? {
        let calendar = Calendar.current
        let after = rule.lastGeneratedDate ?? rule.startDate
        let next: Date?
        switch rule.frequency {
        case .daily:    next = calendar.date(byAdding: .day, value: 1, to: after)
        case .weekly:   next = calendar.date(byAdding: .weekOfYear, value: 1, to: after)
        case .biweekly: next = calendar.date(byAdding: .weekOfYear, value: 2, to: after)
        case .monthly:  next = calendar.date(byAdding: .month, value: 1, to: after)
        }
        if let next, let endDate = rule.endDate, next > endDate { return nil }
        return next
    }
}

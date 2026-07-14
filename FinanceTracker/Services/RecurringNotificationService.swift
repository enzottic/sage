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
import SageKit

enum RecurringNotificationService {
    static let bgTaskIdentifier = "me.enzottic.sage.recurringRefresh"
    private static let center = UNUserNotificationCenter.current()
    private static let notificationIDPrefix = "recurring-day-"
    private static let addedNotificationIDPrefix = "recurring-added-"

    // MARK: - Authorization

    static func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    // MARK: - Scheduling

    /// Cancels all pending day-grouped notifications and re-schedules one per unique due date.
    /// Grouping by day means multiple bills landing on the same date produce a single notification,
    /// and slot usage is bounded by due dates rather than rule count.
    static func scheduleAll(rules: [RecurringExpenseRule], enabled: Bool) async {
        // Remove every previously scheduled recurring notification
        let pending = await center.pendingNotificationRequests()
        let staleIDs = pending.map(\.identifier).filter {
            $0.hasPrefix(notificationIDPrefix) || $0.hasPrefix(addedNotificationIDPrefix)
        }
        center.removePendingNotificationRequests(withIdentifiers: staleIDs)

        guard enabled else { return }

        let status = await authorizationStatus()
        guard status == .authorized || status == .provisional else { return }

        // Group rules by the calendar day of their next occurrence
        var byDay: [Date: [RecurringExpenseRule]] = [:]
        for rule in rules {
            guard let next = nextOccurrence(for: rule) else { continue }
            let day = Calendar.current.startOfDay(for: next)
            byDay[day, default: []].append(rule)
        }

        for (day, dayRules) in byDay {
            await scheduleNotification(dueDate: day, rules: dayRules)
            await scheduleAddedNotification(dueDate: day, rules: dayRules)
        }
    }

    /// Re-fetches all rules and re-schedules notifications. For call sites that don't
    /// have an AppConfiguration instance or a fresh rule list handy (rule create/edit,
    /// background refresh).
    static func rescheduleAll(modelContext: ModelContext) async {
        let rules = (try? modelContext.fetch(FetchDescriptor<RecurringExpenseRule>())) ?? []
        await scheduleAll(rules: rules, enabled: AppConfiguration.isBillRemindersEnabled)
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

                    await rescheduleAll(modelContext: context)
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

    private static func scheduleNotification(dueDate: Date, rules: [RecurringExpenseRule]) async {
        guard let notifyDay = Calendar.current.date(byAdding: .day, value: -1, to: dueDate),
              notifyDay > Date() else { return }

        let content = UNMutableNotificationContent()
        content.sound = .default

        if rules.count == 1, let rule = rules.first {
            content.title = "Bill Due Tomorrow"
            content.body = "\(rule.name) (\(rule.amount.currencyStringWithFraction)) is due tomorrow."
        } else {
            let names = rules.map(\.name).joined(separator: ", ")
            content.title = "\(rules.count) Bills Due Tomorrow"
            content.body = names
        }

        var components = Calendar.current.dateComponents([.year, .month, .day], from: notifyDay)
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: notificationID(for: dueDate),
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    /// Fires at 9 AM on the due date itself, announcing the expenses generated for that day.
    /// The row may be inserted slightly later (next launch or background refresh), but it is
    /// dated to this day. If 9 AM has already passed, skip — the user will see the expense
    /// generated on next launch anyway.
    private static func scheduleAddedNotification(dueDate: Date, rules: [RecurringExpenseRule]) async {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
        components.hour = 9
        components.minute = 0
        guard let fireDate = Calendar.current.date(from: components), fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.sound = .default
        content.threadIdentifier = "recurring-added"

        if rules.count == 1, let rule = rules.first {
            content.title = "Recurring Expense Added"
            content.body = "\(rule.name) (\(rule.amount.currencyStringWithFraction)) was added."
        } else {
            content.title = "\(rules.count) Recurring Expenses Added"
            content.body = rules
                .map { "\($0.name) (\($0.amount.currencyStringWithFraction))" }
                .joined(separator: ", ")
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: addedNotificationID(for: dueDate),
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    private static func notificationID(for day: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "\(notificationIDPrefix)\(formatter.string(from: day))"
    }

    private static func addedNotificationID(for day: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "\(addedNotificationIDPrefix)\(formatter.string(from: day))"
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
        @unknown default:
            fatalError("Unknown frequency: \(rule.frequency)")
        }
        if let next, let endDate = rule.endDate, next > endDate { return nil }
        return next
    }
}

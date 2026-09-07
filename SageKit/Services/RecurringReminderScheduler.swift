import Foundation
import Observation
import UserNotifications

@MainActor
public protocol RecurringReminderNotificationClient {
    func authorizationStatus() async -> UNAuthorizationStatus
    func pendingRequests() async -> [UNNotificationRequest]
    func add(_ request: UNNotificationRequest) async throws
    func removePending(_ identifiers: [String])
    func removeDeliveredReminders(onlySensitive: Bool) async
}

@MainActor
public final class UNRecurringReminderNotificationClient: RecurringReminderNotificationClient {
    private let center: UNUserNotificationCenter

    public init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    public func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    public func pendingRequests() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
    }

    public func add(_ request: UNNotificationRequest) async throws {
        try await center.add(request)
    }

    public func removePending(_ identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers.filter(RecurringReminderPlan.owns))
    }

    public func removeDeliveredReminders(onlySensitive: Bool) async {
        let delivered = await center.deliveredNotifications()
        let identifiers = delivered.map(\.request).filter {
            RecurringReminderPlan.owns($0.identifier)
                && (!onlySensitive || $0.content.categoryIdentifier != RecurringReminderScheduler.privateCategory)
        }.map(\.identifier)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
}

@MainActor
@Observable
public final class RecurringReminderScheduler {
    public private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    public private(set) var errorMessage: String?
    public private(set) var scheduledCount: Int = 0
    public private(set) var isRefreshing: Bool = false

    static let historyKey = "sage.recurring.scheduleHistory.v1"
    fileprivate static let privateCategory = "sage.recurring.v1.private"

    private struct Inputs {
        let enabled: Bool
        let hideDetails: Bool
        let plan: @MainActor () throws -> [RecurringReminderPlan.Summary]
    }

    private let defaults: UserDefaults
    private let client: any RecurringReminderNotificationClient
    private let now: () -> Date
    @ObservationIgnored private var history: [String: Date]
    @ObservationIgnored private var inputs: Inputs?
    @ObservationIgnored private var revision: UInt64 = 0
    @ObservationIgnored private var worker: Task<Void, Never>?

    public init(
        defaults: UserDefaults,
        client: (any RecurringReminderNotificationClient)? = nil,
        now: @escaping () -> Date = Date.init
    ) {
        self.defaults = defaults
        self.client = client ?? UNRecurringReminderNotificationClient()
        self.now = now
        history = defaults.dictionary(forKey: Self.historyKey) as? [String: Date] ?? [:]
    }

    /// Coalesces refreshes into one worker; the plan is evaluated only for current inputs.
    public func refresh(
        enabled: Bool,
        hideDetails: Bool,
        plan: @escaping @MainActor () throws -> [RecurringReminderPlan.Summary]
    ) {
        inputs = Inputs(enabled: enabled, hideDetails: hideDetails, plan: plan)
        revision &+= 1
        guard worker == nil else { return }
        isRefreshing = true
        worker = Task { await run() }
    }

    public func waitUntilIdle() async {
        while let worker { await worker.value }
    }

    private func run() async {
        while let inputs {
            let currentRevision = revision
            errorMessage = nil
            persistHistory()
            await reconcile(inputs, revision: currentRevision)
            guard currentRevision == revision else { continue }
            let pending = await client.pendingRequests()
            guard currentRevision == revision else { continue }
            scheduledCount = pending.filter { RecurringReminderPlan.owns($0.identifier) }.count
            break
        }
        inputs = nil
        isRefreshing = false
        worker = nil
    }

    private func reconcile(_ inputs: Inputs, revision currentRevision: UInt64) async {
        let status = await client.authorizationStatus()
        guard currentRevision == revision else { return }
        authorizationStatus = status
        let requests = await client.pendingRequests()
        guard currentRevision == revision else { return }
        var owned = requests.filter { RecurringReminderPlan.owns($0.identifier) }
        let capacity = min(60, max(0, 64 - (requests.count - owned.count)))
        let authorized = status == .authorized || status == .provisional || status == .ephemeral

        if !inputs.enabled || !authorized {
            removePending(owned.map(\.identifier))
            history = history.filter { $0.value <= now() }
            persistHistory()
            await client.removeDeliveredReminders(onlySensitive: false)
            return
        }

        if inputs.hideDetails {
            // Unknown/legacy content is unsafe. Scrub before invoking a fallible data fetch.
            let unsafe = owned.filter { $0.content.categoryIdentifier != Self.privateCategory }
            removePending(unsafe.map(\.identifier))
            owned.removeAll { $0.content.categoryIdentifier != Self.privateCategory }
            await client.removeDeliveredReminders(onlySensitive: true)
            guard currentRevision == revision else { return }
        }

        let summaries: [RecurringReminderPlan.Summary]
        do {
            summaries = try inputs.plan()
        } catch {
            guard currentRevision == revision else { return }
            errorMessage = error.localizedDescription
            return
        }
        guard currentRevision == revision else { return }

        var seen = Set<String>()
        let desired = Array(summaries.sorted {
            $0.fireDate == $1.fireDate ? $0.identifier < $1.identifier : $0.fireDate < $1.fireDate
        }.filter {
            RecurringReminderPlan.owns($0.identifier) && $0.fireDate > now()
                && !(history[$0.identifier].map { $0 <= now() } ?? false)
                && seen.insert($0.identifier).inserted
        }.prefix(capacity))
        let desiredIDs = Set(desired.map(\.identifier))
        removePending(owned.filter { !desiredIDs.contains($0.identifier) }.map(\.identifier))

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = Calendar.current.timeZone
        for summary in desired {
            guard currentRevision == revision else { return }
            guard summary.fireDate > now(), !(history[summary.identifier].map { $0 <= now() } ?? false) else {
                removePending([summary.identifier])
                continue
            }
            let existing = owned.first { $0.identifier == summary.identifier }
            if let existing, let trigger = existing.trigger as? UNCalendarNotificationTrigger,
               !trigger.repeats, existing.content.title == summary.title,
               existing.content.body == summary.body, trigger.nextTriggerDate() == summary.fireDate {
                continue
            }
            let content = UNMutableNotificationContent()
            content.title = summary.title
            content.body = summary.body
            content.sound = .default
            content.categoryIdentifier = inputs.hideDetails ? Self.privateCategory : "sage.recurring.v1"
            content.userInfo = ["reminderIdentifier": summary.identifier]
            var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: summary.fireDate)
            components.calendar = calendar
            components.timeZone = calendar.timeZone
            let request = UNNotificationRequest(
                identifier: summary.identifier, content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            )
            let previousCutoff = history[summary.identifier]
            do {
                try await client.add(request)
                // A replacement can cross the previous cutoff while the center is suspended.
                // Keep that completed day, rather than moving its cutoff into the future.
                if let previousCutoff, previousCutoff <= now() {
                    history[summary.identifier] = previousCutoff
                    removePending([summary.identifier])
                } else {
                    history[summary.identifier] = summary.fireDate
                }
                persistHistory()
            } catch {
                // A failed replacement must not leave outdated expense details queued.
                removePending([summary.identifier])
                if currentRevision == revision {
                    errorMessage = error.localizedDescription
                }
                return
            }
            // An in-flight add cannot be cancelled. Remove its result before rebuilding.
            guard currentRevision == revision else {
                removePending([summary.identifier])
                return
            }
            if summary.fireDate <= now() { removePending([summary.identifier]) }
        }

        // Missing future requests may have been cleared by the system or another session.
        // Only elapsed cutoffs suppress a nominal day after westward time-zone travel.
        history = history.filter { $0.value <= now() || desiredIDs.contains($0.key) }
        persistHistory()
    }

    private func removePending(_ identifiers: [String]) {
        guard !identifiers.isEmpty else { return }
        client.removePending(identifiers)
        for identifier in identifiers where history[identifier].map({ $0 > now() }) == true {
            history.removeValue(forKey: identifier)
        }
        persistHistory()
    }

    private func persistHistory() {
        let cutoff = now().addingTimeInterval(-100 * 24 * 60 * 60)
        let retained = history.filter {
            RecurringReminderPlan.owns($0.key) && $0.value.timeIntervalSince1970.isFinite && $0.value > cutoff
        }.sorted { $0.value > $1.value }.prefix(256)
        history = Dictionary(uniqueKeysWithValues: retained.map { ($0.key, $0.value) })
        defaults.set(history, forKey: Self.historyKey)
    }
}

import Foundation
import Observation
import UserNotifications

@MainActor
public protocol DailyExpenseReminderNotificationClient {
    func authorizationStatus() async -> UNAuthorizationStatus
    func pendingRequests() async -> [UNNotificationRequest]
    func add(_ request: UNNotificationRequest) async throws
    func removePending(_ identifiers: [String])
    func removeDelivered(_ identifiers: [String])
}

@MainActor
public final class UNDailyExpenseReminderNotificationClient: DailyExpenseReminderNotificationClient {
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
        center.removePendingNotificationRequests(withIdentifiers: identifiers.filter {
            $0 == DailyExpenseReminderScheduler.identifier
        })
    }

    public func removeDelivered(_ identifiers: [String]) {
        center.removeDeliveredNotifications(withIdentifiers: identifiers.filter {
            $0 == DailyExpenseReminderScheduler.identifier
        })
    }
}

@MainActor
@Observable
public final class DailyExpenseReminderScheduler {
    public static let identifier = "sage.daily-expense-entry.v1"

    public private(set) var errorMessage: String?
    public private(set) var isRefreshing = false
    public private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private struct Inputs: Equatable {
        let enabled: Bool
        let timeMinutes: Int
    }

    private let client: any DailyExpenseReminderNotificationClient
    @ObservationIgnored private var inputs: Inputs?
    @ObservationIgnored private var revision: UInt64 = 0
    @ObservationIgnored private var worker: Task<Void, Never>?

    public init(
        center: UNUserNotificationCenter? = nil,
        client: (any DailyExpenseReminderNotificationClient)? = nil
    ) {
        self.client = client ?? UNDailyExpenseReminderNotificationClient(center: center ?? .current())
    }

    /// Reads permission without prompting and coalesces refreshes into one worker.
    public func refresh(enabled: Bool, timeMinutes: Int = 1200) {
        inputs = Inputs(enabled: enabled, timeMinutes: (0..<1440).contains(timeMinutes) ? timeMinutes : 1200)
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
            await reconcile(inputs, revision: currentRevision)
            if currentRevision == revision { break }
        }
        inputs = nil
        isRefreshing = false
        worker = nil
    }

    private func reconcile(_ inputs: Inputs, revision currentRevision: UInt64) async {
        let status = await client.authorizationStatus()
        guard currentRevision == revision else { return }
        authorizationStatus = status
        let authorized = status == .authorized || status == .provisional || status == .ephemeral
        guard inputs.enabled && authorized else {
            client.removePending([Self.identifier])
            client.removeDelivered([Self.identifier])
            return
        }

        let pending = await client.pendingRequests()
        guard currentRevision == revision else { return }
        guard pending.filter({ $0.identifier != Self.identifier }).count < 64 else {
            client.removePending([Self.identifier])
            errorMessage = "Daily expense reminder could not be scheduled because the notification queue is full."
            return
        }

        // Hour/minute only keeps the repeating reminder in floating device-local time.
        let components = DateComponents(hour: inputs.timeMinutes / 60, minute: inputs.timeMinutes % 60)
        let content = UNMutableNotificationContent()
        content.title = "Daily Expense Reminder"
        content.body = "Add expenses from the day."
        content.sound = .default
        if let existing = pending.first(where: { $0.identifier == Self.identifier }),
           let trigger = existing.trigger as? UNCalendarNotificationTrigger,
           trigger.repeats, trigger.dateComponents == components,
           existing.content.title == content.title, existing.content.body == content.body {
            return
        }

        let request = UNNotificationRequest(
            identifier: Self.identifier, content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        )
        do {
            try await client.add(request)
        } catch {
            // A failed replacement must not leave the obsolete time queued.
            client.removePending([Self.identifier])
            if currentRevision == revision { errorMessage = error.localizedDescription }
            return
        }
        // Adds cannot be cancelled. Remove obsolete results before processing the latest inputs.
        if currentRevision != revision && self.inputs != inputs {
            client.removePending([Self.identifier])
        }
    }
}

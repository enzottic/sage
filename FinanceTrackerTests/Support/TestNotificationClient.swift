import UserNotifications
@testable import SageKit

@MainActor
final class TestNotificationClient: NotificationClient {
    private enum Failure: Error { case add }

    var status: UNAuthorizationStatus = .authorized
    var pending: [UNNotificationRequest] = []
    var delivered: [UNNotificationRequest] = []
    var added: [UNNotificationRequest] = []
    var removed: [String] = []
    var removedDelivered: [String] = []
    var statusCalls = 0
    var deliveredCalls = 0
    var failAdd = false
    var blockAdd = false
    var blockStatus = false
    private var addContinuation: CheckedContinuation<Void, Never>?
    private var addStarted: CheckedContinuation<Void, Never>?
    private var statusContinuation: CheckedContinuation<Void, Never>?
    private var statusStarted: CheckedContinuation<Void, Never>?
    private var activeAdds = 0
    private(set) var maximumActiveAdds = 0

    func authorizationStatus() async -> UNAuthorizationStatus {
        statusCalls += 1
        let result = status
        if blockStatus {
            blockStatus = false
            await withCheckedContinuation { continuation in
                statusContinuation = continuation
                statusStarted?.resume()
                statusStarted = nil
            }
        }
        return result
    }

    func pendingRequests() async -> [UNNotificationRequest] { pending }

    func deliveredRequests() async -> [UNNotificationRequest] {
        deliveredCalls += 1
        return delivered
    }

    func add(_ request: UNNotificationRequest) async throws {
        activeAdds += 1
        maximumActiveAdds = max(maximumActiveAdds, activeAdds)
        defer { activeAdds -= 1 }
        added.append(request)
        let shouldFail = failAdd
        if blockAdd {
            blockAdd = false
            await withCheckedContinuation { continuation in
                addContinuation = continuation
                addStarted?.resume()
                addStarted = nil
            }
        }
        if shouldFail { throw Failure.add }
        pending.removeAll { $0.identifier == request.identifier }
        pending.append(request)
    }

    func removePending(_ identifiers: [String]) {
        removed += identifiers
        pending.removeAll { identifiers.contains($0.identifier) }
    }

    func removeDelivered(_ identifiers: [String]) {
        removedDelivered += identifiers
        delivered.removeAll { identifiers.contains($0.identifier) }
    }

    func waitForAdd() async {
        if addContinuation != nil { return }
        await withCheckedContinuation { addStarted = $0 }
    }

    func resumeAdd() {
        addContinuation?.resume()
        addContinuation = nil
    }

    func waitForStatus() async {
        if statusContinuation != nil { return }
        await withCheckedContinuation { statusStarted = $0 }
    }

    func resumeStatus() {
        statusContinuation?.resume()
        statusContinuation = nil
    }
}

import Foundation
import SwiftData

public struct RecurringExpenseRepairResult: Equatable, Sendable {
    public let backfilledCount: Int
    public let removedCount: Int
    public let conflictingGroupCount: Int

    public init(backfilledCount: Int = 0, removedCount: Int = 0, conflictingGroupCount: Int = 0) {
        self.backfilledCount = backfilledCount
        self.removedCount = removedCount
        self.conflictingGroupCount = conflictingGroupCount
    }
}

@MainActor
public final class RecurringExpenseRepairService {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Backfills occurrence identities and removes only exact duplicate generated expenses.
    /// The caller owns the save so repair and generation can use one transaction.
    public func repair() throws -> RecurringExpenseRepairResult {
        let expenses = try modelContext.fetch(FetchDescriptor<Expense>())
        var groups: [String: [Expense]] = [:]
        var backfilledCount = 0

        for expense in expenses {
            guard let ruleID = expense.recurringExpenseId else { continue }

            let key = expense.recurringOccurrenceKey
                ?? RecurringExpenseOccurrence.key(ruleID: ruleID, scheduledDate: expense.date)

            if expense.recurringOccurrenceKey == nil {
                expense.recurringOccurrenceKey = key
                backfilledCount += 1
            }

            groups[key, default: []].append(expense)
        }

        var removedCount = 0
        var conflictingGroupCount = 0

        for group in groups.values where group.count > 1 {
            let sorted = group.sorted { $0.id.uuidString < $1.id.uuidString }
            guard let canonical = sorted.first else { continue }

            var groupHasConflict = false
            for duplicate in sorted.dropFirst() {
                if Self.hasSameContent(canonical, duplicate) {
                    modelContext.delete(duplicate)
                    removedCount += 1
                } else {
                    groupHasConflict = true
                }
            }

            if groupHasConflict {
                conflictingGroupCount += 1
            }
        }

        return RecurringExpenseRepairResult(
            backfilledCount: backfilledCount,
            removedCount: removedCount,
            conflictingGroupCount: conflictingGroupCount
        )
    }

    private static func hasSameContent(_ lhs: Expense, _ rhs: Expense) -> Bool {
        lhs.name == rhs.name
            && lhs.amount == rhs.amount
            && lhs.category == rhs.category
            && lhs.date == rhs.date
            && lhs.note == rhs.note
            && lhs.recurringExpenseId == rhs.recurringExpenseId
            && lhs.tag?.id == rhs.tag?.id
            && Set((lhs.tags ?? []).map(\.id)) == Set((rhs.tags ?? []).map(\.id))
            && lhs.account?.id == rhs.account?.id
    }
}

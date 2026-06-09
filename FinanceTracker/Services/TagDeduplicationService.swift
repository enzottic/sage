//
//  TagDeduplicationService.swift
//  FinanceTracker
//
//  Deduplicates ExpenseTag records that arrive via CloudKit sync.
//  Groups tags by their stable UUID and merges duplicates into a single winner,
//  reassigning all relationships before deleting the losers.
//

import Foundation
import SwiftData
import SageKit

@MainActor
class TagDeduplicationService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Finds and removes duplicate ExpenseTag records, keeping one per unique `id`.
    /// Returns the number of duplicates removed.
    @discardableResult
    func deduplicateTags() -> Int {
        guard let allTags = try? modelContext.fetch(FetchDescriptor<ExpenseTag>()) else {
            return 0
        }
        
        // Group tags by their UUID
        let grouped = Dictionary(grouping: allTags, by: \.id)
        var removedCount = 0
        
        for (_, tags) in grouped where tags.count > 1 {
            // Prefer the tag that already has expenses attached (the CloudKit-synced one).
            // If neither or both have expenses, fall back to stable UUID string ordering
            // so all devices converge on the same winner without relying on hashValue,
            // which is randomized per process in Swift.
            var sorted = tags.sorted { a, b in
                let aHasExpenses = !(a.expenses?.isEmpty ?? true)
                let bHasExpenses = !(b.expenses?.isEmpty ?? true)
                if aHasExpenses != bHasExpenses { return aHasExpenses }
                return (a.id.uuidString) < (b.id.uuidString)
            }
            let winner = sorted.removeFirst()

            for duplicate in sorted {
                // Fetch expenses referencing the duplicate directly — don't rely on the
                // lazily-loaded inverse relationship, which may not be faulted in yet
                // when this runs immediately after a CloudKit remote-change notification.
                let duplicateTagID = duplicate.id
                let expensesDescriptor = FetchDescriptor<Expense>(
                    predicate: #Predicate { $0.tag?.id == duplicateTagID }
                )
                if let expenses: [Expense] = try? modelContext.fetch(expensesDescriptor) {
                    for expense in expenses {
                        expense.tag = winner
                    }
                }

                let rulesDescriptor = FetchDescriptor<RecurringExpenseRule>(
                    predicate: #Predicate { $0.tag?.id == duplicateTagID }
                )
                if let rules: [RecurringExpenseRule] = try? modelContext.fetch(rulesDescriptor) {
                    for rule in rules {
                        rule.tag = winner
                    }
                }

                modelContext.delete(duplicate)
                removedCount += 1
            }
        }
        
        if removedCount > 0 {
            try? modelContext.save()
        }
        
        return removedCount
    }
}

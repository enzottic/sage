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
            // Sort by persistentModelID to get a deterministic winner across devices.
            // All peers will pick the same winner since persistentModelID is stable.
            var sorted = tags.sorted { $0.persistentModelID.hashValue < $1.persistentModelID.hashValue }
            let winner = sorted.removeFirst()
            
            for duplicate in sorted {
                // Reassign expenses from the duplicate to the winner
                if let expenses = duplicate.expenses {
                    for expense in expenses {
                        expense.tag = winner
                    }
                }
                
                // Reassign recurring rules from the duplicate to the winner
                if let rules = duplicate.recurringRules {
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

//
//  RecurringExpenseService.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 3/8/26.
//

import Foundation
import SwiftData
import SageKit

class RecurringExpenseService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Generates expenses for all recurring rules through the given date.
    func generateAllExpenses(through date: Date) {
        let fetchDescriptor = FetchDescriptor<RecurringExpenseRule>()
        guard let rules = try? modelContext.fetch(fetchDescriptor) else { return }
        
        for rule in rules {
            generateExpenses(for: rule, through: date)
        }
        
        try? modelContext.save()
    }
    
    /// Generates expenses for a single rule from its lastGeneratedDate through the target date.
    func generateExpenses(for rule: RecurringExpenseRule, through date: Date) {
        let calendar = Calendar.current
        
        // Start generating from the day after lastGeneratedDate (or startDate if never generated)
        guard let lastGenerated = rule.lastGeneratedDate ?? calendar.date(byAdding: .day, value: -1, to: rule.startDate) else { return }
        
        // If the rule has an end date and we've passed it, stop
        if let endDate = rule.endDate, lastGenerated >= endDate { return }
        
        let effectiveEnd = rule.endDate.map { min($0, date) } ?? date
        
        var nextDate = rule.frequency.nextOccurrence(after: lastGenerated, calendar: calendar)

        while let generationDate = nextDate, generationDate <= effectiveEnd {
            let expense = Expense(
                name: rule.name,
                amount: rule.amount,
                category: rule.category,
                date: generationDate,
                tag: rule.tag,
                note: rule.note,
                recurringExpenseId: rule.id
            )
            modelContext.insert(expense)

            rule.lastGeneratedDate = generationDate
            nextDate = rule.frequency.nextOccurrence(after: generationDate, calendar: calendar)
        }
    }
}

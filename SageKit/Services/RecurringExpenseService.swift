//
//  RecurringExpenseService.swift
//  SageKit
//

import Foundation
import SwiftData

public final class RecurringExpenseService {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Generates expenses for all recurring rules through the given date.
    public func generateAllExpenses(through date: Date) {
        let fetchDescriptor = FetchDescriptor<RecurringExpenseRule>()
        guard let rules = try? modelContext.fetch(fetchDescriptor) else { return }

        for rule in rules {
            generateExpenses(for: rule, through: date)
        }

        try? modelContext.save()
    }

    /// Generates expenses for one rule through the target date.
    public func generateExpenses(for rule: RecurringExpenseRule, through date: Date) {
        let calendar = Calendar.current

        if let endDate = rule.endDate,
           let lastGeneratedDate = rule.lastGeneratedDate,
           lastGeneratedDate >= endDate {
            return
        }

        let effectiveEnd = rule.endDate.map { min($0, date) } ?? date
        var nextDate: Date? = rule.lastGeneratedDate.flatMap {
            rule.frequency.nextOccurrence(after: $0, calendar: calendar)
        } ?? rule.startDate

        while let generationDate = nextDate, generationDate <= effectiveEnd {
            let expense = Expense(
                name: rule.name,
                amount: rule.amount,
                category: rule.category,
                date: generationDate,
                tags: rule.tags ?? [],
                note: rule.note,
                recurringExpenseId: rule.id
            )
            modelContext.insert(expense)

            rule.lastGeneratedDate = generationDate
            nextDate = rule.frequency.nextOccurrence(after: generationDate, calendar: calendar)
        }
    }
}

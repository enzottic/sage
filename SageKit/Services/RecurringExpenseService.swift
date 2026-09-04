//
//  RecurringExpenseService.swift
//  SageKit
//

import Foundation
import SwiftData

public struct RecurringExpenseMaintenanceResult: Equatable, Sendable {
    public let generatedCount: Int
    public let skippedCount: Int
    public let repair: RecurringExpenseRepairResult

    public init(
        generatedCount: Int = 0,
        skippedCount: Int = 0,
        repair: RecurringExpenseRepairResult = RecurringExpenseRepairResult()
    ) {
        self.generatedCount = generatedCount
        self.skippedCount = skippedCount
        self.repair = repair
    }
}

@MainActor
public final class RecurringExpenseService {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Repairs duplicates and generates missing expenses for all rules through the given date.
    /// An occurrence key, and not only the rule cursor, makes repeated calls safe.
    @discardableResult
    public func generateAllExpenses(through date: Date) throws -> RecurringExpenseMaintenanceResult {
        let repair = try RecurringExpenseRepairService(modelContext: modelContext).repair()
        let rules = try modelContext.fetch(FetchDescriptor<RecurringExpenseRule>())
        let expenses = try modelContext.fetch(FetchDescriptor<Expense>())
        var existingKeys = Set(expenses.compactMap(\.recurringOccurrenceKey))
        var generatedCount = 0
        var skippedCount = 0

        for rule in rules {
            let result = generateExpenses(
                for: rule,
                through: date,
                existingKeys: &existingKeys
            )
            generatedCount += result.generatedCount
            skippedCount += result.skippedCount
        }

        do {
            if modelContext.hasChanges {
                try modelContext.save()
            }
        } catch {
            modelContext.rollback()
            throw error
        }

        return RecurringExpenseMaintenanceResult(
            generatedCount: generatedCount,
            skippedCount: skippedCount,
            repair: repair
        )
    }

    private func generateExpenses(
        for rule: RecurringExpenseRule,
        through date: Date,
        existingKeys: inout Set<String>
    ) -> (generatedCount: Int, skippedCount: Int) {
        let calendar = Calendar.current

        if let endDate = rule.endDate,
           let lastGeneratedDate = rule.lastGeneratedDate,
           lastGeneratedDate >= endDate {
            return (0, 0)
        }

        let effectiveEnd = rule.endDate.map { min($0, date) } ?? date
        var nextDate: Date? = rule.lastGeneratedDate.flatMap {
            rule.frequency.nextOccurrence(after: $0, calendar: calendar)
        } ?? rule.startDate
        var generatedCount = 0
        var skippedCount = 0

        while let generationDate = nextDate, generationDate <= effectiveEnd {
            let occurrenceKey = RecurringExpenseOccurrence.key(
                ruleID: rule.id,
                scheduledDate: generationDate
            )

            if existingKeys.contains(occurrenceKey) {
                skippedCount += 1
            } else {
                let expense = Expense(
                    name: rule.name,
                    amount: rule.amount,
                    category: rule.category,
                    date: generationDate,
                    tags: rule.tags ?? [],
                    note: rule.note,
                    recurringExpenseId: rule.id,
                    recurringOccurrenceKey: occurrenceKey,
                    account: rule.account
                )
                modelContext.insert(expense)
                existingKeys.insert(occurrenceKey)
                generatedCount += 1
            }

            rule.lastGeneratedDate = generationDate
            nextDate = rule.frequency.nextOccurrence(after: generationDate, calendar: calendar)
        }

        return (generatedCount, skippedCount)
    }
}

//
//  DataDeletionService.swift
//  SageKit
//

import Foundation
import SwiftData

@MainActor
public struct DataDeletionService {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Deletes every expense. Recurring rules stay active unless the caller also deletes them.
    public func deleteExpenses(includeRecurringRules: Bool) throws {
        try modelContext.delete(model: Expense.self)

        if includeRecurringRules {
            try modelContext.delete(model: RecurringExpenseRule.self)
        }

        try modelContext.save()
    }

    /// Deletes all user-created records in the local model store.
    public func deleteAllUserData() throws {
        try modelContext.delete(model: Expense.self)
        try modelContext.delete(model: RecurringExpenseRule.self)
        try modelContext.delete(model: ExpenseTag.self)
        try modelContext.delete(model: ExpenseAccount.self)
        try modelContext.save()
    }

    public func rollback() {
        modelContext.rollback()
    }
}

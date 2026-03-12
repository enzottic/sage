//
//  ExpenseDataService.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/5/25.
//

import Foundation
import SwiftData

class ExpenseStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    /// Convenience initializer that creates its own ModelContainer (for widget/intent contexts)
    convenience init() throws {
        let schema = Schema(versionedSchema: SageSchemaV1.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container = try ModelContainer(for: schema, configurations: [config])
        self.init(context: ModelContext(container))
    }

    // MARK: - Create

    func addExpense(_ expense: Expense) {
        context.insert(expense)
    }

    // MARK: - Read

    func fetchExpenses(for month: Date) -> [Expense] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: month)?.start ?? month
        let endOfMonth = calendar.dateInterval(of: .month, for: month)?.end ?? month

        let fetchDescriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { expense in
                startOfMonth <= expense.date && expense.date <= endOfMonth
            },
            sortBy: [SortDescriptor(\Expense.date, order: .reverse)]
        )

        return (try? context.fetch(fetchDescriptor)) ?? []
    }

    func fetchAllExpenses() -> [Expense] {
        let fetchDescriptor = FetchDescriptor<Expense>(
            sortBy: [SortDescriptor(\Expense.date, order: .reverse)]
        )
        return (try? context.fetch(fetchDescriptor)) ?? []
    }

    // MARK: - Delete

    func deleteExpense(_ expense: Expense) {
        context.delete(expense)
    }

    // MARK: - Save

    func save() throws {
        try context.save()
    }
}

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

    /// Convenience initializer for widget/intent contexts — opens the shared app group store.
    convenience init() throws {
        let container = try SageModelContainer.make()
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

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

    func fetchTag(id: UUID) -> ExpenseTag? {
        let descriptor = FetchDescriptor<ExpenseTag>(
            predicate: #Predicate { $0.id == id }
        )
        return try? context.fetch(descriptor).first
    }

    func fetchExpenses(from startDate: Date, to endDate: Date) -> [Expense] {
        let fetchDescriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { expense in
                startDate <= expense.date && expense.date < endDate
            },
            sortBy: [SortDescriptor(\Expense.date, order: .reverse)]
        )
        return (try? context.fetch(fetchDescriptor)) ?? []
    }

    func monthlyTotal(for month: Date = .now) -> Double {
        fetchExpenses(for: month).total
    }

    func monthlyTotal(category: ExpenseCategory, month: Date = .now) -> Double {
        fetchExpenses(for: month).filter { $0.category == category }.total
    }

    func monthlyTotal(tagId: UUID, month: Date = .now) -> Double {
        fetchExpenses(for: month).filter { $0.tag?.id == tagId }.total
    }

    // MARK: - Budget

    func budget(for category: ExpenseCategory) -> Double {
        let defaults = UserDefaults(suiteName: SageModelContainer.appGroupIdentifier) ?? .standard
        let income = Double(defaults.integer(forKey: "totalMonthlyIncome"))
        switch category {
        case .needs:
            return income * (defaults.object(forKey: "needsPercent") as? Double ?? 0.5)
        case .wants:
            return income * (defaults.object(forKey: "wantsPercent") as? Double ?? 0.3)
        case .savings:
            return income * (defaults.object(forKey: "savingsPercent") as? Double ?? 0.2)
        }
    }

    func totalBudget() -> Double {
        ExpenseCategory.allCases.map { budget(for: $0) }.reduce(0, +)
    }

    func remainingBudget(for category: ExpenseCategory, month: Date = .now) -> Double {
        budget(for: category) - monthlyTotal(category: category, month: month)
    }

    func totalRemainingBudget(month: Date = .now) -> Double {
        totalBudget() - monthlyTotal(for: month)
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

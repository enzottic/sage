//
//  ExpenseDataService.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/5/25.
//

import Foundation
import SwiftData

@MainActor @Observable
final public class ExpenseStore {
    public static let shared = ExpenseStore()
    
    let modelContainer: ModelContainer
    var context: ModelContext

    private init() {
        guard let container = try? SageModelContainer.make() else {
            fatalError("Failed to create the model container")
        }
        
        self.modelContainer = container
        self.context = container.mainContext
    }

    // MARK: - Create

    public func addExpense(_ expense: Expense) {
        context.insert(expense)
    }

    // MARK: - Read

    /// Returns all expenses for a given month, if provided. If not, fetches all expenses
    public func fetchExpenses(for month: Date? = nil) throws -> [Expense] {
        var descriptor = FetchDescriptor<Expense>(
            sortBy: [SortDescriptor(\Expense.date, order: .reverse)]
        )
        
        if let month {
            let calendar = Calendar.current
            let startOfMonth = calendar.dateInterval(of: .month, for: month)?.start ?? month
            let endOfMonth = calendar.dateInterval(of: .month, for: month)?.end ?? month
            descriptor.predicate = #Predicate { expense in
                startOfMonth <= expense.date && expense.date <= endOfMonth
            }
        }
        
        return try context.fetch(descriptor)
    }

    /// Returns all expenses that match the identifiers
    public func fetchExpenses(with ids: [UUID]) throws -> [Expense] {
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { ids.contains($0.id) }
        )
        return try context.fetch(descriptor)
    }

    /// Finds and returns a single expense by its identifier
    public func fetchExpense(with id: UUID) throws -> Expense? {
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.id == id}
        )
        return try context.fetch(descriptor).first
    }
    
    public func fetchRecentExpenses(limit: Int = 10) throws -> [Expense] {
        var descriptor = FetchDescriptor<Expense>(
            sortBy: [SortDescriptor(\.date)]
        )
        descriptor.fetchLimit = limit
        
        return try context.fetch(descriptor)
    }

    /// Finds and returns a single expense tag by its identifier
    public func fetchTag(id: UUID) throws -> ExpenseTag? {
        let descriptor = FetchDescriptor<ExpenseTag>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }
    
    public func fetchExpenses(from startDate: Date, to endDate: Date) -> [Expense] {
        let fetchDescriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { expense in
                startDate <= expense.date && expense.date < endDate
            },
            sortBy: [SortDescriptor(\Expense.date, order: .reverse)]
        )
        return (try? context.fetch(fetchDescriptor)) ?? []
    }

    public func monthlyTotal(for month: Date = .now) throws -> Double {
        try fetchExpenses(for: month).total
    }

    public func monthlyTotal(category: ExpenseCategory, month: Date = .now) throws -> Double {
        try fetchExpenses(for: month).filter { $0.category == category }.total
    }

    public func monthlyTotal(tagId: UUID, month: Date = .now) throws -> Double {
        try fetchExpenses(for: month).filter { $0.tag?.id == tagId }.total
    }

    // MARK: - Budget

    public func budget(for category: ExpenseCategory) -> Double {
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

    public func totalBudget() -> Double {
        ExpenseCategory.allCases.map { budget(for: $0) }.reduce(0, +)
    }

    public func remainingBudget(for category: ExpenseCategory, month: Date = .now) throws -> Double {
        budget(for: category) - (try monthlyTotal(category: category, month: month))
    }

    public func totalRemainingBudget(month: Date = .now) throws -> Double {
        totalBudget() - (try monthlyTotal(for: month))
    }

    public var totalMonthlyIncome: Int {
        let defaults = UserDefaults(suiteName: SageModelContainer.appGroupIdentifier) ?? .standard
        return defaults.integer(forKey: "totalMonthlyIncome")
    }

    // MARK: - Widget snapshot

    public struct MonthlySnapshot {
        public let totalSpent: Double
        public let wantsSpent: Double
        public let needsSpent: Double
        public let savingsSpent: Double
        public let totalIncome: Int
        public let needsBudget: Double
        public let wantsBudget: Double
        public let savingsBudget: Double
        public let recentExpenses: [ExpenseSnapshot]

        public var totalUnspent: Double { Double(totalIncome) - totalSpent }
        public var needsUtilization: Double { needsBudget > 0 ? needsSpent / needsBudget : 0 }
        public var wantsUtilization: Double { wantsBudget > 0 ? wantsSpent / wantsBudget : 0 }
    }

    public func monthlySnapshot(for month: Date = .now) throws -> MonthlySnapshot {
        let expenses = try fetchExpenses(for: month)
        let recentExpenses = expenses.prefix(5).map {
            ExpenseSnapshot(id: $0.id, name: $0.name, amount: $0.amount, category: $0.category, date: $0.date)
        }
        return MonthlySnapshot(
            totalSpent: expenses.total,
            wantsSpent: expenses.wantsUsed,
            needsSpent: expenses.needsUsed,
            savingsSpent: expenses.savingsUsed,
            totalIncome: totalMonthlyIncome,
            needsBudget: budget(for: .needs),
            wantsBudget: budget(for: .wants),
            savingsBudget: budget(for: .savings),
            recentExpenses: Array(recentExpenses)
        )
    }

    // MARK: - Delete

    public func deleteExpense(_ expense: Expense) {
        context.delete(expense)
    }

    // MARK: - Save

    public func save() throws {
        try context.save()
    }
}

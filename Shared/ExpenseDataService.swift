//
//  ExpenseDataService.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/5/25.
//

import Foundation
import SwiftData
import SwiftUI

class ExpenseDataService {
    
    @AppStorage("totalMonthlyIncome") private var totalMonthlyIncome: Double = 7300
    @AppStorage("wantsPercent") private var wantsPercent: Double = 0.3
    @AppStorage("needsPercent") private var needsPercent: Double = 0.5
    
    static var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Expense.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    func fetchExpenses(for month: Date = .now) -> [Expense] {
        return getExpenses(for: month)
    }
    
    func fetchTotalSpentThisMonth() -> Double {
        let expenses = getExpenses(for: .now)
        return expenses.reduce(0) { $0 + $1.amount }
    }
    
    func fetchWantsUtilizationThisMonth() -> Double {
        let wantsAmount = totalMonthlyIncome * wantsPercent
        let totalWants = getExpenses(for: .now).filter { $0.category == .wants }.reduce(0) { $0 + $1.amount }
        return wantsAmount == 0 ? 0 : totalWants / wantsAmount
    }
    
    func fetchNeedsUtilizationThisMonth() -> Double {
        let needsAmount = totalMonthlyIncome * needsPercent
        let totalNeeds = getExpenses(for: .now).filter { $0.category == .needs }.reduce(0) { $0 + $1.amount }
        return needsAmount == 0 ? 0 : totalNeeds / needsAmount
    }

    private func getExpenses(for month: Date) -> [Expense] {
        guard let container = try? ModelContainer(for: Expense.self) else { return [] }
        let context = ModelContext(container)

        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: month)?.start ?? month
        let endOfMonth = calendar.dateInterval(of: .month, for: month)?.end ?? month

        let fetchDescriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { expense in
                startOfMonth <= expense.date && expense.date <= endOfMonth
            },
            sortBy: [SortDescriptor(\Expense.date, order: .reverse)]
        )

        let allItems = try? context.fetch(fetchDescriptor)
        print(allItems?.count ?? "none")
        return allItems ?? []
    }
    
}

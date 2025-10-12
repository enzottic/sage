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
    
    @AppStorage("totalMonthlyIncome", store: UserDefaults(suiteName: "group.me.enzottic.SageAppGroup"))
    private var totalMonthlyIncome: Int = 7300
    
    @AppStorage("needsPercent", store: UserDefaults(suiteName: "group.me.enzottic.SageAppGroup"))
    private var needsPercent: Double = 0.5
    
    @AppStorage("wantsPercent", store: UserDefaults(suiteName: "group.me.enzottic.SageAppGroup"))
    private var wantsPercent : Double = 0.3
    
    @AppStorage("savingsPercent", store: UserDefaults(suiteName: "group.me.enzottic.SageAppGroup"))
    private var savingsPercent: Double = 0.2
    
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
    
    func fetchTimelineEntry() -> WidgetTimelineEntry {
        let expenses = getExpenses(for: .now)
        let totalSpent = expenses.reduce(0) { $0 + $1.amount }
        let totalWants = expenses.filter { $0.category == .wants }.reduce(0) { $0 + $1.amount }
        let totalNeeds = expenses.filter { $0.category == .needs }.reduce(0) { $0 + $1.amount }
        let totalSavings = expenses.filter { $0.category == .savings }.reduce(0) { $0 + $1.amount }
        let totalUnspent = Double(totalMonthlyIncome) - totalSpent
        let wantsUtilization = totalWants / (Double(totalMonthlyIncome) * wantsPercent)
        let needsUtilization = totalNeeds / (Double(totalMonthlyIncome) * needsPercent)
        
        return WidgetTimelineEntry(
            date: Date.now,
            totalSpent: totalSpent,
            totalWants: totalWants,
            totalNeeds: totalNeeds,
            totalSavings: totalSavings,
            totalUnspent: totalUnspent,
            wantsUtilization: wantsUtilization,
            needsUtilization: needsUtilization,
            latestExpenses: Array(expenses.prefix(3))
        )
    }
    
    func fetchTotalSpentThisMonth() -> Double {
        let expenses = getExpenses(for: .now)
        return expenses.reduce(0) { $0 + $1.amount }
    }
    
    func fetchWantsUtilizationThisMonth() -> Double {
        let wantsAmount = Double(totalMonthlyIncome) * wantsPercent
        let totalWants = getExpenses(for: .now).filter { $0.category == .wants }.reduce(0) { $0 + $1.amount }
        print("got wants: \(totalWants/wantsAmount)")
        return wantsAmount == 0 ? 0 : totalWants / wantsAmount
    }
    
    func fetchNeedsUtilizationThisMonth() -> Double {
        let needsAmount = Double(totalMonthlyIncome) * needsPercent
        let totalNeeds = getExpenses(for: .now).filter { $0.category == .needs }.reduce(0) { $0 + $1.amount }
        print("got needs: \(totalNeeds/needsAmount)")
        return needsAmount == 0 ? 0 : totalNeeds / needsAmount
    }

    private func getExpenses(for month: Date) -> [Expense] {
        let context = ModelContext(ExpenseDataService.sharedModelContainer)
        
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
        return allItems ?? []
    }
    
}

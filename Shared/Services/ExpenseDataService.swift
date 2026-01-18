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
    private let config: AppConfiguration
    
    init() {
        self.config = AppConfiguration()
    }
    
    func fetchTimelineEntry() -> WidgetTimelineEntry {
        let expenses = getExpenses(for: .now)
        let totalSpent = expenses.reduce(0) { $0 + $1.amount }
        let totalWants = expenses.filter { $0.category == .wants }.reduce(0) { $0 + $1.amount }
        let totalNeeds = expenses.filter { $0.category == .needs }.reduce(0) { $0 + $1.amount }
        let totalSavings = expenses.filter { $0.category == .savings }.reduce(0) { $0 + $1.amount }
        let totalUnspent = Double(config.totalMonthlyIncome) - totalSpent
        let wantsUtilization = totalWants / config.wantsBudget
        let needsUtilization = totalNeeds / config.needsBudget
        
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
    
    private func getExpenses(for month: Date) -> [Expense] {
        let schema = Schema(versionedSchema: SageSchemaV1.self)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            let modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            let context = ModelContext(modelContainer)
            
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
        } catch {
            return []
        }
    }
    
}

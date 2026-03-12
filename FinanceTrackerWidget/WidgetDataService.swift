//
//  WidgetDataService.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 3/8/26.
//

import Foundation
import WidgetKit

class WidgetDataService {
    private let expenseStore: ExpenseStore
    private let config: AppConfiguration

    init() {
        self.config = AppConfiguration()
        self.expenseStore = try! ExpenseStore()
    }

    func fetchTimelineEntry() -> WidgetTimelineEntry {
        let expenses = expenseStore.fetchExpenses(for: .now)
        let totalSpent = expenses.total
        let totalWants = expenses.wantsUsed
        let totalNeeds = expenses.needsUsed
        let totalSavings = expenses.savingsUsed
        let totalUnspent = Double(config.totalMonthlyIncome) - totalSpent
        let wantsUtilization = totalWants / config.wantsBudget
        let needsUtilization = totalNeeds / config.needsBudget

        return WidgetTimelineEntry(
            date: .now,
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
}

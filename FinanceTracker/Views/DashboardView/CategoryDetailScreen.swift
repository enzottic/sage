//
//  CategoryDetailScreen.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 7/12/26.
//
import SwiftUI
import SwiftData
import SageKit

/// Category drill-down pushed from the dashboard category widgets.
struct CategoryDetailScreen: View {
    @Environment(AppConfiguration.self) private var config
    @Query private var monthlyExpenses: [Expense]

    let category: ExpenseCategory

    init(category: ExpenseCategory, month: Date) {
        self.category = category
        let cal = Calendar.current
        let start = cal.dateInterval(of: .month, for: month)?.start ?? month
        let end = cal.dateInterval(of: .month, for: month)?.end ?? month
        _monthlyExpenses = Query(filter: #Predicate<Expense> { $0.date >= start && $0.date <= end }, sort: \.date)
    }

    private func utilization() -> Double {
        switch category {
        case .wants: config.wantsBudget == 0 ? 0 : monthlyExpenses.wantsUsed / config.wantsBudget
        case .needs: config.needsBudget == 0 ? 0 : monthlyExpenses.needsUsed / config.needsBudget
        case .savings: config.savingsBudget == 0 ? 0 : monthlyExpenses.savingsUsed / config.savingsBudget
        @unknown default: fatalError("Unknown expense category")
        }
    }

    private func spent() -> Double {
        switch category {
        case .wants: monthlyExpenses.wantsUsed
        case .needs: monthlyExpenses.needsUsed
        case .savings: monthlyExpenses.savingsUsed
        @unknown default: fatalError("Unknown expense category")
        }
    }

    private func budget() -> Double {
        switch category {
        case .wants: config.wantsBudget
        case .needs: config.needsBudget
        case .savings: config.savingsBudget
        @unknown default: fatalError("Unknown expense category")
        }
    }

    var body: some View {
        CategoryDetailView(category: category, utilization: utilization(), used: spent(), total: budget())
    }
}

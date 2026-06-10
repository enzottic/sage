//
//  WidgetTimelineEntry.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/7/25.
//

import Foundation
import WidgetKit
import SageKit

struct ExpenseSnapshot: Identifiable {
    let id: UUID
    let name: String
    let amount: Double
    let category: ExpenseCategory
    let date: Date
}

struct UtilizationEntry: TimelineEntry {
    let date: Date
    let totalSpent: Double
    let wantsUtilization: Double
    let needsUtilization: Double

    static let placeholder = UtilizationEntry(date: .now, totalSpent: 0, wantsUtilization: 0, needsUtilization: 0)
    static let preview = UtilizationEntry(date: .now, totalSpent: 3562.23, wantsUtilization: 0.35, needsUtilization: 0.84)
}

struct PieChartEntry: TimelineEntry {
    let date: Date
    let wantsSpent: Double
    let needsSpent: Double
    let savingsSpent: Double
    let totalUnspent: Double

    static let placeholder = PieChartEntry(date: .now, wantsSpent: 0, needsSpent: 0, savingsSpent: 0, totalUnspent: 0)
    static let preview = PieChartEntry(date: .now, wantsSpent: 1045.32, needsSpent: 2016.91, savingsSpent: 500.0, totalUnspent: 3437.77)
}

struct RecentExpensesEntry: TimelineEntry {
    let date: Date
    let expenses: [ExpenseSnapshot]

    static let placeholder = RecentExpensesEntry(date: .now, expenses: [])
    static let preview = RecentExpensesEntry(date: .now, expenses: [
        ExpenseSnapshot(id: UUID(), name: "Groceries", amount: 87.43, category: .needs, date: .now),
        ExpenseSnapshot(id: UUID(), name: "Netflix", amount: 15.99, category: .wants, date: .now),
        ExpenseSnapshot(id: UUID(), name: "Savings Transfer", amount: 200.0, category: .savings, date: .now),
        ExpenseSnapshot(id: UUID(), name: "Electric Bill", amount: 94.00, category: .needs, date: .now),
        ExpenseSnapshot(id: UUID(), name: "Dinner Out", amount: 62.15, category: .wants, date: .now),
    ])
}

struct BudgetRemainingEntry: TimelineEntry {
    let date: Date
    let remaining: Double
    let totalIncome: Int
    let percentUsed: Double

    static let placeholder = BudgetRemainingEntry(date: .now, remaining: 0, totalIncome: 0, percentUsed: 0)
    static let preview = BudgetRemainingEntry(date: .now, remaining: 3437.77, totalIncome: 7000, percentUsed: 0.51)
}

struct CategorySpotlightEntry: TimelineEntry {
    let date: Date
    let category: ExpenseCategory
    let spent: Double
    let budget: Double

    var utilization: Double { budget > 0 ? spent / budget : 0 }
    var remaining: Double { budget - spent }

    static func placeholder(category: ExpenseCategory) -> CategorySpotlightEntry {
        CategorySpotlightEntry(date: .now, category: category, spent: 0, budget: 0)
    }

    static func preview(category: ExpenseCategory) -> CategorySpotlightEntry {
        switch category {
        case .needs:   return CategorySpotlightEntry(date: .now, category: .needs, spent: 2016.91, budget: 3500)
        case .wants:   return CategorySpotlightEntry(date: .now, category: .wants, spent: 1045.32, budget: 2100)
        case .savings: return CategorySpotlightEntry(date: .now, category: .savings, spent: 500.0, budget: 1400)
        @unknown default:
            fatalError("Unknown category: \(category)")
        }
    }
}

struct MonthlySummaryEntry: TimelineEntry {
    let date: Date
    let totalSpent: Double
    let totalIncome: Int
    let wantsSpent: Double
    let wantsBudget: Double
    let needsSpent: Double
    let needsBudget: Double
    let savingsSpent: Double
    let savingsBudget: Double
    let recentExpenses: [ExpenseSnapshot]

    static let placeholder = MonthlySummaryEntry(
        date: .now, totalSpent: 0, totalIncome: 0,
        wantsSpent: 0, wantsBudget: 0,
        needsSpent: 0, needsBudget: 0,
        savingsSpent: 0, savingsBudget: 0,
        recentExpenses: [
            ExpenseSnapshot(id: UUID(), name: "Groceries", amount: 87.43, category: .needs, date: .now),
            ExpenseSnapshot(id: UUID(), name: "Netflix", amount: 15.99, category: .wants, date: .now),
            ExpenseSnapshot(id: UUID(), name: "Savings Transfer", amount: 200.0, category: .savings, date: .now),
            ExpenseSnapshot(id: UUID(), name: "Electric Bill", amount: 94.00, category: .needs, date: .now),
            ExpenseSnapshot(id: UUID(), name: "Dinner Out", amount: 62.15, category: .wants, date: .now),
        ]
    )
    static let preview = MonthlySummaryEntry(
        date: .now, totalSpent: 3562.23, totalIncome: 7000,
        wantsSpent: 1045.32, wantsBudget: 2100,
        needsSpent: 2016.91, needsBudget: 3500,
        savingsSpent: 500.0, savingsBudget: 1400,
        recentExpenses: [
            ExpenseSnapshot(id: UUID(), name: "Groceries", amount: 87.43, category: .needs, date: .now),
            ExpenseSnapshot(id: UUID(), name: "Netflix", amount: 15.99, category: .wants, date: .now),
            ExpenseSnapshot(id: UUID(), name: "Savings Transfer", amount: 200.0, category: .savings, date: .now),
            ExpenseSnapshot(id: UUID(), name: "Electric Bill", amount: 94.00, category: .needs, date: .now),
            ExpenseSnapshot(id: UUID(), name: "Dinner Out", amount: 62.15, category: .wants, date: .now),
        ]
    )
}

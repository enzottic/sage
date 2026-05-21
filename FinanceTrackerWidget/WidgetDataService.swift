//
//  WidgetDataService.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 3/8/26.
//

import Foundation
import os

private let logger = Logger(subsystem: "me.enzottic.FinanceTracker.widget", category: "WidgetDataService")

class WidgetDataService {
    private let expenseStore: ExpenseStore
    private let config: AppConfiguration

    init?() {
        do {
            self.expenseStore = try ExpenseStore()
        } catch {
            logger.error("ExpenseStore init failed: \(error)")
            return nil
        }
        self.config = AppConfiguration()
        logger.debug("WidgetDataService initialized successfully")
    }

    // MARK: - Public entry fetchers

    func fetchUtilizationEntry() -> UtilizationEntry {
        let raw = fetch()
        return UtilizationEntry(
            date: .now,
            totalSpent: raw.totalSpent,
            wantsUtilization: raw.wantsUtilization,
            needsUtilization: raw.needsUtilization
        )
    }

    func fetchPieChartEntry() -> PieChartEntry {
        let raw = fetch()
        return PieChartEntry(
            date: .now,
            wantsSpent: raw.wantsSpent,
            needsSpent: raw.needsSpent,
            savingsSpent: raw.savingsSpent,
            totalUnspent: raw.totalUnspent
        )
    }

    func fetchRecentExpensesEntry() -> RecentExpensesEntry {
        RecentExpensesEntry(date: .now, expenses: fetch().recentExpenses)
    }

    func fetchBudgetRemainingEntry() -> BudgetRemainingEntry {
        let raw = fetch()
        let total = Double(raw.totalIncome)
        return BudgetRemainingEntry(
            date: .now,
            remaining: raw.totalUnspent,
            totalIncome: raw.totalIncome,
            percentUsed: total > 0 ? raw.totalSpent / total : 0
        )
    }

    func fetchCategorySpotlightEntry(for category: ExpenseCategory) -> CategorySpotlightEntry {
        let raw = fetch()
        switch category {
        case .needs:
            return CategorySpotlightEntry(date: .now, category: .needs, spent: raw.needsSpent, budget: raw.needsBudget)
        case .wants:
            return CategorySpotlightEntry(date: .now, category: .wants, spent: raw.wantsSpent, budget: raw.wantsBudget)
        case .savings:
            return CategorySpotlightEntry(date: .now, category: .savings, spent: raw.savingsSpent, budget: raw.savingsBudget)
        }
    }

    func fetchMonthlySummaryEntry() -> MonthlySummaryEntry {
        let raw = fetch()
        return MonthlySummaryEntry(
            date: .now,
            totalSpent: raw.totalSpent, totalIncome: raw.totalIncome,
            wantsSpent: raw.wantsSpent, wantsBudget: raw.wantsBudget,
            needsSpent: raw.needsSpent, needsBudget: raw.needsBudget,
            savingsSpent: raw.savingsSpent, savingsBudget: raw.savingsBudget
        )
    }

    // MARK: - Private

    private struct RawData {
        let totalSpent: Double
        let wantsSpent: Double
        let needsSpent: Double
        let savingsSpent: Double
        let totalIncome: Int
        let needsBudget: Double
        let wantsBudget: Double
        let savingsBudget: Double
        let recentExpenses: [ExpenseSnapshot]

        var totalUnspent: Double { Double(totalIncome) - totalSpent }
        var needsUtilization: Double { needsBudget > 0 ? needsSpent / needsBudget : 0 }
        var wantsUtilization: Double { wantsBudget > 0 ? wantsSpent / wantsBudget : 0 }
    }

    private func fetch() -> RawData {
        let expenses = expenseStore.fetchExpenses(for: .now)
        let snapshots = expenses.prefix(5).map {
            ExpenseSnapshot(id: $0.id, name: $0.name, amount: $0.amount, category: $0.category, date: $0.date)
        }
        return RawData(
            totalSpent: expenses.total,
            wantsSpent: expenses.wantsUsed,
            needsSpent: expenses.needsUsed,
            savingsSpent: expenses.savingsUsed,
            totalIncome: config.totalMonthlyIncome,
            needsBudget: config.needsBudget,
            wantsBudget: config.wantsBudget,
            savingsBudget: config.savingsBudget,
            recentExpenses: Array(snapshots)
        )
    }
}

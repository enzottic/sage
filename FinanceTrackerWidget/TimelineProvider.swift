//
//  TimelineProvider.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/7/25.
//
import Foundation
import WidgetKit
import SageKit

private extension Date {
    static var nextRefresh: Date { Date().addingTimeInterval(15 * 60) }
}

private extension ExpenseStore.MonthlySnapshot {
    var utilizationEntry: UtilizationEntry {
        UtilizationEntry(date: .now, totalSpent: totalSpent, wantsUtilization: wantsUtilization, needsUtilization: needsUtilization)
    }

    var pieChartEntry: PieChartEntry {
        PieChartEntry(date: .now, wantsSpent: wantsSpent, needsSpent: needsSpent, savingsSpent: savingsSpent, totalUnspent: totalUnspent)
    }

    var recentExpensesEntry: RecentExpensesEntry {
        RecentExpensesEntry(date: .now, expenses: recentExpenses)
    }

    var budgetRemainingEntry: BudgetRemainingEntry {
        BudgetRemainingEntry(
            date: .now,
            remaining: totalUnspent,
            totalIncome: totalIncome,
            percentUsed: totalIncome > 0 ? totalSpent / Double(totalIncome) : 0
        )
    }

    func categorySpotlightEntry(for category: ExpenseCategory) -> CategorySpotlightEntry {
        switch category {
        case .needs:
            return CategorySpotlightEntry(date: .now, category: .needs, spent: needsSpent, budget: needsBudget)
        case .wants:
            return CategorySpotlightEntry(date: .now, category: .wants, spent: wantsSpent, budget: wantsBudget)
        case .savings:
            return CategorySpotlightEntry(date: .now, category: .savings, spent: savingsSpent, budget: savingsBudget)
        @unknown default:
            return CategorySpotlightEntry(date: .now, category: .needs, spent: 0, budget: 0)
        }
    }

    var monthlySummaryEntry: MonthlySummaryEntry {
        MonthlySummaryEntry(
            date: .now,
            totalSpent: totalSpent, totalIncome: totalIncome,
            wantsSpent: wantsSpent, wantsBudget: wantsBudget,
            needsSpent: needsSpent, needsBudget: needsBudget,
            savingsSpent: savingsSpent, savingsBudget: savingsBudget,
            recentExpenses: recentExpenses
        )
    }
}

// MARK: - Utilization

struct UtilizationProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> UtilizationEntry { .placeholder }

    func snapshot(for configuration: UtilizationAppIntent, in context: Context) async -> UtilizationEntry {
        context.isPreview ? .preview : .placeholder
    }

    func timeline(for configuration: UtilizationAppIntent, in context: Context) async -> Timeline<UtilizationEntry> {
        let entry = (try? await ExpenseStore.shared?.monthlySnapshot())?.utilizationEntry ?? .placeholder
        return Timeline(entries: [entry], policy: .after(.nextRefresh))
    }
}

// MARK: - Pie Chart

struct PieChartProvider: TimelineProvider {
    func placeholder(in context: Context) -> PieChartEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (PieChartEntry) -> Void) {
        completion(context.isPreview ? .preview : .placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PieChartEntry>) -> Void) {
        Task {
            let entry = (try? await ExpenseStore.shared?.monthlySnapshot())?.pieChartEntry ?? .placeholder
            completion(Timeline(entries: [entry], policy: .after(.nextRefresh)))
        }
    }
}

// MARK: - Recent Expenses

struct RecentExpensesProvider: TimelineProvider {
    func placeholder(in context: Context) -> RecentExpensesEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (RecentExpensesEntry) -> Void) {
        completion(context.isPreview ? .preview : .placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RecentExpensesEntry>) -> Void) {
        Task {
            let entry = (try? await ExpenseStore.shared?.monthlySnapshot())?.recentExpensesEntry ?? .placeholder
            completion(Timeline(entries: [entry], policy: .after(.nextRefresh)))
        }
    }
}

// MARK: - Budget Remaining

struct BudgetRemainingProvider: TimelineProvider {
    func placeholder(in context: Context) -> BudgetRemainingEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (BudgetRemainingEntry) -> Void) {
        completion(context.isPreview ? .preview : .placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BudgetRemainingEntry>) -> Void) {
        Task {
            let entry = (try? await ExpenseStore.shared?.monthlySnapshot())?.budgetRemainingEntry ?? .placeholder
            completion(Timeline(entries: [entry], policy: .after(.nextRefresh)))
        }
    }
}

// MARK: - Category Spotlight

struct CategorySpotlightProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CategorySpotlightEntry { .placeholder(category: .needs) }

    func snapshot(for configuration: CategorySpotlightAppIntent, in context: Context) async -> CategorySpotlightEntry {
        context.isPreview ? .preview(category: configuration.category) : .placeholder(category: configuration.category)
    }

    func timeline(for configuration: CategorySpotlightAppIntent, in context: Context) async -> Timeline<CategorySpotlightEntry> {
        let entry = (try? await ExpenseStore.shared?.monthlySnapshot())?.categorySpotlightEntry(for: configuration.category) ?? .placeholder(category: configuration.category)
        return Timeline(entries: [entry], policy: .after(.nextRefresh))
    }
}

// MARK: - Monthly Summary

struct MonthlySummaryProvider: TimelineProvider {
    func placeholder(in context: Context) -> MonthlySummaryEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (MonthlySummaryEntry) -> Void) {
        completion(context.isPreview ? .preview : .placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MonthlySummaryEntry>) -> Void) {
        Task {
            let entry = (try? await ExpenseStore.shared?.monthlySnapshot())?.monthlySummaryEntry ?? .placeholder
            completion(Timeline(entries: [entry], policy: .after(.nextRefresh)))
        }
    }
}

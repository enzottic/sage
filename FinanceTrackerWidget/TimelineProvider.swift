//
//  TimelineProvider.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/7/25.
//
import Foundation
import WidgetKit

private extension Date {
    static var nextRefresh: Date { Date().addingTimeInterval(15 * 60) }
}

// MARK: - Utilization

struct UtilizationProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> UtilizationEntry { .placeholder }

    func snapshot(for configuration: UtilizationAppIntent, in context: Context) async -> UtilizationEntry {
        context.isPreview ? .preview : .placeholder
    }

    func timeline(for configuration: UtilizationAppIntent, in context: Context) async -> Timeline<UtilizationEntry> {
        let entry = WidgetDataService()?.fetchUtilizationEntry() ?? .placeholder
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
        let entry = WidgetDataService()?.fetchPieChartEntry() ?? .placeholder
        completion(Timeline(entries: [entry], policy: .after(.nextRefresh)))
    }
}

// MARK: - Recent Expenses

struct RecentExpensesProvider: TimelineProvider {
    func placeholder(in context: Context) -> RecentExpensesEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (RecentExpensesEntry) -> Void) {
        completion(context.isPreview ? .preview : .placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RecentExpensesEntry>) -> Void) {
        let entry = WidgetDataService()?.fetchRecentExpensesEntry() ?? .placeholder
        completion(Timeline(entries: [entry], policy: .after(.nextRefresh)))
    }
}

// MARK: - Budget Remaining

struct BudgetRemainingProvider: TimelineProvider {
    func placeholder(in context: Context) -> BudgetRemainingEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (BudgetRemainingEntry) -> Void) {
        completion(context.isPreview ? .preview : .placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BudgetRemainingEntry>) -> Void) {
        let entry = WidgetDataService()?.fetchBudgetRemainingEntry() ?? .placeholder
        completion(Timeline(entries: [entry], policy: .after(.nextRefresh)))
    }
}

// MARK: - Category Spotlight

struct CategorySpotlightProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CategorySpotlightEntry { .placeholder(category: .needs) }

    func snapshot(for configuration: CategorySpotlightAppIntent, in context: Context) async -> CategorySpotlightEntry {
        context.isPreview ? .preview(category: configuration.category) : .placeholder(category: configuration.category)
    }

    func timeline(for configuration: CategorySpotlightAppIntent, in context: Context) async -> Timeline<CategorySpotlightEntry> {
        let entry = WidgetDataService()?.fetchCategorySpotlightEntry(for: configuration.category)
            ?? .placeholder(category: configuration.category)
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
        let entry = WidgetDataService()?.fetchMonthlySummaryEntry() ?? .placeholder
        completion(Timeline(entries: [entry], policy: .after(.nextRefresh)))
    }
}

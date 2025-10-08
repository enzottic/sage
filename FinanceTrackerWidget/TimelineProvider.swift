//
//  TimelineProvider.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/7/25.
//
import Foundation
import WidgetKit

struct ExpensesProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SageWidgetTimelineEntry {
        return SageWidgetTimelineEntry()
    }
    
    func snapshot(for configuration: UtilizationAppIntent, in context: Context) async -> SageWidgetTimelineEntry {
        if context.isPreview {
            return SageWidgetTimelineEntry(date: Date(), totalSpent: 3562.23, totalWants: 1045.32, totalNeeds: 2016.91, totalSavings: 500.0, wantsUtilization: 0.35, needsUtilization: 0.84, latestExpenses: [])
        } else {
            return SageWidgetTimelineEntry()
        }
    }
    
    func timeline(for configuration: UtilizationAppIntent, in context: Context) async -> Timeline<SageWidgetTimelineEntry> {
        let data = ExpenseDataService()
        let entry = data.fetchTimelineEntry()
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60)))
        return timeline
    }
}

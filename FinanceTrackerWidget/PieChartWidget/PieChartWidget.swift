//
//  PieChartWidget.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/7/25.
//
import SwiftUI
import WidgetKit
import Charts

struct ExpensePieChartEntryView: View {
    @Environment(\.widgetFamily) var family
    
    let entry: SageWidgetTimelineEntry
    let chartData: [ExpenseData]
    
    init(entry: SageWidgetTimelineEntry) {
        self.entry = entry
        
        self.chartData = [
            .init(category: "Wants", count: entry.totalWants),
            .init(category: "Needs", count: entry.totalNeeds),
            .init(category: "Savings", count: entry.totalSavings)
        ]
    }
    
    var body: some View {
        switch family {
        case .systemSmall: PieChartSmall(chartData: chartData)
        case .systemMedium: PieChartMedium(chartData: chartData)
        default:
            fatalError("nosirrr")
        }
    }

}

struct ExpensePieChartWidget: Widget {
    let kind: String = "SageExpensePieChartWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: UtilizationAppIntent.self, provider: ExpensesProvider()) { entry in
            ExpensePieChartEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Expenses Breakdown")
        .description(Text("View expense breakdown as a pie chart"))
        .supportedFamilies([.systemSmall, .systemMedium])

    }
}

#Preview(as: .systemSmall) {
    ExpensePieChartWidget()
} timeline: {
    SageWidgetTimelineEntry(date: Date(), totalSpent: 3562.23, totalWants: 1045.32, totalNeeds: 2016.91, totalSavings: 500.0, wantsUtilization: 0.35, needsUtilization: 0.84, latestExpenses: [])
}

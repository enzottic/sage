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
    
    let entry: WidgetTimelineEntry
    var chartData: [ExpenseData]
    
    init(entry: WidgetTimelineEntry) {
        self.entry = entry
        
        self.chartData = [
            .init(category: "Wants", count: entry.totalWants),
            .init(category: "Needs", count: entry.totalNeeds),
            .init(category: "Savings", count: entry.totalSavings),
            .init(category: "Unspent", count: entry.totalUnspent)
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
                .containerBackground(Color.ui.background, for: .widget)
        }
        .configurationDisplayName("Expenses Breakdown")
        .description(Text("View expense breakdown as a pie chart"))
        .supportedFamilies([.systemSmall, .systemMedium])

    }
}

#Preview(as: .systemSmall) {
    ExpensePieChartWidget()
} timeline: {
    WidgetTimelineEntry(date: Date(), totalSpent: 3562.23, totalWants: 1045.32, totalNeeds: 2016.91, totalSavings: 500.0, totalUnspent: 3532.23, wantsUtilization: 0.35, needsUtilization: 0.84, latestExpenses: [])
}

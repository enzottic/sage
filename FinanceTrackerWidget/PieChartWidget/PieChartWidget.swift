//
//  PieChartWidget.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/7/25.
//
import SwiftUI
import WidgetKit
import Charts
import SageKit

struct ExpensePieChartEntryView: View {
    @Environment(\.widgetFamily) var family

    let entry: PieChartEntry

    var chartData: [ExpenseData] {
        [
            .init(category: "Wants", count: entry.wantsSpent),
            .init(category: "Needs", count: entry.needsSpent),
            .init(category: "Savings", count: entry.savingsSpent),
            .init(category: "Unspent", count: entry.totalUnspent),
        ]
    }

    var body: some View {
        switch family {
        case .systemMedium: PieChartMedium(chartData: chartData)
        default: PieChartSmall(chartData: chartData)
        }
    }
}

struct ExpensePieChartWidget: Widget {
    let kind: String = "SageExpensePieChartWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PieChartProvider()) { entry in
            ExpensePieChartEntryView(entry: entry)
                .environment(\.categoryColors, CategoryColors.load())
                .containerBackground(Color("Background"), for: .widget)
        }
        .configurationDisplayName("Expenses Breakdown")
        .description(Text("View expense breakdown as a pie chart"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    ExpensePieChartWidget()
} timeline: {
    PieChartEntry.preview
}

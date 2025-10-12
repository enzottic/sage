//
//  UtilizationWidget.swift
//  FinanceTrackerWidgetExtension
//
//  Created by Tyler McCormick on 10/7/25.
//

import WidgetKit
import SwiftUI

struct UtilizationEntryView : View {
    @Environment(\.widgetFamily) var family
    
    var entry: WidgetTimelineEntry

    var body: some View {
        VStack(alignment: family == .systemSmall ? .center : .leading, spacing: 3) {
            Text("Total Spent")
                .font(.subheadline)
                .fontWeight(.ultraLight)
            Text(entry.totalSpent.currencyString)
                .font(.title2)
                .fontWeight(.black)
                .padding([.top], 3)
            
            Spacer()
            
            VStack(spacing: 10) {
                utilizationView(for: .wants, value: entry.wantsUtilization)
                utilizationView(for: .needs, value: entry.needsUtilization)
            }
        }
    }
    
    func utilizationView(for category: ExpenseCategory, value: Double) -> some View {
        VStack(spacing: 5){
            HStack {
                Text(category.rawValue.uppercased())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value, format: .percent.precision(.fractionLength(0)))
            }
            
            ProgressView(value: value, total: 1)
                .overlay(
                    LinearGradient(gradient: Gradient(colors: [category.color]), startPoint: .leading, endPoint: .trailing)
                    .mask(ProgressView(value: value, total: 1))
                  )
        }
        .font(.caption)
    }
}

struct ExpenseUtilizationWidget: Widget {
    let kind: String = "SageExpenseUtilizationWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: UtilizationAppIntent.self, provider: ExpensesProvider()) { entry in
            UtilizationEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("View Expense Utilization")
        .description(Text("View total spent this month, and wants and needs utilization"))
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    ExpenseUtilizationWidget()
} timeline: {
    WidgetTimelineEntry(date: Date(), totalSpent: 3562.23, totalWants: 1045.32, totalNeeds: 2016.91, totalSavings: 500.0, wantsUtilization: 0.35, needsUtilization: 0.84, latestExpenses: [])
}

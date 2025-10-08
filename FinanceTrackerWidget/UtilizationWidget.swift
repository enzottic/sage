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
    
    var entry: SageWidgetTimelineEntry

    var body: some View {
        VStack(alignment: family == .systemSmall ? .center : .leading, spacing: 3) {
            Text("Total Spent")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(entry.totalSpent.currencyString)
                .font(.title2)
                .bold()
                .padding([.top], 3)
            
            Spacer()
            
            VStack {
                utilizationView(for: .wants, value: entry.wantsUtilization)
                utilizationView(for: .needs, value: entry.needsUtilization)
            }
        }
    }
    
    func utilizationView(for category: ExpenseCategory, value: Double) -> some View {
        VStack(spacing: 5) {
            HStack{
                Text(category.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                Text(value, format: .percent.precision(.fractionLength(0)))
            }
            
            ProgressView(value: value)
                .tint(category.color)
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
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

#Preview(as: .systemMedium) {
    ExpenseUtilizationWidget()
} timeline: {
    SageWidgetTimelineEntry(date: Date(), totalSpent: 3562.23, totalWants: 1045.32, totalNeeds: 2016.91, totalSavings: 500.0, wantsUtilization: 0.35, needsUtilization: 0.84, latestExpenses: [])
}

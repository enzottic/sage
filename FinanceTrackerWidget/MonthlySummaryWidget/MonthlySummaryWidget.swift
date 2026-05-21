//
//  MonthlySummaryWidget.swift
//  FinanceTrackerWidgetExtension
//
//  Created by Tyler McCormick on 5/20/26.
//

import SwiftUI
import WidgetKit

struct MonthlySummaryEntryView: View {
    let entry: MonthlySummaryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("This Month")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(entry.totalSpent.currencyString)
                        .font(.title2)
                        .fontWeight(.black)
                }
                Spacer()
                Text("of \(entry.totalIncome.currencyString)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(spacing: 10) {
                categoryRow(name: "Needs", spent: entry.needsSpent, budget: entry.needsBudget, color: ExpenseCategory.needs.color)
                categoryRow(name: "Wants", spent: entry.wantsSpent, budget: entry.wantsBudget, color: ExpenseCategory.wants.color)
                categoryRow(name: "Savings", spent: entry.savingsSpent, budget: entry.savingsBudget, color: ExpenseCategory.savings.color)
            }
        }
    }

    func categoryRow(name: String, spent: Double, budget: Double, color: Color) -> some View {
        let utilization = budget > 0 ? spent / budget : 0
        return VStack(spacing: 4) {
            HStack {
                Text(name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(spent.currencyString)
                    .font(.caption)
                    .fontWeight(.medium)
                Text("/ \(budget.currencyString)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: min(utilization, 1), total: 1)
                .overlay(
                    LinearGradient(colors: [color], startPoint: .leading, endPoint: .trailing)
                        .mask(ProgressView(value: min(utilization, 1), total: 1))
                )
        }
    }
}

struct MonthlySummaryWidget: Widget {
    let kind: String = "SageMonthlySummaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MonthlySummaryProvider()) { entry in
            MonthlySummaryEntryView(entry: entry)
                .containerBackground(Color("Background"), for: .widget)
        }
        .configurationDisplayName("Monthly Summary")
        .description(Text("View spending across all budget categories"))
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

#Preview(as: .systemMedium) {
    MonthlySummaryWidget()
} timeline: {
    MonthlySummaryEntry.preview
}

#Preview(as: .systemLarge) {
    MonthlySummaryWidget()
} timeline: {
    MonthlySummaryEntry.preview
}


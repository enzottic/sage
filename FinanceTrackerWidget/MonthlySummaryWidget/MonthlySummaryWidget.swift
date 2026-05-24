//
//  MonthlySummaryWidget.swift
//  FinanceTrackerWidgetExtension
//
//  Created by Tyler McCormick on 5/20/26.
//

import SwiftUI
import WidgetKit

struct MonthlySummaryEntryView: View {
    @Environment(\.widgetFamily) var family
    @Environment(\.categoryColors) private var categoryColors
    let entry: MonthlySummaryEntry

    var remaining: Double { Double(entry.totalIncome) - entry.totalSpent }
    var isOverBudget: Bool { remaining < 0 }

    var body: some View {
        Group {
            switch family {
            case .systemSmall: smallBody
            case .systemMedium: mediumBody
            default: largeBody
            }
        }
    }

    // MARK: - Small: remaining + compact category bars

    var smallBody: some View {
        VStack(alignment: .leading, spacing: 5) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Remaining")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(abs(entry.totalSpent).currencyString)
                    .font(.title3)
                    .fontWeight(.black)
                    .foregroundStyle(isOverBudget ? .red : .primary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }

            Divider()

            VStack(spacing: 6) {
                compactCategoryRow(name: "Needs", spent: entry.needsSpent, budget: entry.needsBudget, color: categoryColors.needs)
                compactCategoryRow(name: "Wants", spent: entry.wantsSpent, budget: entry.wantsBudget, color: categoryColors.wants)
                compactCategoryRow(name: "Savings", spent: entry.savingsSpent, budget: entry.savingsBudget, color: categoryColors.savings)
            }
        }
    }

    func compactCategoryRow(name: String, spent: Double, budget: Double, color: Color) -> some View {
        let utilization = budget > 0 ? spent / budget : 0
        return VStack(spacing: 3) {
            HStack {
                Circle()
                    .frame(width: 6, height: 6)
                    .foregroundStyle(color)
                Text(name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(utilization, format: .percent.precision(.fractionLength(0)))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(utilization > 1 ? .red : .primary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.15))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * min(utilization, 1), height: 4)
                }
            }
            .frame(height: 4)
        }
    }

    // MARK: - Medium/Large: header + full category rows

    var mediumBody: some View {
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
                fullCategoryRow(name: "Needs", spent: entry.needsSpent, budget: entry.needsBudget, color: categoryColors.needs)
                fullCategoryRow(name: "Wants", spent: entry.wantsSpent, budget: entry.wantsBudget, color: categoryColors.wants)
                fullCategoryRow(name: "Savings", spent: entry.savingsSpent, budget: entry.savingsBudget, color: categoryColors.savings)
            }
        }
    }

    var largeBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date.now.formatted(.dateTime.month(.wide).year()))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(entry.totalSpent.currencyString)
                    .font(.title)
                    .fontWeight(.black)
                    .fontDesign(.rounded)
            }

            VStack(spacing: 10) {
                fullCategoryRow(name: "Needs", spent: entry.needsSpent, budget: entry.needsBudget, color: categoryColors.needs)
                fullCategoryRow(name: "Wants", spent: entry.wantsSpent, budget: entry.wantsBudget, color: categoryColors.wants)
                fullCategoryRow(name: "Savings", spent: entry.savingsSpent, budget: entry.savingsBudget, color: categoryColors.savings)
            }
            
            Divider()
            
            VStack(alignment: .leading) {
                Text("Recent Expenses")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ForEach(entry.recentExpenses.prefix(5)) { expense in
                    HStack(spacing: 6) {
                        Circle()
                            .frame(width: 8, height: 8)
                            .foregroundStyle(expense.category.color(in: categoryColors))
                        Text(expense.name)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        Text(expense.amount.currencyString)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }

            }
        }
    }

    func fullCategoryRow(name: String, spent: Double, budget: Double, color: Color) -> some View {
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
                .environment(\.categoryColors, CategoryColors.load())
                .containerBackground(Color("Background"), for: .widget)
        }
        .configurationDisplayName("Monthly Summary")
        .description(Text("View spending across all budget categories"))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview("Small", as: .systemSmall) {
    MonthlySummaryWidget()
} timeline: {
    MonthlySummaryEntry.preview
}

#Preview("Medium", as: .systemMedium) {
    MonthlySummaryWidget()
} timeline: {
    MonthlySummaryEntry.preview
}

#Preview("Large", as: .systemLarge) {
    MonthlySummaryWidget()
} timeline: {
    MonthlySummaryEntry.preview
}

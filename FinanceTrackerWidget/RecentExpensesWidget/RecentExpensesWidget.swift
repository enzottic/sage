//
//  RecentExpensesWidget.swift
//  FinanceTrackerWidgetExtension
//
//  Created by Tyler McCormick on 5/20/26.
//

import SwiftUI
import WidgetKit
import SageKit

struct RecentExpensesEntryView: View {
    @Environment(\.widgetFamily) var family
    @Environment(\.categoryColors) private var categoryColors

    let entry: RecentExpensesEntry

    var displayCount: Int { family == .systemSmall ? 3 : 5 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Recent Expenses")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            if entry.expenses.isEmpty {
                Spacer()
                Text("No expenses yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ForEach(entry.expenses.prefix(displayCount)) { expense in
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
            Spacer(minLength: 0)
        }
    }
}

struct RecentExpensesWidget: Widget {
    let kind: String = "SageRecentExpensesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecentExpensesProvider()) { entry in
            RecentExpensesEntryView(entry: entry)
                .environment(\.categoryColors, CategoryColors.load())
                .containerBackground(Color("Background"), for: .widget)
        }
        .configurationDisplayName("Recent Expenses")
        .description(Text("View your most recent expenses"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    RecentExpensesWidget()
} timeline: {
    RecentExpensesEntry.preview
}

#Preview(as: .systemMedium) {
    RecentExpensesWidget()
} timeline: {
    RecentExpensesEntry.preview
}

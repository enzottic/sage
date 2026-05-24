//
//  CategorySpotlightWidget.swift
//  FinanceTrackerWidgetExtension
//
//  Created by Tyler McCormick on 5/20/26.
//

import SwiftUI
import WidgetKit

struct CategorySpotlightEntryView: View {
    @Environment(\.categoryColors) private var categoryColors
    let entry: CategorySpotlightEntry

    var isOverBudget: Bool { entry.utilization > 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.category.rawValue.uppercased())
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(entry.category.color(in: categoryColors))
                Spacer()
                Text(entry.utilization, format: .percent.precision(.fractionLength(0)))
                    .font(.caption2)
                    .foregroundStyle(isOverBudget ? .red : .secondary)
            }

            Text(entry.spent.currencyString)
                .font(.title2)
                .fontWeight(.black)

            Spacer()

            VStack(spacing: 3) {
                ProgressView(value: min(entry.utilization, 1), total: 1)
                    .overlay(
                        LinearGradient(colors: [entry.category.color(in: categoryColors)], startPoint: .leading, endPoint: .trailing)
                            .mask(ProgressView(value: min(entry.utilization, 1), total: 1))
                    )
                HStack {
                    Text("of \(entry.budget.currencyString)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Group {
                        if isOverBudget {
                            Text("over budget")
                                .foregroundStyle(.red)
                        } else {
                            Text("\(entry.remaining.currencyString) left")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.caption2)
                }
            }
        }
    }
}

struct CategorySpotlightWidget: Widget {
    let kind: String = "SageCategorySpotlightWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: CategorySpotlightAppIntent.self, provider: CategorySpotlightProvider()) { entry in
            CategorySpotlightEntryView(entry: entry)
                .environment(\.categoryColors, CategoryColors.load())
                .containerBackground(Color("Background"), for: .widget)
        }
        .configurationDisplayName("Category Spotlight")
        .description(Text("Track spending for a specific budget category"))
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    CategorySpotlightWidget()
} timeline: {
    CategorySpotlightEntry.preview(category: .needs)
}

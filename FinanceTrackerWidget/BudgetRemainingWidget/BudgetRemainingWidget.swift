//
//  BudgetRemainingWidget.swift
//  FinanceTrackerWidgetExtension
//
//  Created by Tyler McCormick on 5/20/26.
//

import SwiftUI
import WidgetKit

struct BudgetRemainingEntryView: View {
    let entry: BudgetRemainingEntry

    var isOverBudget: Bool { entry.remaining < 0 }
    var ringColor: Color { isOverBudget ? .red : Color("Sage") }

    var body: some View {
        VStack(spacing: 10) {
            Text(Date.now.formatted(.dateTime.month(.wide).year()))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            ZStack {
                Circle()
                    .stroke(Color("Sage").opacity(0.15), lineWidth: 10)

                Circle()
                    .trim(from: 0, to: min(entry.percentUsed, 1))
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut, value: entry.percentUsed)

                VStack(spacing: 2) {
                    Text(abs(entry.remaining).currencyString)
                        .font(.system(size: 14, weight: .black))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .foregroundStyle(isOverBudget ? .red : .primary)
                    Text(isOverBudget ? "over" : "left")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
            }

            Text("of \(entry.totalIncome.currencyString)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct BudgetRemainingWidget: Widget {
    let kind: String = "SageBudgetRemainingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BudgetRemainingProvider()) { entry in
            BudgetRemainingEntryView(entry: entry)
                .containerBackground(Color("Background"), for: .widget)
        }
        .configurationDisplayName("Budget Remaining")
        .description(Text("See how much of your monthly budget remains"))
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    BudgetRemainingWidget()
} timeline: {
    BudgetRemainingEntry.preview
}

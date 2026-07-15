//
//  TopSpendingBreakdown.swift
//  FinanceTracker
//
//  Ranked "where the money went" list for the current Stats period.
//

import SwiftUI
import SwiftData
import SageKit

struct TopSpendingBreakdown: View {
    let expenses: [Expense]
    let accentColor: Color

    private struct Row: Identifiable {
        let id: String
        let label: String
        let emoji: String?
        let amount: Double
    }

    private var total: Double { expenses.total }

    private var rows: [Row] {
        let groups = Dictionary(grouping: expenses) { expense -> String in
            if let tag = expense.tag, !tag.isDeleted { return "tag-\(tag.id)" }
            return "cat-\(expense.category.rawValue)"
        }

        return groups
            .map { key, items -> Row in
                if let tag = items.first?.tag, !tag.isDeleted {
                    return Row(id: key, label: tag.name, emoji: tag.emoji, amount: items.total)
                }
                let category = items.first?.category ?? .wants
                return Row(id: key, label: category.rawValue, emoji: nil, amount: items.total)
            }
            .sorted { $0.amount > $1.amount }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Spending")
                .font(.headline)

            ForEach(rows) { row in
                rowView(row)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 15).fill(.cardBackground))
    }

    @ViewBuilder
    private func rowView(_ row: Row) -> some View {
        let fraction = total > 0 ? row.amount / total : 0

        VStack(spacing: 4) {
            HStack(spacing: 8) {
                if let emoji = row.emoji {
                    Text(emoji)
                } else {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 10, height: 10)
                }

                Text(row.label)
                    .font(.subheadline)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(row.amount.currencyString)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(fraction, format: .percent.precision(.fractionLength(0)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 36, alignment: .trailing)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(accentColor.opacity(0.15))
                    Capsule()
                        .fill(accentColor)
                        .frame(width: max(0, geometry.size.width * fraction))
                }
            }
            .frame(height: 6)
        }
    }
}

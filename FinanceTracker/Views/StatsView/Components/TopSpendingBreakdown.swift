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
    var title: String = "Top Spending"
    /// Label for expenses with no tag. When nil, they fall back to their category name,
    /// which only reads well in a mixed-category context like Stats.
    var untaggedLabel: String? = nil

    private struct Row: Identifiable {
        let id: String
        let label: String
        let glyph: TagGlyph?
        let amount: Double
    }

    private var total: Double { expenses.total }

    private var rows: [Row] {
        // An expense can carry multiple tags; attribute its full amount to each tag it has, so a
        // multi-tagged expense appears under every one of its tags. Untagged expenses fall back to
        // their category. (Rows can therefore sum to more than the grand total — expected for a
        // "where the money went" ranking.)
        var accumulator: [String: Row] = [:]

        func add(key: String, label: String, glyph: TagGlyph?, amount: Double) {
            if let existing = accumulator[key] {
                accumulator[key] = Row(id: key, label: existing.label, glyph: existing.glyph, amount: existing.amount + amount)
            } else {
                accumulator[key] = Row(id: key, label: label, glyph: glyph, amount: amount)
            }
        }

        for expense in expenses {
            let activeTags = (expense.tags ?? []).filter { !$0.isDeleted }
            if activeTags.isEmpty {
                add(key: "cat-\(expense.category.rawValue)", label: untaggedLabel ?? expense.category.rawValue, glyph: nil, amount: expense.amount)
            } else {
                for tag in activeTags {
                    add(key: "tag-\(tag.id)", label: tag.name, glyph: tag.glyph, amount: expense.amount)
                }
            }
        }

        return accumulator.values
            .sorted { $0.amount > $1.amount }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
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
                if let glyph = row.glyph {
                    TagGlyphView(glyph)
                        .foregroundStyle(accentColor)
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

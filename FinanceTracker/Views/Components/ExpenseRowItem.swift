//
//  ExpenseRowItem.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/4/25.
//

import SwiftUI
import SageKit

struct ExpenseRowItem: View {
    enum Style: Codable {
        case regular
        /// Single-line layout for tight spaces like dashboard cards.
        case condensed
    }

    @Environment(\.categoryColors) private var categoryColors
    let expense: Expense
    var style: Style = .regular

    private var tags: [ExpenseTag] { expense.tags ?? [] }

    var body: some View {
        switch style {
        case .regular: regularContent
        case .condensed: condensedContent
        }
    }

    private var regularContent: some View {
        HStack(spacing: 12) {
            // Category color accent bar
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(expense.category.color(in: categoryColors).secondary)
                    .frame(width: 40, height: 40)
                if let tag = tags.first {
                    TagGlyphView(tag: tag)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if tags.count > 1 {
                    Text("+\(tags.count - 1)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(expense.category.color(in: categoryColors)))
                        .offset(x: 4, y: 4)
                }
            }

            // Name and date on the left
            VStack(alignment: .leading, spacing: 3) {
                Text(expense.name)
                    .font(.body)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(expense.date.relative())
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if expense.recurringExpenseId != nil {
                        Image(systemName: "arrow.trianglehead.2.clockwise")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Text("-\(expense.amount.currencyStringWithFraction)")
                .font(.body)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var condensedContent: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(expense.category.color(in: categoryColors).secondary)
                    .frame(width: 24, height: 24)
                if let tag = tags.first {
                    TagGlyphView(tag: tag)
                        .font(.caption)
                }
            }

            Text(expense.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
                .layoutPriority(-1)

            if expense.recurringExpenseId != nil {
                Image(systemName: "arrow.trianglehead.2.clockwise")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(expense.date.relative())
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize()

            Text("-\(expense.amount.currencyStringWithFraction)")
                .font(.subheadline)
                .fontWeight(.medium)
                .fixedSize()
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        ExpenseRowItem(expense: Expense.example)
        ExpenseRowItem(expense: Expense.recurringExample)
    }
}

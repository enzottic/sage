//
//  ExpenseRowItem.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/4/25.
//

import SwiftUI

struct ExpenseRowItem: View {
    @Environment(\.categoryColors) private var categoryColors
    let expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            // Category color accent bar
            RoundedRectangle(cornerRadius: 3)
                .fill(expense.category.color(in: categoryColors))
                .frame(width: 4, height: 40)

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

            // Tag and amount on the right
            VStack(alignment: .trailing, spacing: 3) {
                Text(expense.amount.currencyStringWithFraction)
                    .font(.body)
                    .fontWeight(.medium)

                TagCapsule(tag: expense.tag, .xsmall)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        ExpenseRowItem(expense: Expense.example)
        ExpenseRowItem(expense: Expense.recurringExample)
    }
}

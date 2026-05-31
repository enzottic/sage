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
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(expense.category.color(in: categoryColors).secondary)
                    .frame(width: 40, height: 40)
                if let tagEmoji = expense.tag?.emoji {
                    Text(tagEmoji)
                }
            }

            // Name and date on the left
            VStack(alignment: .leading, spacing: 3) {
                Text(expense.name)
                    .font(.body)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if let tagName = expense.tag?.name {
                        Text(tagName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

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
}

#Preview {
    List {
        ExpenseRowItem(expense: Expense.example)
        ExpenseRowItem(expense: Expense.recurringExample)
    }
}

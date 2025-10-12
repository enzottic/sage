//
//  ExpenseRowItem.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/4/25.
//

import SwiftUI

struct ExpenseRowItem: View {
    let expense: Expense
    
    @State private var showEditExpenseSheet: Bool = false
    
    var body: some View {
        HStack {
            Circle()
                .frame(width: 10, height: 10)
                .foregroundStyle(expense.category.color)
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(expense.name)
                        .font(.headline)
                    Text(expense.date.relative())
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 5) {
                    Text(expense.amount.currencyString)
                    tagButton(tag: expense.tag)
                }
            }
        }
    }
    
    private func tagButton(tag: ExpenseTag) -> some View {
        ZStack {
            Text(String(tag.rawValue))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(tag.color))
                .foregroundStyle(.white)
                .font(.footnote)
        }
    }

    private func categoryButton(category: ExpenseCategory) -> some View {
        ZStack {
            Text(String(category.rawValue))
                .padding(.horizontal, 4)
                .foregroundStyle(.white)
                .font(.footnote)
                .background(Capsule().fill(category.color.opacity(0.5)))
        }
    }
}

#Preview {
    ExpenseRowItem(expense: Expense.example)
}

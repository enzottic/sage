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
                    Text(expense.amount.currencyStringWithFraction)
                    TagCapsule(tag: expense.tag)
                }
            }
        }
    }
}

#Preview {
    ExpenseRowItem(expense: Expense.example)
}

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
                VStack(alignment: .leading, spacing: 10) {
                    Text(expense.name)
                        .font(.headline)
                    
                    HStack(alignment: .center) {
                        Text(expense.date.relative())
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                        Text("•")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                        TagCapsule(tag: expense.tag)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 5) {
                    Text(expense.amount.currencyStringWithFraction)
                }
            }
        }
    }
}

#Preview {
    ExpenseRowItem(expense: Expense.example)
}

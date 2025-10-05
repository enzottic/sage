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
            VStack(alignment: .leading) {
                Text(expense.name)
                    .font(.headline)
                Text(expense.date.relative())
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(expense.amount.currencyString)
                categoryButton(category: expense.category)
            }
        }
    }
    
    private func categoryButton(category: ExpenseCategory) -> some View {
        ZStack {
            Text(String(category.rawValue))
                .padding(.horizontal, 4)
                .foregroundStyle(.white)
                .font(.footnote)
                .background(Capsule().fill(category.color))
        }
    }
}

#Preview {
    ExpenseRowItem(expense: Expense.example)
}

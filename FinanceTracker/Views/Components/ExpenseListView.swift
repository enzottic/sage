//
//  ExpenseRowView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/1/25.
//

import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext
    
    let expenses: [Expense]
    
    var body: some View {
        ForEach(expenses) {
            expenseRow(expense: $0)
        }
        .onDelete(perform: deleteItems)
    }
    
    private func expenseRow(expense: Expense) -> some View {
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
    
    private func categoryButton(category: Expense.ExpenseCategory) -> some View {
        ZStack {
            Text(String(category.rawValue))
                .padding(.horizontal, 4)
                .foregroundStyle(.white)
                .font(.footnote)
                .background(Capsule().fill(category.color))
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(expenses[index])
            }
        }
    }
}


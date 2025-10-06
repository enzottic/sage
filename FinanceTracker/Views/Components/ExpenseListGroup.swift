//
//  ExpenseListGroup.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/4/25.
//

import SwiftUI
import SwiftData
import WidgetKit

struct ExpenseListGroup: View {
    @Environment(\.modelContext) private var modelContext
    
    let expenses: [Expense]
    
    @State private var expenseToDelete: Expense? = nil
    @State private var showingDeleteConfirmation: Bool = false
    
    var body: some View {
        ForEach(expenses) { expense in
            NavigationLink {
                EditExpenseSheet(expense: expense)
            } label: {
                ExpenseRowItem(expense: expense)
            }
            .swipeActions {
                Button("Delete") {
                    expenseToDelete = expense
                    showingDeleteConfirmation = true
                }
                .tint(.red)
            }
        }
        .alert("Delete Expense?", isPresented: $showingDeleteConfirmation, actions: {
            Button("Delete", role: .destructive) {
                if let expense = expenseToDelete {
                    modelContext.delete(expense)
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
            
            Button("Cancel", role: .cancel) {
                expenseToDelete = nil
            }
        })
    }
}

#Preview {
    ExpenseListGroup(expenses: [Expense.example, Expense.example])
}

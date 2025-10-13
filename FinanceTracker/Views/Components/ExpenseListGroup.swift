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
    
    @State private var expenseToView: Expense? = nil
    
    var body: some View {
        ForEach(expenses) { expense in
            ExpenseRowItem(expense: expense)
                .buttonStyle(.plain)
                .swipeActions {
                    Button("Delete") {
                        expenseToDelete = expense
                        showingDeleteConfirmation = true
                    }
                    .tint(.red)
                }
                .onTapGesture { expenseToView = expense }
        }
        .sheet(item: $expenseToView) { expense in
            ExpenseDetailView(expense: expense)
                .presentationDetents([.medium])
        }
        .alert("Delete Expense?", isPresented: $showingDeleteConfirmation, actions: {
            Button("Delete", role: .destructive) {
                if let expense = expenseToDelete {
                    modelContext.delete(expense)
                    try! modelContext.save()
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
        .modelContainer(ModelContainer.preview)
}

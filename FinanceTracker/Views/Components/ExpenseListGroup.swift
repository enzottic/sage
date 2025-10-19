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
    @Binding var selectedExpense: Expense?
    
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
                .contentShape(Rectangle())
                .onTapGesture { selectedExpense = expense }
        }
        .alert("Delete Expense?", isPresented: $showingDeleteConfirmation, actions: {
            Button("Delete", role: .destructive) {
                if let expense = expenseToDelete {
                    withAnimation {
                        modelContext.delete(expense)
                        try! modelContext.save()
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }
            }
            
            Button("Cancel", role: .cancel) {
                expenseToDelete = nil
            }
        })
    }
}

#Preview {
    @Previewable @State var expenseToView: Expense? = nil
    
    ExpenseListGroup(expenses: [Expense.example, Expense.example], selectedExpense: $expenseToView)
        .modelContainer(ModelContainer.preview)
}

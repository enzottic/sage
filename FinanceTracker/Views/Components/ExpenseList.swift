//
//  ExpenseListGroup.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/4/25.
//

import SwiftUI
import SwiftData
import WidgetKit

struct ExpenseList: View {
    @Environment(\.modelContext) private var modelContext

    let expenses: [Expense]
    
    @State private var expenseToDelete: Expense? = nil
    @State private var showingDeleteConfirmation: Bool = false
    @Binding var selectedExpense: Expense?
    
    var body: some View {
        Group {
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
                    .onTapGesture {
                        selectedExpense = expense
                    }
                }
        }
        .alert("Delete Expense?", isPresented: $showingDeleteConfirmation, actions: {
            Button("Delete", role: .destructive) {
                if let expense = expenseToDelete {
                    deleteExpense(expense)
                }
            }
            Button("Cancel", role: .cancel) {
                expenseToDelete = nil
            }
        })
    }
    
    private func deleteExpense(_ expense: Expense) {
        withAnimation {
            modelContext.delete(expense)
            try! modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}

#Preview {
    @Previewable @State var expenseToView: Expense? = nil
    
    List {
        ExpenseList(expenses: [Expense.example, Expense.example], selectedExpense: $expenseToView)
    }
        .modelContainer(previewAppContainer)
}

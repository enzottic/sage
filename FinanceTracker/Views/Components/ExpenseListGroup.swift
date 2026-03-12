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
    @State private var recurringIdToDelete: UUID? = nil
    @State private var recurringDeleteFromDate: Date? = nil
    @State private var showingDeleteConfirmation: Bool = false
    @State private var showingRecurringDeleteConfirmation: Bool = false
    @Binding var selectedExpense: Expense?
    
    var body: some View {
        ForEach(expenses) { expense in
        ExpenseRowItem(expense: expense)
            .buttonStyle(.plain)
            .swipeActions {
                Button("Delete") {
                    expenseToDelete = expense
                    recurringIdToDelete = expense.recurringExpenseId
                    recurringDeleteFromDate = expense.date
                    if expense.recurringExpenseId != nil {
                        showingRecurringDeleteConfirmation = true
                    } else {
                        showingDeleteConfirmation = true
                    }
                }
                .tint(.red)
            }
            .contentShape(Rectangle())
            .onTapGesture { selectedExpense = expense }
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
        .alert("This is a recurring expense.", isPresented: $showingRecurringDeleteConfirmation) {
            Button("This Expense Only") {
                if let expense = expenseToDelete {
                    deleteExpense(expense)
                }
            }
            
            Button("All Future Expenses", role: .destructive) {
                if let recurringId = recurringIdToDelete,
                   let fromDate = recurringDeleteFromDate {
                    deleteRecurringExpenses(recurringId: recurringId, fromDate: fromDate)
                }
            }
            
            Button("Cancel", role: .cancel) {
                expenseToDelete = nil
            }
        } message: {
            Text("Do you want to delete just this expense, or all future expenses in this series?")
        }
    }
    
    private func deleteExpense(_ expense: Expense) {
        withAnimation {
            modelContext.delete(expense)
            try! modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    private func deleteRecurringExpenses(recurringId: UUID, fromDate: Date) {
        let fetchDescriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { e in
                e.recurringExpenseId == recurringId && e.date >= fromDate
            }
        )
        
        withAnimation {
            if let futureExpenses = try? modelContext.fetch(fetchDescriptor) {
                for futureExpense in futureExpenses {
                    modelContext.delete(futureExpense)
                }
            }
            
            let ruleFetch = FetchDescriptor<RecurringExpenseRule>(
                predicate: #Predicate { rule in
                    rule.id == recurringId
                }
            )
            
            if let rule = try? modelContext.fetch(ruleFetch).first {
                modelContext.delete(rule)
            }
            
            try! modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}

#Preview {
    @Previewable @State var expenseToView: Expense? = nil
    
    ExpenseListGroup(expenses: [Expense.example, Expense.example], selectedExpense: $expenseToView)
        .modelContainer(ModelContainer.preview)
}

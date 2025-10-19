//
//  EditExpenseSheet.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/4/25.
//

import SwiftUI
import SwiftData
import WidgetKit


//struct EditExpenseSheet: View {
//    @Environment(\.modelContext) private var modelContext
//    @Environment(\.dismiss) private var dismiss
//
//    var expense: Expense
//    let completion: () -> Void
//    @State private var workingExpense: EditableExpense
//
//    init(expense: Expense, completion: @escaping () -> Void) {
//        self.expense = expense
//        _workingExpense = State(initialValue: EditableExpense(
//            name: expense.name,
//            amount: expense.amount,
//            date: expense.date,
//            category: expense.category,
//            tag: expense.tag
//        ))
//        self.completion = completion
//    }
//
//    var body: some View {
//        NavigationStack {
//            ExpenseInfoForm(
//                name: $workingExpense.name,
//                amount: $workingExpense.amount,
//                date: $workingExpense.date,
//                category: $workingExpense.category,
//                tag: $workingExpense.tag
//            )
//        }
//        .toolbar {
//            ToolbarItemGroup(placement: .topBarLeading) {
//                Button("Cancel") { completion() }
//            }
//            
//            ToolbarItemGroup(placement: .topBarTrailing) {
//                Button("Save") { saveItem() }
//            }
//        }
//    }
//    
//    func saveItem() {
//        expense.name = workingExpense.name
//        expense.amount = workingExpense.amount ?? 0
//        expense.date = workingExpense.date
//        expense.category = workingExpense.category
//        expense.tag = workingExpense.tag
//        try! modelContext.save()
//        WidgetCenter.shared.reloadAllTimelines()
//        completion()
//    }
//}

//#Preview {
//    EditExpenseSheet(expense: Expense.example, completion: { })
//}

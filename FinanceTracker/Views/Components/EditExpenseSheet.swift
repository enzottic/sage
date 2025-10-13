//
//  EditExpenseSheet.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/4/25.
//

import SwiftUI
import SwiftData
import WidgetKit

private struct EditableExpense {
    var name: String
    var amount: Double
    var date: Date
    var category: ExpenseCategory
    var tag: ExpenseTag
}

struct EditExpenseSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var expense: Expense
    let completion: () -> Void
    @State private var workingExpense: EditableExpense

    init(expense: Expense, completion: @escaping () -> Void) {
        self.expense = expense
        _workingExpense = State(initialValue: EditableExpense(
            name: expense.name,
            amount: expense.amount,
            date: expense.date,
            category: expense.category,
            tag: expense.tag
        ))
        self.completion = completion
    }

    var body: some View {
        Form {
            TextField("Expense Name", text: $workingExpense.name)
            
            TextField("Amount", value: $workingExpense.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                .keyboardType(.decimalPad)
            
            DatePicker("Date", selection: $workingExpense.date, displayedComponents: .date)
            
            Picker("Category", selection: $workingExpense.category) {
                ForEach(ExpenseCategory.allCases, id: \.self) { option in
                    Text(option.rawValue)
                }
            }
            .pickerStyle(.segmented)
            
            Picker("Tag", selection: $workingExpense.tag) {
                ForEach(ExpenseTag.allCases, id: \.self) { option in
                    Text(option.rawValue)
                }
            }
        }
        .navigationTitle("Edit Expense")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                Button("Cancel") { completion() }
            }
            
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Save") { saveItem() }
            }
        }
    }
    
    func saveItem() {
        expense.name = workingExpense.name
        expense.amount = workingExpense.amount
        expense.date = workingExpense.date
        expense.category = workingExpense.category
        expense.tag = workingExpense.tag
        try! modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
        completion()
    }
}

#Preview {
    EditExpenseSheet(expense: Expense.example, completion: { })
}

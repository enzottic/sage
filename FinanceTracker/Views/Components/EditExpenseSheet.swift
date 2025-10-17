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
        ScrollView {
            VStack(spacing: 10) {
                HStack {
                    TextField("Expense Name", text: $workingExpense.name)
                        .font(.title)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                HStack {
                    TextField("Amount (\(Locale.current.currency?.identifier ?? "USD"))", value: $workingExpense.amount, format: .number)
                        .keyboardType(.decimalPad)
                        .font(.title)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                    
                DatePicker("Date", selection: $workingExpense.date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()

                VStack {
                    Text("Category")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    CategoryPicker(selectedCategory: $workingExpense.category)
                }
                
                VStack(spacing: 4) {
                    Text("Tag")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    TagPicker(selectedTag: $workingExpense.tag)
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

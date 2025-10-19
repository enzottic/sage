//
//  ExpenseDetailView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/11/25.
//
import SwiftUI
import SwiftData
import WidgetKit

struct ExpenseDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    let expense: Expense
    
    @State private var isEditing: Bool = false
    @State private var workingExpense: EditableExpense
    @State private var showingDeleteConfirmation: Bool = false

    init(expense: Expense) {
        self.expense = expense
        _workingExpense = State(initialValue: EditableExpense(
            name: expense.name,
            amount: expense.amount,
            date: expense.date,
            category: expense.category,
            tag: expense.tag
        ))
    }
    
    var body: some View {
        NavigationStack {
            ExpenseInfoForm(
                name: $workingExpense.name,
                amount: Binding<Double?>(
                    get: { workingExpense.amount },
                    set: { workingExpense.amount = $0 ?? 0 }
                ),
                date: $workingExpense.date,
                category: $workingExpense.category,
                tag: $workingExpense.tag,
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveItem()
                        dismiss()
                    }
                }
            }
        }
    }
    
    func saveItem() {
        expense.name = workingExpense.name
        expense.amount = workingExpense.amount ?? 0
        expense.date = workingExpense.date
        expense.category = workingExpense.category
        expense.tag = workingExpense.tag
        try! modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

private struct EditableExpense {
    var name: String
    var amount: Double?
    var date: Date
    var category: ExpenseCategory
    var tag: ExpenseTag
}

#Preview {
    @Previewable @State var expense = Expense.example
    ExpenseDetailView(expense: expense)
        .modelContainer(ModelContainer.preview)
}

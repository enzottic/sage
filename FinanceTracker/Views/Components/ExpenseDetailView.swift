//
//  ExpenseDetailView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/11/25.
//
import SwiftUI
import SwiftData
import WidgetKit
import SageKit

struct ExpenseDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    let expense: Expense
    
    @State private var isEditing: Bool = false
    @State private var workingExpense: EditableExpense
    @State private var showingDeleteConfirmation: Bool = false
    @State private var saveErrorMessage: String?

    init(expense: Expense) {
        self.expense = expense
        _workingExpense = State(initialValue: EditableExpense(
            name: expense.name,
            amount: expense.amount,
            date: expense.date,
            category: expense.category,
            tags: expense.tags ?? [],
            note: expense.note
        ))
    }
    
    var body: some View {
        ScrollView {
            ExpenseInfoForm(
                name: $workingExpense.name,
                amount: Binding<Double?>(
                    get: { workingExpense.amount },
                    set: { workingExpense.amount = $0 ?? 0 }
                ),
                date: $workingExpense.date,
                category: $workingExpense.category,
                tags: $workingExpense.tags,
                note: $workingExpense.note,
                isEditing: true
            )
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .background(.sageBackground)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Edit Expense")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveItem()
                }
                .accessibilityIdentifier("save-expense-changes-button")
                .tint(Color.sageAccent)
            }
        }
        .alert("Could not save expense", isPresented: Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveErrorMessage ?? "Please try again.")
        }
        .gradientBackground()
    }
    
    func saveItem() {
        expense.name = workingExpense.name
        expense.amount = workingExpense.amount ?? 0
        expense.date = workingExpense.date
        expense.category = workingExpense.category
        expense.tags = workingExpense.tags
        expense.note = workingExpense.note
        do {
            try modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
            dismiss()
        } catch {
            modelContext.rollback()
            saveErrorMessage = error.localizedDescription
        }
    }
}

private struct EditableExpense {
    var name: String
    var amount: Double?
    var date: Date
    var category: ExpenseCategory
    var tags: [ExpenseTag]
    var note: String
}

#Preview {
    @Previewable @State var expense = Expense.example
    ExpenseDetailView(expense: expense)
        .environmentInjection()
}

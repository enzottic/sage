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
    @Environment(AppRouter.self) private var appRouter
    
    let expense: Expense
    
    @State private var isEditing: Bool = false
    @State private var workingExpense: EditableExpense
    @State private var showingDeleteConfirmation: Bool = false
    @State private var saveErrorMessage: String?
    @State private var isSaving = false

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
                if isSaving {
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityLabel("Saving expense")
                } else {
                    Button("Save") {
                        Task { await saveItem() }
                    }
                    .accessibilityIdentifier("save-expense-changes-button")
                    .tint(Color.sageAccent)
                    .disabled(isSaving)
                }
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
    
    private func saveItem() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        await Task.yield()

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
            appRouter.showToast(SageToast(message: "Expense updated", kind: .success))
        } catch {
            modelContext.rollback()
            saveErrorMessage = "Sage could not save this expense. Check available storage and try again."
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

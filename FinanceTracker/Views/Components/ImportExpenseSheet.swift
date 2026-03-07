//
//  ImportExpenseSheet.swift
//  FinanceTracker
//
//  Created by Claude on 2/22/26.
//

import SwiftUI
import SwiftData
import WidgetKit

struct ImportExpenseSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let splitwiseExpense: SplitwiseExpense
    let owedShare: Double

    @State private var name: String
    @State private var amount: Double?
    @State private var date: Date
    @State private var category: ExpenseCategory = .wants
    @State private var tag: ExpenseTag? = nil
    @State private var note: String = "Imported from Splitwise"

    @State private var errorMessage: String?
    @State private var showError = false
    @State private var isSaving = false

    init(splitwiseExpense: SplitwiseExpense, owedShare: Double) {
        self.splitwiseExpense = splitwiseExpense
        self.owedShare = owedShare
        _name = State(initialValue: splitwiseExpense.description)
        _amount = State(initialValue: owedShare)
        _date = State(initialValue: splitwiseExpense.parsedDate ?? Date.now)
    }

    var body: some View {
        NavigationStack {
            ExpenseInfoForm(
                name: $name,
                amount: $amount,
                date: $date,
                category: $category,
                tag: $tag,
                note: $note
            )
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Import") { saveItem() }
                        .disabled(isSaving)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unexpected error occurred")
            }
        }
    }

    private func saveItem() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter an expense name"
            showError = true
            return
        }

        guard let expenseAmount = amount, expenseAmount > 0 else {
            errorMessage = "Please enter a valid amount"
            showError = true
            return
        }

        isSaving = true

        let newExpense = Expense(
            name: name,
            amount: expenseAmount,
            category: category,
            date: date,
            tag: tag,
            note: note
        )

        modelContext.insert(newExpense)

        do {
            try modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
            dismiss()
        } catch {
            isSaving = false
            errorMessage = "Failed to save expense: \(error.localizedDescription)"
            showError = true
        }
    }
}

#Preview {
    let sampleExpense = SplitwiseExpense(
        id: 1,
        groupId: nil,
        description: "Dinner at Restaurant",
        cost: "45.00",
        currencyCode: "USD",
        date: "2026-02-20",
        createdAt: "2026-02-20T12:00:00Z",
        updatedAt: "2026-02-20T12:00:00Z",
        deletedAt: nil,
        category: SplitwiseCategory(id: 1, name: "Food"),
        users: []
    )
    ImportExpenseSheet(splitwiseExpense: sampleExpense, owedShare: 22.50)
        .modelContainer(ModelContainer.preview)
}

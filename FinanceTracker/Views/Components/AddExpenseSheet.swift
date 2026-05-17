//
//  AddExpenseSheet.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/4/25.
//
import SwiftUI
import SwiftData
import WidgetKit

struct AddExpenseSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showDatePopover: Bool = false
    @State private var name: String = ""
    @State private var amount: Double? = nil
    @State private var date: Date = Date.now
    @State private var category: ExpenseCategory = .needs
    @State private var tag: ExpenseTag? = nil
    @State private var note: String = ""
    @State private var isRecurring: Bool = false
    @State private var recurrenceFrequency: RecurrenceFrequency = .monthly
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ExpenseInfoForm(name: $name, amount: $amount, date: $date, category: $category, tag: $tag, note: $note)
            
            Divider()
                .padding(.horizontal)

            HStack {
                Toggle("Recurring", isOn: $isRecurring.animation())
                    .labelsHidden()
                
                Text("Recurring")
                    .font(.subheadline)
                    .foregroundStyle(isRecurring ? .primary : .secondary)

                if isRecurring {
                    Spacer()

                    Picker("Frequency", selection: $recurrenceFrequency) {
                        ForEach(RecurrenceFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.primary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Save") { saveItem() }
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
    
    func saveItem() {
        // Validate input
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

        // Start saving
        isSaving = true

        // Create recurring rule if toggled on
        var recurringId: UUID? = nil
        if isRecurring {
            let rule = RecurringExpenseRule(
                name: name,
                amount: expenseAmount,
                note: note,
                category: category,
                tag: tag,
                frequency: recurrenceFrequency,
                startDate: date,
                lastGeneratedDate: date
            )
            recurringId = rule.id
            modelContext.insert(rule)
        }

        // Create and save expense
        let newExpense = Expense(
            name: name,
            amount: expenseAmount,
            category: category,
            date: date,
            tag: tag,
            recurringExpenseId: recurringId
        )

        modelContext.insert(newExpense)

        do {
            try modelContext.save()

            // Success - reload widgets and dismiss
            WidgetCenter.shared.reloadAllTimelines()
            dismiss()

        } catch {
            // Handle error
            isSaving = false
            errorMessage = "Failed to save expense: \(error.localizedDescription)"
            showError = true

            #if DEBUG
            print("Failed to save expense: \(error)")
            #endif
        }
    }
}

#Preview {
    AddExpenseSheet()
        .modelContainer(previewAppContainer)
}


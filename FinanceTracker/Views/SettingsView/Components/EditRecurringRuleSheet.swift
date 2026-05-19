//
//  EditRecurringRuleSheet.swift
//  FinanceTracker
//
import SwiftUI
import SwiftData
import WidgetKit

struct EditRecurringRuleSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let rule: RecurringExpenseRule

    @State private var name: String
    @State private var amount: Double?
    @State private var note: String
    @State private var category: ExpenseCategory
    @State private var tag: ExpenseTag?
    @State private var frequency: RecurrenceFrequency
    @State private var hasEndDate: Bool
    @State private var endDate: Date

    @State private var showError = false
    @State private var errorMessage: String?

    init(rule: RecurringExpenseRule) {
        self.rule = rule
        _name = State(initialValue: rule.name)
        _amount = State(initialValue: rule.amount)
        _note = State(initialValue: rule.note)
        _category = State(initialValue: rule.category)
        _tag = State(initialValue: rule.tag)
        _frequency = State(initialValue: rule.frequency)
        _hasEndDate = State(initialValue: rule.endDate != nil)
        _endDate = State(initialValue: rule.endDate ?? Calendar.current.date(byAdding: .month, value: 1, to: Date.now)!)
    }

    var body: some View {
        NavigationStack {
            ExpenseInfoForm(
                name: $name,
                amount: $amount,
                date: .constant(rule.startDate),
                category: $category,
                tag: $tag,
                note: $note
            )

            Divider()
                .padding(.horizontal)

            VStack(spacing: 12) {
                HStack {
                    Text("Frequency")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Picker("Frequency", selection: $frequency) {
                        ForEach(RecurrenceFrequency.allCases, id: \.self) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.primary)
                }

                Toggle(isOn: $hasEndDate.animation()) {
                    Text("End Date")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if hasEndDate {
                    DatePicker(
                        "Ends on",
                        selection: $endDate,
                        in: rule.startDate...,
                        displayedComponents: .date
                    )
                    .font(.subheadline)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveChanges() }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An unexpected error occurred")
            }
        }
    }

    private func saveChanges() {
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

        rule.name = name
        rule.amount = expenseAmount
        rule.note = note
        rule.category = category
        rule.tag = tag
        rule.frequency = frequency
        rule.endDate = hasEndDate ? endDate : nil

        do {
            try modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
            dismiss()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            showError = true
        }
    }
}

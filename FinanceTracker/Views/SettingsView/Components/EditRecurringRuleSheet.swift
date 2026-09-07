//
//  EditRecurringRuleSheet.swift
//  FinanceTracker
//
import SwiftUI
import SwiftData
import WidgetKit
import SageKit

struct EditRecurringRuleSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let rule: RecurringExpenseRule

    @State private var name: String
    @State private var amount: Double?
    @State private var note: String
    @State private var category: ExpenseCategory
    @State private var tags: [ExpenseTag]
    @State private var frequency: RecurrenceFrequency
    @State private var hasEndDate: Bool
    @State private var endDate: Date
    @State private var useFixedSchedule = false
    @State private var timeZoneIdentifier: String
    @State private var showScheduleConfirmation = false

    @State private var showError = false
    @State private var errorMessage: String?

    init(rule: RecurringExpenseRule) {
        self.rule = rule
        _name = State(initialValue: rule.name)
        _amount = State(initialValue: rule.amount)
        _note = State(initialValue: rule.note)
        _category = State(initialValue: rule.category)
        _tags = State(initialValue: rule.tags ?? [])
        _frequency = State(initialValue: rule.frequency)
        _hasEndDate = State(initialValue: rule.endDate != nil)
        _endDate = State(initialValue: rule.endDate ?? Calendar.current.date(byAdding: .month, value: 1, to: Date.now) ?? Date.now)
        _timeZoneIdentifier = State(initialValue: rule.recurrenceTimeZoneIdentifier ?? TimeZone.current.identifier)
    }

    var body: some View {
        NavigationStack {
            ExpenseInfoForm(
                name: $name,
                amount: $amount,
                date: .constant(rule.startDate),
                category: $category,
                tags: $tags,
                note: $note
            )

            Divider()
                .padding(.horizontal)

            ScrollView {
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

                    if rule.recurrenceTimeZoneIdentifier == nil {
                        Toggle("Use Fixed Schedule", isOn: $useFixedSchedule)
                        Text("This existing rule uses each device's calendar and time zone. Monthly dates can drift after a shorter month. Keep this off to leave its scheduling unchanged.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if useFixedSchedule || rule.recurrenceTimeZoneIdentifier != nil {
                        Picker("Time Zone", selection: $timeZoneIdentifier) {
                            ForEach(Array(Set(TimeZone.knownTimeZoneIdentifiers + [timeZoneIdentifier, TimeZone.current.identifier])).sorted(), id: \.self) { identifier in
                                Text(identifier.replacingOccurrences(of: "_", with: " ")).tag(identifier)
                            }
                        }
                        .pickerStyle(.menu)
                        Text("Uses the Gregorian calendar and this time zone on every device. Monthly dates return to the original start day after shorter months.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
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
            .confirmationDialog("Update Future Schedule?", isPresented: $showScheduleConfirmation, titleVisibility: .visible) {
                Button("Update Future Schedule") { saveChanges(scheduleConfirmed: true) }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Use the Gregorian calendar in \(timeZoneIdentifier). Existing expenses and their identities stay unchanged. Past catch-up is skipped. Monthly rules already started resume after this month or the latest recorded occurrence's month, whichever is later. Other frequencies resume after that date on their cadence. Future start dates are kept. Update Syl on every synced device first; older versions do not honor this schedule.")
            }
        }
    }

    private func saveChanges(scheduleConfirmed: Bool = false) {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter an expense name"
            showError = true
            return
        }
        let currencyCode: String
        do {
            currencyCode = try LedgerCurrency.requireCode()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            return
        }
        guard let expenseAmount = amount,
              MonetaryAmount.isValid(expenseAmount, currencyCode: currencyCode, requiresPositive: true) else {
            errorMessage = MonetaryAmount.validationMessage(currencyCode: currencyCode, requiresPositive: true)
            showError = true
            return
        }

        let changesSchedule = (rule.recurrenceTimeZoneIdentifier == nil && useFixedSchedule)
            || (rule.recurrenceTimeZoneIdentifier != nil && rule.recurrenceTimeZoneIdentifier != timeZoneIdentifier)
        if changesSchedule && !scheduleConfirmed {
            showScheduleConfirmation = true
            return
        }

        // Fetch before mutating the rule; confirmation alone must not persist any changes.
        let existingExpenses: [Expense]
        do {
            if changesSchedule {
                existingExpenses = try modelContext.fetch(FetchDescriptor<Expense>())
            } else {
                existingExpenses = []
            }
        } catch {
            errorMessage = "Could not check existing occurrences: \(error.localizedDescription)"
            showError = true
            return
        }
        guard let timeZone = TimeZone(identifier: timeZoneIdentifier) else {
            errorMessage = "Please choose a valid time zone."
            showError = true
            return
        }

        rule.name = name
        rule.amount = expenseAmount
        rule.note = note
        rule.category = category
        rule.tags = tags
        rule.frequency = frequency
        rule.endDate = hasEndDate ? endDate : nil
        if changesSchedule {
            rule.enableFixedSchedule(in: timeZone, after: .now, existingExpenses: existingExpenses)
        }

        do {
            try modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
            dismiss()
        } catch {
            modelContext.rollback()
            errorMessage = "Failed to save: \(error.localizedDescription)"
            showError = true
        }
    }
}

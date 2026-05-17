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
    @Environment(SplitwiseService.self) private var splitwise

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

    // Splitwise
    @State private var splitwiseEnabled: Bool = false
    @State private var selectedGroupId: Int? = nil
    @State private var availableGroups: [SplitwiseGroup] = []
    @State private var isLoadingGroups: Bool = false

    private var selectedGroup: SplitwiseGroup? {
        availableGroups.first { $0.id == selectedGroupId }
    }

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    var body: some View {
        NavigationStack {
            ExpenseInfoForm(name: $name, amount: $amount, date: $date, category: $category, tag: $tag, note: $note)

            Divider()
                .padding(.horizontal)

            VStack(spacing: 0) {
                optionRow(
                    isOn: $isRecurring.animation(),
                    label: "Recurring",
                    trailing: {
                        if isRecurring {
                            Picker("Frequency", selection: $recurrenceFrequency) {
                                ForEach(RecurrenceFrequency.allCases, id: \.self) { freq in
                                    Text(freq.rawValue).tag(freq)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.primary)
                        }
                    }
                )

                if splitwise.isConnected {
                    Divider()
                        .padding(.leading)

                    optionRow(
                        isOn: $splitwiseEnabled.animation(),
                        label: "Split with Splitwise",
                        trailing: {
                            if splitwiseEnabled {
                                if isLoadingGroups {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Picker("Group", selection: $selectedGroupId) {
                                        Text("Select group").tag(Optional<Int>.none)
                                        ForEach(availableGroups) { group in
                                            Text(group.name).tag(Optional(group.id))
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(.primary)
                                }
                            }
                        }
                    )

                    if splitwiseEnabled, let total = amount {
                        HStack {
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Total  \(total.formatted(.currency(code: currencyCode)))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("Your share  \((total / 2).formatted(.currency(code: currencyCode)))")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.ui.sage)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .padding(.bottom, 8)
            .onChange(of: splitwiseEnabled) { _, enabled in
                if enabled && availableGroups.isEmpty {
                    Task { await loadGroups() }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Save") { Task { await saveItem() } }
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

    @ViewBuilder
    private func optionRow<Trailing: View>(
        isOn: Binding<Bool>,
        label: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack {
            Toggle(label, isOn: isOn)
                .labelsHidden()

            Text(label)
                .font(.subheadline)
                .foregroundStyle(isOn.wrappedValue ? .primary : .secondary)

            Spacer()

            trailing()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private func loadGroups() async {
        isLoadingGroups = true
        do {
            availableGroups = try await splitwise.fetchGroups()
        } catch {
            errorMessage = "Couldn't load Splitwise groups: \(error.localizedDescription)"
            showError = true
            splitwiseEnabled = false
        }
        isLoadingGroups = false
    }

    func saveItem() async {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter an expense name"
            showError = true
            return
        }

        guard let total = amount, total > 0 else {
            errorMessage = "Please enter a valid amount"
            showError = true
            return
        }

        let saveAmount = (splitwiseEnabled && selectedGroup != nil) ? total / 2 : total

        isSaving = true

        // Post to Splitwise before saving locally so any auth errors surface first
        if splitwiseEnabled, let group = selectedGroup {
            do {
                let req = CreateSplitwiseExpenseRequest(
                    cost: String(format: "%.2f", total),
                    description: name,
                    groupId: group.id,
                    splitEqually: true
                )
                try await splitwise.createExpense(req: req)
            } catch {
                isSaving = false
                errorMessage = "Couldn't add to Splitwise: \(error.localizedDescription)"
                showError = true
                return
            }
        }

        var recurringId: UUID? = nil
        if isRecurring {
            let rule = RecurringExpenseRule(
                name: name,
                amount: saveAmount,
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

        let newExpense = Expense(
            name: name,
            amount: saveAmount,
            category: category,
            date: date,
            tag: tag,
            recurringExpenseId: recurringId
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
    AddExpenseSheet()
        .modelContainer(previewAppContainer)
        .environment(SplitwiseService())
        .environment(AppConfiguration())
}

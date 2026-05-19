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
    @Environment(AppRouter.self) private var appRouter

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
            ScrollView {
                VStack(spacing: 24) {
                    ExpenseInfoForm(
                        name: $name,
                        amount: $amount,
                        date: $date,
                        category: $category,
                        tag: $tag,
                        note: $note,
                        autoFocusAmount: true
                    )

                    optionsCard
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") { Task { await saveItem() } }
                            .fontWeight(.semibold)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unexpected error occurred")
            }
            .task {
                if splitwise.isConnected {
                    await loadGroups()
                }
            }
        }
    }

    // MARK: - Options card

    private var optionsCard: some View {
        VStack(spacing: 0) {
            // Recurring row
            HStack(spacing: 12) {
                Toggle("Recurring", isOn: $isRecurring.animation())
                    .labelsHidden()
                Text("Recurring")
                    .font(.subheadline)
                    .foregroundStyle(isRecurring ? .primary : .secondary)
                Spacer()
                if isRecurring {
                    Picker("", selection: $recurrenceFrequency) {
                        ForEach(RecurrenceFrequency.allCases, id: \.self) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if splitwise.isConnected {
                Divider()
                    .padding(.leading, 56)

                // Splitwise row
                HStack {
                    Text("Splitwise")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if isLoadingGroups {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Picker("Splitwise", selection: $selectedGroupId) {
                            Text("No split").tag(Optional<Int>.none)
                            ForEach(availableGroups) { group in
                                Text(group.name).tag(Optional(group.id))
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(selectedGroupId == nil ? .secondary : .primary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // Split summary
                if selectedGroupId != nil, let total = amount {
                    Divider()
                        .padding(.leading, 16)

                    HStack(spacing: 24) {
                        Spacer()
                        VStack(spacing: 2) {
                            Text("Total")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Text(total.formatted(.currency(code: currencyCode)))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .strikethrough()
                        }
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        VStack(spacing: 2) {
                            Text("Your share")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Text((total / 2).formatted(.currency(code: currencyCode)))
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.ui.sage)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .background(Color.ui.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .animation(.spring(duration: 0.3), value: selectedGroupId)
        .animation(.spring(duration: 0.3), value: amount)
    }

    // MARK: - Logic

    private func loadGroups() async {
        isLoadingGroups = true
        do {
            availableGroups = try await splitwise.fetchGroups()
        } catch {
            errorMessage = "Couldn't load Splitwise groups: \(error.localizedDescription)"
            showError = true
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

        let saveAmount = selectedGroup != nil ? total / 2 : total

        isSaving = true

        if let group = selectedGroup {
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
            note: note,
            recurringExpenseId: recurringId
        )

        modelContext.insert(newExpense)

        do {
            try modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
            dismiss()
            appRouter.showToast(SageToast(message: "Expense saved", kind: .success))
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
        .environment(AppRouter())
}

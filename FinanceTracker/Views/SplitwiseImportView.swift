//
//  SplitwiseImportView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 5/16/26.
//
import SwiftUI
import SwiftData
import WidgetKit

struct SplitwiseImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SplitwiseService.self) private var splitwise

    @State private var expenses: [SplitwiseFetchedExpense] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedExpense: SplitwiseFetchedExpense?
    @State private var importedIds: Set<Int> = []

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Fetching expenses…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage {
                    ContentUnavailableView {
                        Label("Couldn't Load", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button("Retry") { Task { await load() } }
                            .buttonStyle(.borderedProminent)
                    }
                } else if expenses.isEmpty {
                    ContentUnavailableView(
                        "No Expenses",
                        systemImage: "checkmark.circle",
                        description: Text("No recent Splitwise expenses found.")
                    )
                } else {
                    List(expenses) { expense in
                        SplitwiseExpenseRow(
                            expense: expense,
                            userId: splitwise.currentUserId ?? 0,
                            isImported: importedIds.contains(expense.id)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard !importedIds.contains(expense.id) else { return }
                            selectedExpense = expense
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Import from Splitwise")
            .navigationBarTitleDisplayMode(.inline)
            .task { await load() }
            .sheet(item: $selectedExpense) { expense in
                SplitwiseImportConfirmSheet(
                    expense: expense,
                    userId: splitwise.currentUserId ?? 0
                ) { newExpense in
                    modelContext.insert(newExpense)
                    try? modelContext.save()
                    WidgetCenter.shared.reloadAllTimelines()
                    importedIds.insert(expense.id)
                    selectedExpense = nil
                }
            }
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let all = try await splitwise.fetchExpenses()
            let userId = splitwise.currentUserId ?? 0
            expenses = all.filter { $0.owedAmount(forUserId: userId) > 0 }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Row

private struct SplitwiseExpenseRow: View {
    let expense: SplitwiseFetchedExpense
    let userId: Int
    let isImported: Bool

    var owedAmount: Double { expense.owedAmount(forUserId: userId) }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.description)
                    .font(.headline)
                    .foregroundStyle(isImported ? .secondary : .primary)
                Text(expense.date, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isImported {
                Label("Added", systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.green)
                    .labelStyle(.iconOnly)
                    .imageScale(.large)
            } else {
                Text(owedAmount, format: .currency(code: expense.currencyCode))
                    .font(.headline)
                    .foregroundStyle(Color.ui.sage)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Import Confirm Sheet

private struct SplitwiseImportConfirmSheet: View {
    let expense: SplitwiseFetchedExpense
    let onImport: (Expense) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var amount: Double?
    @State private var date: Date
    @State private var category: ExpenseCategory = .wants
    @State private var tag: ExpenseTag? = nil
    @State private var note: String = ""

    init(expense: SplitwiseFetchedExpense, userId: Int, onImport: @escaping (Expense) -> Void) {
        self.expense = expense
        self.onImport = onImport
        _name = State(initialValue: expense.description)
        _amount = State(initialValue: expense.owedAmount(forUserId: userId))
        _date = State(initialValue: expense.date)
    }

    var canImport: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (amount ?? 0) > 0
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
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Import") {
                        guard let amt = amount, canImport else { return }
                        onImport(Expense(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            amount: amt,
                            category: category,
                            date: date,
                            tag: tag,
                            note: note
                        ))
                    }
                    .fontWeight(.semibold)
                    .disabled(!canImport)
                }
            }
        }
        .presentationDetents([.large])
        .presentationBackground(Color.ui.background)
    }
}

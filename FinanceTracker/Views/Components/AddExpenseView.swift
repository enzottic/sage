//
//  AddExpenseSheet.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/4/25.
//
import SwiftUI
import SwiftData
import WidgetKit
import SageKit

struct AddExpenseView: View {
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
    @State private var isParsingReceipt: Bool = false

    @Query private var allTags: [ExpenseTag]
    
    init(expense: Expense?) {
        if let expense = expense {
            _name = State(initialValue: expense.name)
            _amount = State(initialValue: expense.amount)
            _tag = State(initialValue: expense.tag ?? nil)
            _category = State(initialValue: expense.category)
        }
    }

    private var selectedGroup: SplitwiseGroup? {
        availableGroups.first { $0.id == selectedGroupId }
    }

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ExpenseInfoForm(
                    name: $name,
                    amount: $amount,
                    date: $date,
                    category: $category,
                    tag: $tag,
                    note: $note
                )

                optionsCard
            }
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .background(.sageBackground)
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("New Expense")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if isSaving {
                    ProgressView()
                } else {
                    Button("Save") { Task { await saveItem() } }
                        .fontWeight(.semibold)
                        .tint(Color(red: 108 / 255, green: 138 / 255, blue: 78 / 255))
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
            await parseReceiptIfNeeded()
        }
        .overlay {
            if isParsingReceipt {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(.white)
                        Text("Reading receipt…")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .gradientBackground()
    }

    // MARK: - Options card

    private var optionsCard: some View {
        VStack(spacing: 0) {
            // Recurring row
            HStack(spacing: 12) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
                Text("Recurring")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Spacer()
                Toggle("", isOn: $isRecurring.animation(.spring(duration: 0.3)))
                    .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if isRecurring {
                Divider()
                    .padding(.leading, 52)

                HStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    Text("Frequency")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Picker("", selection: $recurrenceFrequency) {
                        ForEach(RecurrenceFrequency.allCases, id: \.self) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

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
                                .foregroundStyle(.sage)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .background(.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .animation(.spring(duration: 0.3), value: selectedGroupId)
        .animation(.spring(duration: 0.3), value: amount)
        .animation(.spring(duration: 0.3), value: isRecurring)
    }

    // MARK: - Logic

    private func parseReceiptIfNeeded() async {
        guard let image = ReceiptHandoffService.consumePendingImage() else { return }
        isParsingReceipt = true
        defer { isParsingReceipt = false }

        if #available(iOS 26.0, *) {
            let service = ReceiptParserService()
            guard let parsed = await service.parseReceipt(image: image, tags: allTags) else { return }

            name = parsed.name
            amount = parsed.price

            if let dateStr = parsed.date {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                date = formatter.date(from: dateStr) ?? .now
            }

            category = parsed.category.lowercased() == "needs" ? .needs : .wants

            if let tagName = parsed.tag {
                tag = allTags.first { $0.name == tagName }
            }
        }
    }

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
    AddExpenseView(expense: nil)
        .environmentInjection()
}

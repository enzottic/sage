//
//  AddExpenseSheet.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/4/25.
//
import SwiftUI
import SwiftData
import WidgetKit
import PhotosUI
import UIKit
import FoundationModels
import SageKit

struct AddExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(AppRouter.self) private var appRouter

    @State private var name: String = ""
    @State private var amount: Double? = nil
    @State private var date: Date = Date.now
    @State private var category: ExpenseCategory = .needs
    @State private var tags: [ExpenseTag] = []
    @State private var note: String = ""
    @State private var isRecurring: Bool = false
    @State private var recurrenceFrequency: RecurrenceFrequency = .monthly
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var isSaving = false
    @State private var isNameFieldFocused = false
    @State private var keyboardDismissalRequest = 0
    @State private var debouncedName = ""
    @State private var nameDebounceTask: Task<Void, Never>?

    @State private var isParsingReceipt: Bool = false
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var receiptPhotoItem: PhotosPickerItem?
    private let initialReceiptData: Data?

    @Query private var allTags: [ExpenseTag]
    @Query(sort: \Expense.date, order: .reverse) private var pastExpenses: [Expense]
    
    init(expense: Expense?, receiptData: Data? = nil) {
        initialReceiptData = receiptData
        if let expense = expense {
            _name = State(initialValue: expense.name)
            _amount = State(initialValue: expense.amount)
            _tags = State(initialValue: expense.tags ?? [])
            _category = State(initialValue: expense.category)
        }
    }

    private var receiptImportUnavailableMessage: String? {
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.isAvailable
                ? nil
                : "Receipt reading requires Apple Intelligence on this device."
        }

        return nil
    }

    private var receiptImportConfiguration: ReceiptImportConfiguration? {
        guard receiptImportUnavailableMessage == nil else { return nil }

        return ReceiptImportConfiguration(
            isParsing: isParsingReceipt,
            canUseCamera: UIImagePickerController.isSourceTypeAvailable(.camera),
            onTakePhoto: {
                guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                    showReceiptError("This device does not have a camera. Choose a photo from your library instead.")
                    return
                }
                showCamera = true
            },
            onChoosePhoto: { showPhotoLibrary = true }
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ExpenseInfoForm(
                    name: $name,
                    amount: $amount,
                    date: $date,
                    category: $category,
                    tags: $tags,
                    note: $note,
                    isNameFieldFocused: $isNameFieldFocused,
                    keyboardDismissalRequest: $keyboardDismissalRequest,
                    receiptImport: receiptImportConfiguration,
                    receiptImportUnavailableMessage: receiptImportUnavailableMessage
                )

                optionsCard
                    .simultaneousGesture(
                        TapGesture().onEnded { keyboardDismissalRequest += 1 }
                    )
            }
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .background(.sageBackground)
        .scrollDismissesKeyboard(.immediately)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if showsPastExpenseSuggestions {
                pastExpenseSuggestionList
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(
            reduceMotion ? nil : .spring(duration: 0.32, bounce: 0.18),
            value: showsPastExpenseSuggestions
        )
        .navigationTitle("New Expense")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .accessibilityIdentifier("cancel-expense-button")
            }
            ToolbarItem(placement: .topBarTrailing) {
                if isSaving {
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityLabel("Saving expense")
                } else {
                    Button("Save") { Task { await saveItem() } }
                        .accessibilityIdentifier("save-expense-button")
                        .fontWeight(.semibold)
                        .tint(Color(red: 108 / 255, green: 138 / 255, blue: 78 / 255))
                        .disabled(isParsingReceipt || isSaving)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unexpected error occurred")
        }
        .photosPicker(
            isPresented: $showPhotoLibrary,
            selection: $receiptPhotoItem,
            matching: .images
        )
        .onChange(of: receiptPhotoItem) { _, item in
            guard let item else { return }
            Task { await loadReceiptPhoto(item) }
        }
        .onChange(of: name) { _, newValue in
            nameDebounceTask?.cancel()
            nameDebounceTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
                debouncedName = newValue
            }
        }
        .onDisappear {
            nameDebounceTask?.cancel()
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerView(
                onImagePicked: { image in
                    Task { await parseReceipt(image) }
                },
                onFailure: showReceiptError
            )
            .ignoresSafeArea()
        }
        .task {
            guard let initialReceiptData else { return }
            guard let image = UIImage(data: initialReceiptData) else {
                showReceiptError("Sage couldn't open the shared receipt.")
                return
            }
            await parseReceipt(image)
        }
        .gradientBackground()
    }

    private var pastExpenseSuggestions: [Expense] {
        let trimmedName = debouncedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return [] }

        let lowercasedName = trimmedName.lowercased()
        var seenNames = Set<String>()
        return pastExpenses.filter { expense in
            let key = expense.name.lowercased()
            guard key.contains(lowercasedName), !seenNames.contains(key) else { return false }
            seenNames.insert(key)
            return true
        }
        .prefix(3)
        .map { $0 }
    }

    private var showsPastExpenseSuggestions: Bool {
        isNameFieldFocused && !pastExpenseSuggestions.isEmpty
    }

    private var pastExpenseSuggestionList: some View {
        VStack(spacing: 0) {
            ForEach(Array(pastExpenseSuggestions.enumerated()), id: \.element.id) { index, expense in
                if index > 0 {
                    Divider().padding(.leading, 56)
                }

                Button {
                    name = expense.name
                    amount = expense.amount
                    category = expense.category
                    tags = expense.tags ?? []
                    isNameFieldFocused = false
                } label: {
                    HStack(spacing: 12) {
                        if let tag = expense.tags?.first {
                            TagGlyphView(tag: tag)
                                .font(.system(size: 20))
                                .foregroundStyle(tag.color)
                                .frame(width: 36, height: 36)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Image(systemName: "clock")
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                                .frame(width: 36, height: 36)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(expense.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                            HStack(spacing: 4) {
                                Text(expense.category.rawValue)
                                let tagNames = (expense.tags ?? []).map(\.name).joined(separator: ", ")
                                if !tagNames.isEmpty {
                                    Text("·")
                                    Text(tagNames)
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(expense.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .background(.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 14, y: 6)
        .accessibilityIdentifier("past-expense-suggestions")
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

        }
        .background(.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .animation(.spring(duration: 0.3), value: amount)
        .animation(.spring(duration: 0.3), value: isRecurring)
    }

    // MARK: - Logic

    private func loadReceiptPhoto(_ item: PhotosPickerItem) async {
        defer { receiptPhotoItem = nil }

        do {
            guard
                let data = try await item.loadTransferable(type: Data.self),
                let image = UIImage(data: data)
            else {
                showReceiptError("Sage couldn't open that photo.")
                return
            }

            await parseReceipt(image)
        } catch {
            showReceiptError("Sage couldn't open that photo. Choose another photo and try again.")
        }
    }

    private func parseReceipt(_ image: UIImage) async {
        guard !isParsingReceipt, !isSaving else { return }
        isParsingReceipt = true
        defer { isParsingReceipt = false }

        guard receiptImportUnavailableMessage == nil else {
            showReceiptError(receiptImportUnavailableMessage ?? "Receipt reading is unavailable.")
            return
        }

        if #available(iOS 26.0, *) {
            do {
                let parsed = try await ReceiptParserService().parseReceipt(image: image, tags: allTags)
                name = parsed.name
                amount = parsed.price

                if let dateStr = parsed.date {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    date = formatter.date(from: dateStr) ?? .now
                }

                category = parsed.category.lowercased() == "needs" ? .needs : .wants

                if let tagName = parsed.tag, let matched = allTags.first(where: { $0.name == tagName }) {
                    tags = [matched]
                }
            } catch let error as ReceiptParserError {
                showReceiptError(error.localizedDescription)
            } catch {
                showReceiptError("Sage couldn't read this receipt. Try again later.")
            }
        }
    }

    private func showReceiptError(_ message: String) {
        errorMessage = message
        showError = true
    }

    func saveItem() async {
        guard !isSaving else { return }

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

        isSaving = true
        defer { isSaving = false }

        await Task.yield()

        var recurringId: UUID? = nil
        if isRecurring {
            let rule = RecurringExpenseRule(
                name: name,
                amount: total,
                note: note,
                category: category,
                tags: tags,
                frequency: recurrenceFrequency,
                startDate: date,
                lastGeneratedDate: date
            )
            recurringId = rule.id
            modelContext.insert(rule)
        }

        let newExpense = Expense(
            name: name,
            amount: total,
            category: category,
            date: date,
            tags: tags,
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
            modelContext.rollback()
            errorMessage = "Sage could not save this expense. Check available storage and try again."
            showError = true
        }
    }
}

#Preview {
    AddExpenseView(expense: nil)
        .environmentInjection()
}

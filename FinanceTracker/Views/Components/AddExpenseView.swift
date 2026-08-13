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
import SageKit

struct AddExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
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

    @State private var isParsingReceipt: Bool = false
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var receiptPhotoItem: PhotosPickerItem?

    @Query private var allTags: [ExpenseTag]
    
    init(expense: Expense?) {
        if let expense = expense {
            _name = State(initialValue: expense.name)
            _amount = State(initialValue: expense.amount)
            _tags = State(initialValue: expense.tags ?? [])
            _category = State(initialValue: expense.category)
        }
    }

    private var receiptImportEnabled: Bool {
        if #available(iOS 26.0, *) { true } else { false }
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
                    receiptImport: receiptImportEnabled
                        ? ReceiptImportConfiguration(
                            isParsing: isParsingReceipt,
                            onTakePhoto: { showCamera = true },
                            onChoosePhoto: { showPhotoLibrary = true }
                        )
                        : nil
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
                        .disabled(isParsingReceipt)
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
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerView { image in
                Task { await parseReceipt(image) }
            }
            .ignoresSafeArea()
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
            showReceiptError("Sage couldn't open that photo: \(error.localizedDescription)")
        }
    }

    private func parseReceipt(_ image: UIImage) async {
        guard !isParsingReceipt else { return }
        isParsingReceipt = true
        defer { isParsingReceipt = false }

        if #available(iOS 26.0, *) {
            let service = ReceiptParserService()
            guard let parsed = await service.parseReceipt(image: image, tags: allTags) else {
                showReceiptError("Sage couldn't read this receipt. Try a clearer photo.")
                return
            }

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
        } else {
            showReceiptError("Receipt reading requires iOS 26 or later.")
        }
    }

    private func showReceiptError(_ message: String) {
        errorMessage = message
        showError = true
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

        isSaving = true

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

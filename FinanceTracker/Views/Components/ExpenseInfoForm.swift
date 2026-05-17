//
//  ExpenseInfoForm.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/16/25.
//

import SwiftUI
import SwiftData

struct ExpenseInfoForm: View {

    @Binding var name: String
    @Binding var amount: Double?
    @Binding var date: Date
    @Binding var category: ExpenseCategory
    @Binding var tag: ExpenseTag?
    @Binding var note: String
    var autoFocusAmount: Bool = false

    private let tagSuggestionService = TagSuggestionService()
    @Environment(AppConfiguration.self) private var config
    @Query(sort: \ExpenseTag.name) private var expenseTags: [ExpenseTag]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @FocusState private var focusedField: Field?
    @State private var tagIsAISuggested = false

    private enum Field: Hashable { case name, note }

    var body: some View {
        VStack(spacing: 24) {
            CentsFirstCurrencyField(amount: $amount, autoFocus: autoFocusAmount)

            basicInfoCard

            CategoryPicker(selectedCategory: $category)

            TagPicker(selectedTag: $tag, tagIsAISuggested: tagIsAISuggested)
        }
        .onChange(of: tag) { _, _ in tagIsAISuggested = false }
    }

    private var basicInfoCard: some View {
        VStack(spacing: 0) {
            TextField("Expense name", text: $name)
                .font(.body)
                .focused($focusedField, equals: .name)
                .onChange(of: focusedField) { old, _ in
                    if old == .name { suggestTagIfNeeded() }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

            Divider()
                .padding(.leading, 16)

            HStack {
                Text("Date")
                    .foregroundStyle(.secondary)
                Spacer()
                DatePicker("", selection: $date, displayedComponents: .date)
                    .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()
                .padding(.leading, 16)

            TextField("Add a note", text: $note)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .focused($focusedField, equals: .note)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
        }
        .background(Color.ui.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private func suggestTagIfNeeded() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              tag == nil,
              config.smartTaggingMode != .none else { return }

        let tagNames = expenseTags.map(\.name)
        let currentName = name
        let history = expenses.map { (name: $0.name, tagName: $0.tag?.name) }

        Task {
            if let result = await tagSuggestionService.suggestTag(
                for: currentName,
                existingExpenses: history,
                tagNames: tagNames,
                smartTaggingMode: config.smartTaggingMode
            ) {
                await MainActor.run {
                    if tag == nil {
                        tag = expenseTags.first { $0.name == result.tagName }
                        tagIsAISuggested = result.source == .ai
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var name: String = "My Expense"
    @Previewable @State var amount: Double? = 1254.12
    @Previewable @State var date: Date = Date.now
    @Previewable @State var category: ExpenseCategory = .needs
    @Previewable @State var tag: ExpenseTag? = nil
    @Previewable @State var note: String = ""

    ScrollView {
        ExpenseInfoForm(
            name: $name,
            amount: $amount,
            date: $date,
            category: $category,
            tag: $tag,
            note: $note
        )
        .padding(.vertical, 20)
    }
    .environment(AppConfiguration())
    .modelContainer(previewAppContainer)
}

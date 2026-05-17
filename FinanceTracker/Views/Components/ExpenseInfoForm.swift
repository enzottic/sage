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

    let tagSuggestionService = TagSuggestionService()
    @Environment(AppConfiguration.self) private var config: AppConfiguration
    @Query(sort: \ExpenseTag.name) private var expenseTags: [ExpenseTag]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @FocusState private var isNameFocused: Bool

    @State private var tagIsAISuggested: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            CustomDatePicker(selectedDate: $date)

            TextField("Expense Name", text: $name)
                .font(.title)
                .fontWeight(.bold)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .focused($isNameFocused)
                .onChange(of: isNameFocused) { _, focused in handleNameFocusChange(focused: focused) }
                .onChange(of: tag) { _, _ in
                    // Clear the AI badge whenever the tag changes (manual selection or removal)
                    tagIsAISuggested = false
                }

            TextField("Add a note", text: $note)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            CentsFirstCurrencyField(amount: $amount)

            Spacer()

            CategoryPicker(selectedCategory: $category)

            TagPicker(selectedTag: $tag, tagIsAISuggested: tagIsAISuggested)
        }
        .multilineTextAlignment(.center)
    }
    
    private func handleNameFocusChange(focused: Bool) {
        // When the user de-focuses the name field, attempt tag suggestion
        guard !focused,
              !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              tag == nil,
              config.smartTaggingMode != .none else { return }

        let tagNames = expenseTags.map(\.name)
        let currentName = name
        let expenseHistory = expenses.map { (name: $0.name, tagName: $0.tag?.name) }

        Task {
            if let result = await tagSuggestionService.suggestTag(
                for: currentName,
                existingExpenses: expenseHistory,
                tagNames: tagNames,
                smartTaggingMode: config.smartTaggingMode
            ) {
                await MainActor.run {
                    // Only apply if user hasn't manually picked a tag in the meantime
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
    @Previewable @State var appConfig: AppConfiguration = AppConfiguration()
    ExpenseInfoForm(
        name: $name,
        amount: $amount,
        date: $date,
        category: $category,
        tag: $tag,
        note: $note
    )
    .environment(appConfig)
    .modelContainer(previewAppContainer)
}


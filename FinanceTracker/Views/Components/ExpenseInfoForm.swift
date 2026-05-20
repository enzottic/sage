//
//  ExpenseInfoFormNew.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 5/19/26.
//

import SwiftUI
import SwiftData

struct ExpenseInfoForm: View {
    @Environment(AppConfiguration.self) private var config
    @Query(sort: \ExpenseTag.name) private var expenseTags: [ExpenseTag]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    @Binding var name: String
    @Binding var amount: Double?
    @Binding var date: Date
    @Binding var category: ExpenseCategory
    @Binding var tag: ExpenseTag?
    @Binding var note: String

    var isEditing: Bool = false

    private let tagSuggestionService = TagSuggestionService()
    @FocusState private var focusedField: Field?
    @State private var tagIsAISuggested = false

    private enum Field: Hashable { case name, note }

    var body: some View {
        VStack(spacing: 20) {
            amountHeader
            basicInfoCard
            sectionHeader(title: "Category") {
                inlineCategoryPicker
            }
            sectionHeader(title: "Tag") {
                TagPicker(selectedTag: $tag, tagIsAISuggested: tagIsAISuggested)
                    .padding(.horizontal, 8)
            }
        }
        .onChange(of: tag) { _, _ in tagIsAISuggested = false }
        .sensoryFeedback(.selection, trigger: category)
        .sensoryFeedback(.selection, trigger: tag)
    }

    // MARK: - Amount header

    private var amountHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                CentsFirstCurrencyField(amount: $amount)
                Text(isEditing ? "Tap to edit amount" : "Enter amount")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
            Spacer(minLength: 0)
            receiptPlaceholder
        }
        .padding(.horizontal)
    }

    private var receiptPlaceholder: some View {
        VStack(spacing: 6) {
            Image(systemName: "camera")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(.secondary)
            Text("Receipt")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 72, height: 80)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    Color.secondary.opacity(0.4),
                    style: StrokeStyle(lineWidth: 1, dash: [4])
                )
        )
    }

    // MARK: - Basic info card

    private var basicInfoCard: some View {
        VStack(spacing: 0) {
            TextField("Expense name", text: $name)
                .font(.body)
                .focused($focusedField, equals: .name)
                .onChange(of: focusedField) { old, _ in
                    if old == .name { suggestTagIfNeeded() }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)

            Divider().padding(.leading, 52)

            HStack(spacing: 12) {
                rowIcon("calendar")
                Text("Date")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                DatePicker("", selection: $date, displayedComponents: .date)
                    .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().padding(.leading, 52)

            HStack(spacing: 12) {
                rowIcon("text.alignleft")
                Text("Note")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                TextField("Add a note", text: $note)
                    .font(.subheadline)
                    .multilineTextAlignment(.trailing)
                    .focused($focusedField, equals: .note)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(Color.ui.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private func rowIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .regular))
            .foregroundStyle(.secondary)
            .frame(width: 24, alignment: .center)
    }

    // MARK: - Category picker (inline)

    private var inlineCategoryPicker: some View {
        HStack(spacing: 10) {
            ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                let isSelected = category == cat
                Button {
                    category = cat
                } label: {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(cat.color)
                            .frame(width: 10, height: 10)
                        Text(cat.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isSelected ? cat.color.opacity(0.18) : Color.ui.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                isSelected ? cat.color.opacity(0.6) : Color.clear,
                                lineWidth: 1.5
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.15), value: category)
    }


    // MARK: - Section wrapper

    @ViewBuilder
    private func sectionHeader<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .tracking(0.6)
                .padding(.horizontal)
            content()
        }
    }

    // MARK: - Tag suggestion

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

#Preview("Add") {
    @Previewable @State var name: String = ""
    @Previewable @State var amount: Double? = nil
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

#Preview("Edit") {
    @Previewable @State var name: String = "Safeway"
    @Previewable @State var amount: Double? = 57.57
    @Previewable @State var date: Date = Date.now
    @Previewable @State var category: ExpenseCategory = .needs
    @Previewable @State var tag: ExpenseTag? = nil
    @Previewable @State var note: String = "Weekly shop + party stuff"

    ScrollView {
        ExpenseInfoForm(
            name: $name,
            amount: $amount,
            date: $date,
            category: $category,
            tag: $tag,
            note: $note,
            isEditing: true
        )
        .padding(.vertical, 20)
    }
    .environment(AppConfiguration())
    .modelContainer(previewAppContainer)
}

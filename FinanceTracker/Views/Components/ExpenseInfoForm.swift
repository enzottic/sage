//
//  ExpenseInfoFormNew.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 5/19/26.
//

import SwiftUI
import SwiftData
import SageKit

struct ReceiptImportConfiguration {
    let isParsing: Bool
    let canUseCamera: Bool
    let onTakePhoto: () -> Void
    let onChoosePhoto: () -> Void
}

struct ExpenseInfoForm: View {
    @Environment(AppConfiguration.self) private var config
    @Environment(\.categoryColors) private var categoryColors
    @Query(sort: \ExpenseTag.name) private var expenseTags: [ExpenseTag]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    @Binding var name: String
    @Binding var amount: Double?
    @Binding var date: Date
    @Binding var category: ExpenseCategory
    @Binding var tags: [ExpenseTag]
    @Binding var note: String
    var isEditing: Bool
    var receiptImport: ReceiptImportConfiguration?
    var receiptImportUnavailableMessage: String?

    private let tagSuggestionService = TagSuggestionService()
    @FocusState private var focusedField: Field?
    /// IDs of currently-selected tags that were suggested by the AI (drives the rainbow border).
    @State private var aiSuggestedTagIDs: Set<UUID> = []

    private enum Field: Hashable { case name, amount, note }

    @State private var showDatePicker = false
    @State private var debouncedName: String = ""
    @State private var debounceTask: Task<Void, Never>? = nil

    private var nameSuggestions: [Expense] {
        let trimmed = debouncedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let lower = trimmed.lowercased()
        var seen = Set<String>()
        return expenses.filter { expense in
            let key = expense.name.lowercased()
            guard key.contains(lower), !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }.prefix(4).map { $0 }
    }

    init(
        name: Binding<String>,
        amount: Binding<Double?>,
        date: Binding<Date>,
        category: Binding<ExpenseCategory>,
        tags: Binding<[ExpenseTag]>,
        note: Binding<String>,
        isEditing: Bool = false,
        receiptImport: ReceiptImportConfiguration? = nil,
        receiptImportUnavailableMessage: String? = nil
    ) {
        self._name = name
        self._amount = amount
        self._date = date
        self._category = category
        self._tags = tags
        self._note = note
        self.isEditing = isEditing
        self.receiptImport = receiptImport
        self.receiptImportUnavailableMessage = receiptImportUnavailableMessage
    }

    var body: some View {
        VStack(spacing: 20) {
            nameHeader
            if !isEditing && focusedField == .name && !nameSuggestions.isEmpty {
                pastExpenseSuggestions
                    .transition(.opacity.combined(with: .offset(y: -8)))
            }
            detailsCard
            sectionHeader(title: "Category") {
                inlineCategoryPicker
            }
            sectionHeader(title: "Tags") {
                TagPicker(selectedTags: $tags, aiSuggestedTagIDs: aiSuggestedTagIDs)
                    .padding(.horizontal, 8)
            }
        }
        .animation(.spring(duration: 0.35, bounce: 0.2), value: focusedField == .name && !nameSuggestions.isEmpty)
        .onChange(of: name) { _, newValue in
            debounceTask?.cancel()
            debounceTask = Task {
                try? await Task.sleep(for: .seconds(0.5))
                guard !Task.isCancelled else { return }
                await MainActor.run { debouncedName = newValue }
            }
        }
        .onChange(of: tags) { _, newValue in
            // Keep the AI-suggested highlight only for tags that are still selected.
            let selectedIDs = Set(newValue.map(\.id))
            aiSuggestedTagIDs.formIntersection(selectedIDs)
        }
        .sensoryFeedback(.selection, trigger: category)
        .sensoryFeedback(.selection, trigger: tags.map(\.id))
    }

    // MARK: - Name header

    private var nameHeader: some View {
        HStack(alignment: .center, spacing: 16) {
            TextField("New Expense", text: $name)
                .accessibilityIdentifier("expense-name-field")
                .font(.system(size: 34, weight: .bold))
                .focused($focusedField, equals: .name)
                .onChange(of: focusedField) { old, _ in
                    if old == .name { suggestTagIfNeeded() }
                }

            Spacer(minLength: 0)

            if !isEditing, let receiptImport {
                receiptButton(receiptImport)
            } else if !isEditing, let receiptImportUnavailableMessage {
                Text(receiptImportUnavailableMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 144)
            }
        }
        .padding(.horizontal)
    }

    private func receiptButton(_ configuration: ReceiptImportConfiguration) -> some View {
        Menu {
            if configuration.canUseCamera {
                Button("Take Photo", systemImage: "camera", action: configuration.onTakePhoto)
            }
            Button(
                "Choose from Photos",
                systemImage: "photo.on.rectangle",
                action: configuration.onChoosePhoto
            )
        } label: {
            VStack(spacing: 6) {
                if configuration.isParsing {
                    ProgressView()
                        .frame(width: 22, height: 22)
                } else {
                    Image(systemName: "receipt")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(.secondary)
                }

                Text("Receipt")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 72, height: 80)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        Color.secondary.opacity(0.4),
                        style: StrokeStyle(lineWidth: 1, dash: [4])
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(configuration.isParsing)
        .accessibilityLabel("Receipt")
    }

    // MARK: - Past expense suggestions

    private var pastExpenseSuggestions: some View {
        VStack(spacing: 0) {
            ForEach(Array(nameSuggestions.enumerated()), id: \.element.id) { index, expense in
                if index > 0 {
                    Divider().padding(.leading, 56)
                }
                Button {
                    name = expense.name
                    amount = expense.amount
                    category = expense.category
                    tags = expense.tags ?? []
                    aiSuggestedTagIDs = []
                    focusedField = nil
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
        .background(.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Details card

    private var detailsCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                rowIcon("dollarsign")
                Text("Amount")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                TextField(
                    "$0.00",
                    value: $amount,
                    format: .currency(code: Locale.current.currency?.identifier ?? "USD")
                )
                .accessibilityIdentifier("expense-amount-field")
                .keyboardType(.decimalPad)
                .font(.body)
                .multilineTextAlignment(.trailing)
                .focused($focusedField, equals: .amount)
                .onChange(of: focusedField) { _, newField in
                    if newField == .amount, (amount ?? 0) == 0 {
                        amount = nil
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider().padding(.leading, 52)

            Button {
                withAnimation(.spring(duration: 0.3)) { showDatePicker.toggle() }
            } label: {
                HStack(spacing: 12) {
                    rowIcon("calendar")
                    Text("Date")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(showDatePicker ? .sage : .primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            if showDatePicker {
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                    .onChange(of: date) {
                        withAnimation(.spring(duration: 0.3)) { showDatePicker = false }
                    }
                    .transition(.opacity.combined(with: .offset(y: -8)))
            }

            Divider().padding(.leading, 52)

            HStack(spacing: 12) {
                rowIcon("text.alignleft")
                Text("Note")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                TextField("Add a note", text: $note)
                    .accessibilityIdentifier("expense-note-field")
                    .font(.subheadline)
                    .multilineTextAlignment(.trailing)
                    .focused($focusedField, equals: .note)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(.cardBackground)
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
                            .fill(cat.color(in: categoryColors))
                            .frame(width: 10, height: 10)
                        Text(cat.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isSelected ? cat.color(in: categoryColors).opacity(0.18) : .cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                isSelected ? cat.color(in: categoryColors).opacity(0.6) : Color.clear,
                                lineWidth: 1.5
                            )
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("expense-category-\(cat.rawValue.lowercased())")
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
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            content()
        }
    }

    // MARK: - Tag suggestion

    private func suggestTagIfNeeded() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              tags.isEmpty,
              config.smartTaggingMode != .none else { return }

        let tagNames = expenseTags.map(\.name)
        let currentName = name
        let history = expenses.map { (name: $0.name, tagName: $0.tags?.first?.name) }

        Task {
            if let result = await tagSuggestionService.suggestTag(
                for: currentName,
                existingExpenses: history,
                tagNames: tagNames,
                smartTaggingMode: config.smartTaggingMode
            ) {
                await MainActor.run {
                    if tags.isEmpty, let suggested = expenseTags.first(where: { $0.name == result.tagName }) {
                        tags = [suggested]
                        if result.source == .ai {
                            aiSuggestedTagIDs = [suggested.id]
                        }
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
    @Previewable @State var tags: [ExpenseTag] = []
    @Previewable @State var note: String = ""

    ScrollView {
        ExpenseInfoForm(
            name: $name,
            amount: $amount,
            date: $date,
            category: $category,
            tags: $tags,
            note: $note
        )
        .padding(.vertical, 20)
    }
    .environmentInjection()
}

#Preview("Edit") {
    @Previewable @State var name: String = "Safeway"
    @Previewable @State var amount: Double? = 57.57
    @Previewable @State var date: Date = Date.now
    @Previewable @State var category: ExpenseCategory = .needs
    @Previewable @State var tags: [ExpenseTag] = []
    @Previewable @State var note: String = "Weekly shop + party stuff"

    ScrollView {
        ExpenseInfoForm(
            name: $name,
            amount: $amount,
            date: $date,
            category: $category,
            tags: $tags,
            note: $note,
            isEditing: true
        )
        .padding(.vertical, 20)
    }
    .environmentInjection()
}

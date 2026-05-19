//
//  ExpenseInfoFormNew.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 5/19/26.
//

import SwiftUI
import SwiftData

struct ExpenseInfoFormNew: View {

    @Binding var name: String
    @Binding var amount: Double?
    @Binding var date: Date
    @Binding var category: ExpenseCategory
    @Binding var tag: ExpenseTag?
    @Binding var note: String

    var isEditing: Bool = false
    var autoFocusAmount: Bool = false

    private let tagSuggestionService = TagSuggestionService()
    @Environment(AppConfiguration.self) private var config
    @Query(sort: \ExpenseTag.name) private var expenseTags: [ExpenseTag]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @FocusState private var focusedField: Field?
    @State private var tagIsAISuggested = false

    @State private var centsValue: String = "0"
    @FocusState private var amountFocused: Bool
    @State private var newTagSheetIsPresented = false

    private enum Field: Hashable { case name, note }

    var body: some View {
        VStack(spacing: 20) {
            amountHeader
            basicInfoCard
            sectionHeader(title: "Category") {
                inlineCategoryPicker
            }
            sectionHeader(title: "Tags") {
                inlineTagPicker
            }
        }
        .onChange(of: tag) { _, _ in tagIsAISuggested = false }
        .onAppear {
            if let amount = amount {
                centsValue = String(Int(amount * 100))
            }
            if autoFocusAmount {
                Task {
                    try? await Task.sleep(for: .seconds(0.6))
                    amountFocused = true
                }
            }
        }
    }

    // MARK: - Amount header

    private var amountHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                amountDisplay
                Text(isEditing ? "Tap to edit amount" : "Enter amount")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
            Spacer(minLength: 0)
            receiptPlaceholder
        }
        .padding(.horizontal)
    }

    private var amountDisplay: some View {
        ZStack(alignment: .leading) {
            TextField("", text: $centsValue)
                .keyboardType(.numberPad)
                .opacity(0)
                .frame(width: 0, height: 0)
                .focused($amountFocused)
                .onChange(of: centsValue) { _, newValue in
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered.isEmpty {
                        centsValue = "0"
                        amount = nil
                    } else if filtered.count > 10 {
                        centsValue = String(filtered.prefix(10))
                    } else {
                        centsValue = filtered
                    }
                    if let cents = Int(centsValue), cents > 0 {
                        amount = Double(cents) / 100.0
                    } else {
                        amount = nil
                    }
                }
                .accessibilityIdentifier("Expense Amount Field")

            amountText
                .contentShape(Rectangle())
                .onTapGesture { amountFocused = true }
        }
    }

    private var currentCents: Int {
        Int(centsValue) ?? 0
    }

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        let dollars = Double(currentCents) / 100.0
        return formatter.string(from: NSNumber(value: dollars)) ?? "$0.00"
    }

    @ViewBuilder
    private var amountText: some View {
        if currentCents == 0 {
            Text(splitForEmpty(formattedAmount))
        } else {
            Text(formattedAmount)
                .font(.system(size: 52, weight: .bold))
                .foregroundStyle(.primary)
        }
    }

    private func splitForEmpty(_ formatted: String) -> AttributedString {
        let separator = Locale.current.decimalSeparator ?? "."
        if let range = formatted.range(of: separator) {
            var main = AttributedString(String(formatted[..<range.lowerBound]))
            main.font = .system(size: 52, weight: .bold)
            main.foregroundColor = .primary

            var cents = AttributedString(String(formatted[range.lowerBound...]))
            cents.font = .system(size: 36, weight: .bold)
            cents.foregroundColor = .secondary

            return main + cents
        }
        var full = AttributedString(formatted)
        full.font = .system(size: 52, weight: .bold)
        full.foregroundColor = .primary
        return full
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
            TextField("Where did you spend?", text: $name)
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

    // MARK: - Tag picker (inline, always visible)

    private var inlineTagPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(expenseTags, id: \.self) { option in
                    Button {
                        if tag == option {
                            tag = nil
                        } else {
                            tag = option
                        }
                    } label: {
                        HStack(spacing: 2) {
                            TagCapsule(
                                tag: option,
                                .medium,
                                aiSuggested: tagIsAISuggested && tag == option
                            )
                            if tag == option {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.footnote)
                                    .foregroundStyle(option.color.opacity(0.8))
                                    .accessibilityLabel(Text("Remove tag"))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    newTagSheetIsPresented = true
                } label: {
                    Image(systemName: "plus")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.ui.cardBackground))
                        .accessibilityLabel(Text("Add new tag"))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.vertical, 2)
        }
        .sheet(isPresented: $newTagSheetIsPresented) {
            AddExpenseTagSheet { newTag in
                tag = newTag
            }
        }
        .animation(.easeInOut(duration: 0.15), value: tag)
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
        ExpenseInfoFormNew(
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
        ExpenseInfoFormNew(
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

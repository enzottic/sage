import Foundation
import SwiftData
import UIKit

@MainActor
public struct ExpenseImportService {
    private let modelContainer: ModelContainer

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    /// Appends one batch without saving or rolling back the caller's pending edits.
    public func importExpenses(
        _ expenses: [ExportableExpense],
        ledgerCurrencyCode: String,
        allowLegacy: Bool = false,
        creatingTagNames: [String] = [],
        progress: (Int) -> Void = { _ in },
        save: (ModelContext) throws -> Void = { try $0.save() }
    ) async throws -> Int {
        try ExpenseCSVCodec.validateCurrency(
            expenses, ledgerCurrencyCode: ledgerCurrencyCode, allowLegacy: allowLegacy
        )
        let categories = try expenses.enumerated().map { index, expense in
            guard let category = ExpenseCategory(rawValue: expense.category) else {
                throw ExpenseCSVError.invalidCategory(row: index + 2, value: expense.category)
            }
            return category
        }

        let context = ModelContext(modelContainer)
        context.autosaveEnabled = false
        do {
            let existingTags = try context.fetch(FetchDescriptor<ExpenseTag>())
            var tagsByName = Dictionary(existingTags.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
            let referencedNames = Set(expenses.flatMap(\.tagNames))
            for name in Set(creatingTagNames).intersection(referencedNames).sorted() where tagsByName[name] == nil {
                let tag = ExpenseTag(name: name, uiColor: .systemGray, emoji: "\u{1F3F7}\u{FE0F}")
                context.insert(tag)
                tagsByName[name] = tag
            }

            for (index, expense) in expenses.enumerated() {
                context.insert(Expense(
                    name: expense.name,
                    amount: expense.amount,
                    category: categories[index],
                    date: expense.date,
                    tags: expense.tagNames.compactMap { tagsByName[$0] },
                    note: expense.note
                ))
                progress(index + 1)
                if index.isMultiple(of: 25) {
                    await Task.yield()
                }
                try Task.checkCancellation()
            }

            try Task.checkCancellation()
            try save(context)
            return expenses.count
        } catch {
            context.rollback()
            throw error
        }
    }
}

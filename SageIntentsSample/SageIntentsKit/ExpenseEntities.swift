import AppIntents
import Foundation
import SwiftData

public struct ExpenseEntity: IndexedEntity {
    public static let defaultQuery = ExpenseEntityQuery()
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Expense"

    public let id: UUID
    let name: String
    let amount: Double
    let category: ExpenseCategory
    let date: Date
    let tags: [ExpenseTagEntity]

    public var displayRepresentation: DisplayRepresentation {
        let tagText = tags.map { "\($0.emoji) \($0.name)" }.joined(separator: ", ")
        let subtitle = tagText.isEmpty
            ? "\(amount.currencyString) · \(category.rawValue)"
            : "\(amount.currencyString) · \(category.rawValue) · \(tagText)"
        return DisplayRepresentation(title: "\(name)", subtitle: "\(subtitle)")
    }

    init(_ expense: Expense) {
        id = expense.id
        name = expense.name
        amount = expense.amount
        category = expense.category
        date = expense.date
        tags = (expense.tags ?? []).map(ExpenseTagEntity.init)
    }

    @MainActor
    public struct ExpenseEntityQuery: EnumerableEntityQuery, EntityStringQuery {
        @Dependency var expenseStore: ExpenseStore

        public nonisolated init() {}

        public func allEntities() async throws -> [ExpenseEntity] {
            try expenseStore.fetchExpenses().map(ExpenseEntity.init)
        }

        public func entities(matching string: String) async throws -> [ExpenseEntity] {
            try expenseStore.fetchExpenses()
                .filter { $0.name.localizedCaseInsensitiveContains(string) }
                .map(ExpenseEntity.init)
        }

        public func entities(for identifiers: [UUID]) async throws -> [ExpenseEntity] {
            try expenseStore.fetchExpenses(with: identifiers).map(ExpenseEntity.init)
        }

        public func suggestedEntities() async throws -> [ExpenseEntity] {
            try expenseStore.fetchRecentExpenses().map(ExpenseEntity.init)
        }
    }
}

public struct ExpenseTagEntity: AppEntity {
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Tag"
    public static var defaultQuery = ExpenseTagEntityQuery()

    public let id: UUID
    let name: String
    let emoji: String
    let symbolName: String?

    public var displayRepresentation: DisplayRepresentation {
        if let symbolName {
            return DisplayRepresentation(title: "\(name)", image: .init(systemName: symbolName))
        }
        return DisplayRepresentation(title: "\(emoji) \(name)")
    }

    init(_ tag: ExpenseTag) {
        id = tag.id
        name = tag.name
        emoji = tag.emoji
        symbolName = tag.symbolName
    }
}

@MainActor
public struct ExpenseTagEntityQuery: EntityQuery {
    @Dependency var expenseStore: ExpenseStore

    public nonisolated init() {}

    public func entities(for identifiers: [UUID]) async throws -> [ExpenseTagEntity] {
        let tags = try expenseStore.context.fetch(FetchDescriptor<ExpenseTag>())
        return tags.filter { identifiers.contains($0.id) }.map(ExpenseTagEntity.init)
    }

    public func suggestedEntities() async throws -> [ExpenseTagEntity] {
        try expenseStore.context.fetch(
            FetchDescriptor<ExpenseTag>(sortBy: [SortDescriptor(\.name)])
        ).map(ExpenseTagEntity.init)
    }
}


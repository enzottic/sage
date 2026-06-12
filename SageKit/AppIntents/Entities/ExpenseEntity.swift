//
//  ExpenseEntity.swift
//  FinanceTracker
//

import Foundation
import AppIntents
import SwiftData

public struct ExpenseEntity: IndexedEntity {
    // MARK: Static

    public static let defaultQuery = ExpenseEntityQuery()

    // MARK: Properties

    public let id: UUID
    let name: String
    let amount: Double
    let category: ExpenseCategory
    let date: Date
    let tag: ExpenseTagEntity?

    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Expense"

    public var displayRepresentation: DisplayRepresentation {
        let subtitle: String
        if let tag {
            subtitle = "\(amount.currencyString) · \(category) · \(tag.emoji) \(tag.name)"
        } else {
            subtitle = "\(amount.currencyString) · \(category)"
        }

        return DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(subtitle)"
        )
    }

    public init(id: UUID, name: String, amount: Double, category: ExpenseCategory, date: Date, tag: ExpenseTag?) {
        self.id = id
        self.name = name
        self.amount = amount
        self.category = category
        self.date = date
        self.tag = tag?.entity
    }
    
    @MainActor
    public struct ExpenseEntityQuery: EnumerableEntityQuery, EntityStringQuery {

        @Dependency
        var expenseStore: ExpenseStore

        public func allEntities() async throws -> [ExpenseEntity] {
            try expenseStore.fetchExpenses().map(\.entity)
        }

        public func entities(matching string: String) async throws -> [ExpenseEntity] {
            try expenseStore.fetchExpenses()
                .filter { $0.name.localizedCaseInsensitiveContains(string) }
                .map(\.entity)
        }
        
        public func entities(for identifiers: [ExpenseEntity.ID]) async throws -> [ExpenseEntity] {
            try expenseStore.fetchExpenses(with: identifiers).map(\.entity)
        }

        public func suggestedEntities() async throws -> [ExpenseEntity] {
            try expenseStore.fetchRecentExpenses(limit: 5).map(\.entity)
        }
        
        public nonisolated init () { }
    }
}

extension Expense {
    var entity: ExpenseEntity {
        ExpenseEntity(id: self.id, name: self.name, amount: self.amount, category: self.category, date: self.date, tag: self.tag)
    }
}


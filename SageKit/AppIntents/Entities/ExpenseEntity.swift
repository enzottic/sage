//
//  ExpenseEntity.swift
//  FinanceTracker
//

import Foundation
import AppIntents
import SwiftData

struct ExpenseEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Expense"
    static var defaultQuery = ExpenseEntityQuery()

    public let id: UUID
    let name: String
    let amount: Double
    let category: ExpenseCategory
    let date: Date
    let tagName: String?
    let tagEmoji: String?

    public var displayRepresentation: DisplayRepresentation {
        if let tagEmoji, let tagName {
            return DisplayRepresentation(
                title: "\(name)",
                subtitle: "\(tagEmoji) \(tagName) · \(amount.currencyString)"
            )
        }
        return DisplayRepresentation(title: "\(name)", subtitle: "\(amount.currencyString)")
    }
}

extension ExpenseEntity {
    init(from expense: Expense) {
        self.init(
            id: expense.id,
            name: expense.name,
            amount: expense.amount,
            category: expense.category,
            date: expense.date,
            tagName: expense.tag?.name,
            tagEmoji: expense.tag?.emoji
        )
    }
}

struct ExpenseEntityQuery: EntityQuery, EntityStringQuery {
    func entities(for identifiers: [UUID]) async throws -> [ExpenseEntity] {
        let store = try ExpenseStore()
        return store.fetchAllExpenses()
            .filter { identifiers.contains($0.id) }
            .map { ExpenseEntity(from: $0) }
    }

    func suggestedEntities() async throws -> [ExpenseEntity] {
        let store = try ExpenseStore()
        return Array(store.fetchExpenses(for: .now).prefix(20))
            .map { ExpenseEntity(from: $0) }
    }

    func entities(matching string: String) async throws -> [ExpenseEntity] {
        let store = try ExpenseStore()
        let lowercased = string.lowercased()
        return store.fetchAllExpenses()
            .filter {
                $0.name.lowercased().contains(lowercased) ||
                ($0.tag?.name.lowercased().contains(lowercased) ?? false)
            }
            .map { ExpenseEntity(from: $0) }
    }
}

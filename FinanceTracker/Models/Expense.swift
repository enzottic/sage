//
//  Item.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 9/21/25.
//

import Foundation
import SwiftData
import SwiftUI
import AppIntents

@Model
final class Expense {
    var id: UUID
    var name: String
    var amount: Double
    var category: ExpenseCategory
    var date: Date

    init(
        name: String,
        amount: Double,
        category: ExpenseCategory = .wants,
        date: Date = Date.now,
    ) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.category = category
        self.date = date
    }
    
}

extension Expense {
    static var example: Expense {
        .init(name: "My Expense", amount: 123.45, category: .wants, date: Date.now)
    }
}

struct ExpenseEntity: AppEntity {
    let id: UUID
    let name: String
    let date: Date
    let category: ExpenseCategory
    
    static var defaultQuery = ExpenseQuery()
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Entity"
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: LocalizedStringResource("\(name)")
        )
    }
}

struct ExpenseQuery: EntityQuery {
    typealias Entity = ExpenseEntity
    
    func latestExpenses() async throws -> [ExpenseEntity] {
        let expenses = try await fetchExpenses()
        print("Got latest expenses: \(expenses)")
        
        return Array(expenses.prefix(3))
    }
    
    func entities(for identifiers: [Entity.ID]) async throws -> [Entity] {
        let expenses = try await fetchExpenses()
        return expenses.filter { identifiers.contains($0.id) }
    }
    
    
    private func fetchExpenses() async throws -> [ExpenseEntity] {
        let container = try ModelContainer(for: Expense.self)
        let context = ModelContext(container)
        
        let fetchDescriptor = FetchDescriptor<Expense>(
            sortBy: [SortDescriptor(\Expense.date, order: .reverse)]
        )
        
        let results = try context.fetch(FetchDescriptor<Expense>())
        
        return results.compactMap { expense in
            ExpenseEntity(id: expense.id, name: expense.name, date: expense.date, category: expense.category)
        }
    }
    
    
}


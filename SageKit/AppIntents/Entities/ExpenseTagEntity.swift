//
//  ExpenseTagEntity.swift
//  FinanceTracker
//

import Foundation
import AppIntents
import SwiftData

struct ExpenseTagEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Tag"
    static var defaultQuery = ExpenseTagEntityQuery()

    let id: UUID
    let name: String
    let emoji: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(emoji) \(name)")
    }
}

struct ExpenseTagEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [ExpenseTagEntity] {
        let container = try SageModelContainer.make()
        let context = ModelContext(container)
        let all = try context.fetch(FetchDescriptor<ExpenseTag>())
        return all
            .filter { identifiers.contains($0.id) }
            .map { ExpenseTagEntity(id: $0.id, name: $0.name, emoji: $0.emoji) }
    }

    func suggestedEntities() async throws -> [ExpenseTagEntity] {
        let container = try SageModelContainer.make()
        let context = ModelContext(container)
        let all = try context.fetch(FetchDescriptor<ExpenseTag>(sortBy: [SortDescriptor(\.name)]))
        return all.map { ExpenseTagEntity(id: $0.id, name: $0.name, emoji: $0.emoji) }
    }
}

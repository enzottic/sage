//
//  ExpenseTagEntity.swift
//  FinanceTracker
//

import Foundation
import AppIntents
import SwiftData

public struct ExpenseTagEntity: AppEntity {
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Tag"
    public static var defaultQuery = ExpenseTagEntityQuery()

    public let id: UUID
    let name: String
    let emoji: String
    let symbolName: String?

    public var displayRepresentation: DisplayRepresentation {
        // Titles are plain strings, so an icon-marked tag carries its symbol in the image slot
        // and drops the emoji from the title rather than showing both marks.
        if let symbolName {
            return DisplayRepresentation(title: "\(name)", image: .init(systemName: symbolName))
        }
        return DisplayRepresentation(title: "\(emoji) \(name)")
    }
}

public struct ExpenseTagEntityQuery: EntityQuery {
    public func entities(for identifiers: [UUID]) async throws -> [ExpenseTagEntity] {
        let container = try SageModelContainer.make()
        let context = ModelContext(container)
        let all = try context.fetch(FetchDescriptor<ExpenseTag>())
        return all
            .filter { identifiers.contains($0.id) }
            .map { ExpenseTagEntity(id: $0.id, name: $0.name, emoji: $0.emoji, symbolName: $0.symbolName) }
    }

    public func suggestedEntities() async throws -> [ExpenseTagEntity] {
        let container = try SageModelContainer.make()
        let context = ModelContext(container)
        let all = try context.fetch(FetchDescriptor<ExpenseTag>(sortBy: [SortDescriptor(\.name)]))
        return all.map { ExpenseTagEntity(id: $0.id, name: $0.name, emoji: $0.emoji, symbolName: $0.symbolName) }
    }
    
    public init() { }
}

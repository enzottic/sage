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

enum SageSchemaV0: VersionedSchema {
    static var versionIdentifier = Schema.Version(0, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Expense.self]
    }
    
    @Model
    final class Expense {
        var id: UUID
        var name: String
        var amount: Double
        var category: ExpenseCategory
        var date: Date
        var tag: ExpenseTag = ExpenseTag.other

        init(
            name: String,
            amount: Double,
            category: ExpenseCategory = .wants,
            date: Date = Date.now,
            tag: ExpenseTag = .other
        ) {
            self.id = UUID()
            self.name = name
            self.amount = amount
            self.category = category
            self.date = date
            self.tag = tag
        }
    }
}

typealias Expense = SageSchemaV0.Expense

enum SageSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Expense.self, ExpenseTagModel.self]
    }

    @Model
    final class Expense {
        var id: UUID
        var name: String
        var amount: Double
        var category: ExpenseCategory
        var date: Date
        var tag: ExpenseTagModel

        init(
            name: String,
            amount: Double,
            category: ExpenseCategory = .wants,
            date: Date = Date.now,
            tag: ExpenseTagModel
        ) {
            self.id = UUID()
            self.name = name
            self.amount = amount
            self.category = category
            self.date = date
            self.tag = tag
        }
    }
    
    @Model
    class ExpenseTagModel: Identifiable {
        var id: UUID
        var name: String
        var emoji: String
        
        @Attribute(.transformable(by: UIColorValueTransformer.self))
        var color: UIColor
        
        init(name: String, color: UIColor, emoji: String) {
            self.id = UUID()
            self.name = name
            self.color = color
            self.emoji = emoji
        }
    }
}

enum ExpensesMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SageSchemaV0.self, SageSchemaV1.self]
    }
    
    static var stages: [MigrationStage] {
        [migrateV0toV1]
    }
    
    static let migrateV0toV1 = MigrationStage.custom(
        fromVersion: SageSchemaV0.self,
        toVersion: SageSchemaV1.self,
        willMigrate: { context in
            
        }, didMigrate: nil
    )
}

extension Expense {
    static var example: Expense {
        .init(name: "My Expense", amount: 123.45, category: .wants, date: Date.now, tag: .dining)
    }
}

extension [Expense] {
    
    var total: Double {
        self.reduce(0) { $0 + $1.amount }
    }
    
    var wantsUsed: Double {
        self.filter { $0.category == .wants }
            .reduce(0) { $0 + $1.amount }
    }
    
    
    var needsUsed: Double {
        self.filter { $0.category == .needs}
            .reduce(0) { $0 + $1.amount }
    }
    
    var savingsUsed: Double {
        self.filter { $0.category == .savings}
            .reduce(0) { $0 + $1.amount }
    }
}

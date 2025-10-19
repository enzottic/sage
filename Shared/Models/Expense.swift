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
        var tag: SageSchemaV0.ExpenseTag = ExpenseTag.other
        var note: String = ""

        init(
            name: String,
            amount: Double,
            category: ExpenseCategory = .wants,
            date: Date = Date.now,
            tag: ExpenseTag = .other,
            note: String = ""
        ) {
            self.id = UUID()
            self.name = name
            self.amount = amount
            self.category = category
            self.date = date
            self.tag = tag
            self.note = ""
        }
    }
    
    enum ExpenseTag: String, Codable, CaseIterable {
        case shopping = "Shopping"
        case dining = "Dining"
        case entertainment = "Entertainment"
        case billsAndUtils = "Bills & Utilities"
        case groceries = "Groceries"
        case subscription = "Subscriptions"
        case travel = "Travel"
        case other = "Other"
        
        var color: Color {
            switch (self) {
            case .shopping: .yellow
            case .dining: .orange
            case .entertainment: .pink
            case .billsAndUtils: .blue
            case .groceries: .green
            case .subscription: .teal
            case .travel: .purple
            case .other: .gray
            }
        }
        
        var emoji: String {
            switch (self) {
            case .shopping: "🛍️"
            case .dining: "🍔"
            case .entertainment: "🍿"
            case .billsAndUtils: "🏠"
            case .groceries: "🥗"
            case .subscription: "💻"
            case .travel: "✈️"
            case .other: "💰"
            }
        }
    }
}

class SageSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(0, 1, 0)
    
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
        var tag: ExpenseTagModel?
        var note: String = ""

        init(
            name: String,
            amount: Double,
            category: ExpenseCategory = .wants,
            date: Date = Date.now,
            tag: ExpenseTagModel? = nil,
            note: String = ""
        ) {
            self.id = UUID()
            self.name = name
            self.amount = amount
            self.category = category
            self.date = date
            self.tag = tag
            self.note = ""
        }
    }
    
    @Model
    final class ExpenseTagModel: Identifiable {
        var id: UUID
        var name: String
        var emoji: String
        
        @Attribute(.transformable(by: UIColorValueTransformer.self))
        var uiColor: UIColor
        
        var color: Color {
            Color(uiColor: uiColor)
        }
        
        init(name: String, uiColor: UIColor, emoji: String) {
            self.id = UUID()
            self.name = name
            self.uiColor = uiColor
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
            let fetchDesc = FetchDescriptor<SageSchemaV0.Expense>()
            let oldExpenses = try? context.fetch(fetchDesc)
            
            let tagMap: Dictionary<SageSchemaV0.ExpenseTag, ExpenseTag> = [
                SageSchemaV0.ExpenseTag.other : ExpenseTag.other,
                SageSchemaV0.ExpenseTag.dining: ExpenseTag.dining,
                SageSchemaV0.ExpenseTag.groceries: ExpenseTag.groceries,
                SageSchemaV0.ExpenseTag.billsAndUtils: ExpenseTag.billsAndUtils,
                SageSchemaV0.ExpenseTag.subscription: ExpenseTag.subscriptions,
                SageSchemaV0.ExpenseTag.entertainment: ExpenseTag.entertainment,
                SageSchemaV0.ExpenseTag.shopping: ExpenseTag.shopping,
                SageSchemaV0.ExpenseTag.travel: ExpenseTag.travel
            ]
            
            tagMap.values.forEach { newTag in
                context.insert(newTag)
            }
            
            oldExpenses?.forEach { oldExpense in
                let newExpense = SageSchemaV1.Expense(
                    name: oldExpense.name,
                    amount: oldExpense.amount,
                    category: oldExpense.category,
                    date: oldExpense.date,
                    tag: tagMap[oldExpense.tag],
                    note: oldExpense.note,
                )
                context.delete(oldExpense)
                context.insert(newExpense)
            }
            
            try context.save()
            
        }, didMigrate: nil
    )
}

typealias Expense = SageSchemaV1.Expense
typealias ExpenseTag = SageSchemaV1.ExpenseTagModel

extension Expense {
    static var example: Expense {
        .init(name: "My Expense", amount: 123.45, category: .wants, date: Date.now, tag: .dining)
    }
}

extension ExpenseTag {

    static var shopping: ExpenseTag {
        .init(name: "Shopping", uiColor: .yellow, emoji: "🛍️")
    }
    
    static var dining: ExpenseTag {
        .init(name: "Dining", uiColor: .orange, emoji: "🍽️")
    }
    
    static var entertainment: ExpenseTag {
        .init(name: "Entertainment", uiColor: .systemPink, emoji: "🍿")
    }
    
    static var billsAndUtils: ExpenseTag {
        .init(name: "Bills & Utilities", uiColor: .blue, emoji: "🏠")
    }
    
    static var groceries: ExpenseTag {
        .init(name: "Groceries", uiColor: .green, emoji: "🥗")
    }
    
    static var subscriptions: ExpenseTag {
        .init(name: "Subscriptions", uiColor: .systemTeal, emoji: "💻")
    }
    
    static var travel: ExpenseTag {
        .init(name: "Travel", uiColor: .purple , emoji: "✈️")
    }
    
    static var other: ExpenseTag {
        .init(name: "Other", uiColor: .gray, emoji: "🔖")
    }
    
    static var defaultTags: [ExpenseTag] {
        [.shopping, .dining, .entertainment, .billsAndUtils, .groceries, .subscriptions, .travel, .other]
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

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
        
        @Relationship(deleteRule: .nullify)
        var tag: ExpenseTagModel? = ExpenseTagModel.other
        
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

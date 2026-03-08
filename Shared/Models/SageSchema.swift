//
//  SageSchema.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 3/7/26.
//
import SwiftData
import Foundation
import SwiftUI

enum SageSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] = [Expense.self, ExpenseTag.self]
    
    @Model
    final class Expense {
        var id: UUID
        var name: String
        var amount: Double
        var category: ExpenseCategory
        var date: Date
        
        @Relationship(deleteRule: .nullify)
        var tag: ExpenseTag? = ExpenseTag.other
        
        var note: String = ""
        
        init(
            name: String,
            amount: Double,
            category: ExpenseCategory = .wants,
            date: Date = Date.now,
            tag: ExpenseTag? = nil,
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
    final class ExpenseTag: Identifiable {
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

typealias Expense = SageSchemaV1.Expense
typealias ExpenseTag = SageSchemaV1.ExpenseTag

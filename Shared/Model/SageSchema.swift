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
    static var models: [any PersistentModel.Type] = [Expense.self, ExpenseTag.self, RecurringExpenseRule.self]
    
    @Model
    final class Expense {
        var id: UUID
        var name: String
        var amount: Double
        var category: ExpenseCategory
        var date: Date
        var note: String = ""
        
        @Relationship(deleteRule: .nullify, inverse: \ExpenseTag.expenses)
        var tag: ExpenseTag? = ExpenseTag.other
        
        var recurringExpenseId: UUID? = nil
        
        init(
            name: String,
            amount: Double,
            category: ExpenseCategory = .wants,
            date: Date = Date.now,
            tag: ExpenseTag? = nil,
            note: String = "",
            recurringExpenseId: UUID? = nil,
        ) {
            self.id = UUID()
            self.name = name
            self.amount = amount
            self.category = category
            self.date = date
            self.tag = tag
            self.note = note
            self.recurringExpenseId = recurringExpenseId
        }
    }
    
    @Model
    final class ExpenseTag: Identifiable {
        var id: UUID
        var name: String
        var emoji: String
        
        @Attribute(.transformable(by: UIColorValueTransformer.self))
        var uiColor: UIColor
        
        @Relationship var expenses: [Expense]?
        @Relationship var recurringRules: [RecurringExpenseRule]?
        
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
   
    enum RecurrenceFrequency: String, Codable, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case biweekly = "Bi-Weekly"
        case monthly = "Monthly"
    }

    @Model
    final class RecurringExpenseRule: Identifiable {
        var id: UUID
        var name: String
        var amount: Double
        var note: String
        var category: ExpenseCategory
        @Relationship(deleteRule: .nullify, inverse: \ExpenseTag.recurringRules)
        var tag: ExpenseTag?
        
        var frequency: RecurrenceFrequency
        var startDate: Date
        var endDate: Date?
        var lastGeneratedDate: Date?
        
        init(name: String, amount: Double, note: String, category: ExpenseCategory, tag: ExpenseTag, frequency: RecurrenceFrequency, startDate: Date, endDate: Date? = nil, lastGeneratedDate: Date? = nil) {
            self.id = UUID()
            self.name = name
            self.amount = amount
            self.note = note
            self.category = category
            self.tag = tag
            self.frequency = frequency
            self.startDate = startDate
            self.endDate = endDate
            self.lastGeneratedDate = lastGeneratedDate
        }
    }
    
}

extension Expense {
    static var example: Expense = Expense(name: "Car Insurance", amount: 123.43, category: .needs, date: .now, tag: .billsAndUtils, note: "Progressive Insurance", recurringExpenseId: nil)
    
    static var recurringExpense: RecurringExpenseRule = RecurringExpenseRule(name: "Rent", amount: 1300.00, note: "Rent", category: .needs, tag: .billsAndUtils, frequency: .monthly, startDate: .now)
    static var recurringExample: Expense = Expense(name: "Rent", amount: 1300.00,  category: .needs, date: .now, tag: .billsAndUtils, note: "Rent", recurringExpenseId: recurringExpense.id)
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
typealias RecurringExpenseRule = SageSchemaV1.RecurringExpenseRule
typealias RecurrenceFrequency = SageSchemaV1.RecurrenceFrequency

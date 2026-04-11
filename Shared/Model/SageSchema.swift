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
    static var models: [any PersistentModel.Type] = [SageSchemaV1.Expense.self, SageSchemaV1.ExpenseTag.self, SageSchemaV1.RecurringExpenseRule.self]
    
    @Model
    final class Expense {
        var id: UUID = UUID()
        var name: String = "New Expense"
        var amount: Double = 0.0
        var category: ExpenseCategory = ExpenseCategory.needs
        var date: Date = Date.now
        var note: String = ""
        
        @Relationship(deleteRule: .nullify, inverse: \ExpenseTag.expenses)
        var tag: ExpenseTag?
        
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
        var id: UUID = UUID()
        var name: String = "Tag"
        var emoji: String = "💰"
        
        @Attribute(.transformable(by: UIColorValueTransformer.self))
        var uiColor: UIColor = UIColor.blue
        
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
        var id: UUID = UUID()
        var name: String = "My Expense"
        var amount: Double = 0.0
        var note: String = ""
        var category: ExpenseCategory = ExpenseCategory.wants
        @Relationship(deleteRule: .nullify, inverse: \ExpenseTag.recurringRules)
        var tag: ExpenseTag?
        
        var frequency: RecurrenceFrequency = RecurrenceFrequency.monthly
        var startDate: Date = Date.now
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

enum SageSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] = [SageSchemaV2.Expense.self, SageSchemaV2.ExpenseTag.self, SageSchemaV2.RecurringExpenseRule.self, SageSchemaV2.ExpenseAccount.self]
    
    @Model
    final class Expense {
        var id: UUID = UUID()
        var name: String = "New Expense"
        var amount: Double = 0.0
        var category: ExpenseCategory = ExpenseCategory.needs
        var date: Date = Date.now
        var note: String = ""
        
        @Relationship(deleteRule: .nullify, inverse: \ExpenseTag.expenses)
        var tag: ExpenseTag?
        
        var recurringExpenseId: UUID? = nil
        
        @Relationship(deleteRule: .nullify, inverse: \ExpenseAccount.expenses)
        var account: ExpenseAccount? = nil
        
        init(
            name: String,
            amount: Double,
            category: ExpenseCategory = .wants,
            date: Date = Date.now,
            tag: ExpenseTag? = nil,
            note: String = "",
            recurringExpenseId: UUID? = nil,
            account: ExpenseAccount? = nil
        ) {
            self.id = UUID()
            self.name = name
            self.amount = amount
            self.category = category
            self.date = date
            self.tag = tag
            self.note = note
            self.recurringExpenseId = recurringExpenseId
            self.account = account
        }
    }
    
    @Model
    final class ExpenseTag: Identifiable {
        var id: UUID = UUID()
        var name: String = "Tag"
        var emoji: String = "💰"
        
        @Attribute(.transformable(by: UIColorValueTransformer.self))
        var uiColor: UIColor = UIColor.blue
        
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
        var id: UUID = UUID()
        
        // Fields gathered from the original expense to be copied to the new expense
        var name: String = "New Expense"
        var amount: Double = 0.0
        var note: String = ""
        var category: ExpenseCategory = ExpenseCategory.needs
        @Relationship(deleteRule: .nullify, inverse: \ExpenseTag.recurringRules)
        var tag: ExpenseTag?
        
        @Relationship(deleteRule: .nullify, inverse: \ExpenseAccount.recurringRules)
        var account: ExpenseAccount?
        
        // Recurrance configuration
        var frequency: RecurrenceFrequency = RecurrenceFrequency.monthly
        var startDate: Date = Date.now
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
    
    @Model
    final class ExpenseAccount: Identifiable {
        var id: UUID = UUID()
        var name: String = "Account"
        var type: AccountType = AccountType.bankAccount
        
        @Relationship var expenses: [Expense]?
        @Relationship var recurringRules: [RecurringExpenseRule]?

        enum AccountType: String, Codable {
            case bankAccount = "Bank Account"
            case creditCard = "Credit Card"
            case other = "Other"
        }
        
        init(id: UUID, name: String, type: AccountType) {
            self.id = id
            self.name = name
            self.type = type
        }
    }
}


class SageSchemaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [SageSchemaV1.self, SageSchemaV2.self]
    
    static var stages: [MigrationStage] = [
        MigrationStage.lightweight(fromVersion: SageSchemaV1.self, toVersion: SageSchemaV2.self)
    ]
}


extension Expense {
    static var example: Expense = Expense(name: "Car Insurance", amount: 123.43, category: .needs, date: .now, tag: .billsAndUtils, note: "Progressive Insurance", recurringExpenseId: nil, account: nil)
    
    static var recurringExpense: RecurringExpenseRule = RecurringExpenseRule(name: "Rent", amount: 1300.00, note: "Rent", category: .needs, tag: .billsAndUtils, frequency: .monthly, startDate: .now)
    static var recurringExample: Expense = Expense(name: "Rent", amount: 1300.00,  category: .needs, date: .now, tag: .billsAndUtils, note: "Rent", recurringExpenseId: recurringExpense.id, account: nil)
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

typealias Expense = SageSchemaV2.Expense
typealias ExpenseTag = SageSchemaV2.ExpenseTag
typealias RecurringExpenseRule = SageSchemaV2.RecurringExpenseRule
typealias RecurrenceFrequency = SageSchemaV2.RecurrenceFrequency
typealias ExpenseAccount = SageSchemaV2.ExpenseAccount

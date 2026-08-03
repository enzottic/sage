//
//  ExpenseTag.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 3/7/26.
//
import Foundation
import SwiftUI
import SwiftData

public extension ExpenseTag {
    /// Templates shown during onboarding. Each call produces fresh instances with new UUIDs —
    /// they are only inserted into the store if the user selects them.
    static var suggestedTags: [ExpenseTag] {
        [
            ExpenseTag(name: "Shopping",          uiColor: .systemYellow, emoji: "🛍️"),
            ExpenseTag(name: "Dining",            uiColor: .systemOrange, emoji: "🍽️"),
            ExpenseTag(name: "Entertainment",     uiColor: .systemPink,   emoji: "🍿"),
            ExpenseTag(name: "Bills & Utilities", uiColor: .systemBlue,   emoji: "🏠"),
            ExpenseTag(name: "Groceries",         uiColor: .systemGreen,  emoji: "🥗"),
            ExpenseTag(name: "Subscriptions",     uiColor: .systemTeal,   emoji: "💻"),
            ExpenseTag(name: "Travel",            uiColor: .systemPurple, emoji: "✈️"),
            ExpenseTag(name: "Other",             uiColor: .systemGray,   emoji: "🔖"),
        ]
    }

    // Preview-only convenience instances.
    static var shopping: ExpenseTag      { .init(name: "Shopping",          uiColor: .systemYellow, emoji: "🛍️") }
    static var dining: ExpenseTag        { .init(name: "Dining",            uiColor: .systemOrange, emoji: "🍽️") }
    static var entertainment: ExpenseTag { .init(name: "Entertainment",     uiColor: .systemPink,   emoji: "🍿") }
    static var billsAndUtils: ExpenseTag { .init(name: "Bills & Utilities", uiColor: .systemBlue,   emoji: "🏠") }
    static var groceries: ExpenseTag     { .init(name: "Groceries",         uiColor: .systemGreen,  emoji: "🥗") }
    static var subscriptions: ExpenseTag { .init(name: "Subscriptions",     uiColor: .systemTeal,   emoji: "💻") }
    static var travel: ExpenseTag        { .init(name: "Travel",            uiColor: .systemPurple, emoji: "✈️") }
    static var other: ExpenseTag         { .init(name: "Other",             uiColor: .systemGray,   emoji: "🔖") }
    
    var entity: ExpenseTagEntity {
        ExpenseTagEntity(id: self.id, name: self.name, emoji: self.emoji, symbolName: self.symbolName)
    }
}

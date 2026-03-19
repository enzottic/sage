//
//  ExpenseTag+BuiltInTags.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 3/17/26.
//
import SwiftUI

extension ExpenseTag {
    static var builtInTags: [ExpenseTag] {
        return [
            ExpenseTag(name: "Shopping", uiColor: .systemYellow, emoji: "🛍️"),
            ExpenseTag(name: "Dining", uiColor: .systemOrange, emoji: "🍔"),
            ExpenseTag(name: "Entertainment", uiColor: .systemPink, emoji: "🍿"),
            ExpenseTag(name: "Bills & Utilities", uiColor: .systemBlue, emoji: "🏠"),
            ExpenseTag(name: "Groceries", uiColor: .systemGreen, emoji: "🥗"),
            ExpenseTag(name: "Subscriptions", uiColor: .systemTeal, emoji: "💻"),
            ExpenseTag(name: "Travel", uiColor: .systemPurple, emoji: "✈️"),
            ExpenseTag(name: "Other", uiColor: .systemGray, emoji: "🔖"),
        ]
    }
}

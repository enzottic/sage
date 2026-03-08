//
//  SageTag.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 3/7/26.
//
import Foundation
import SwiftUI
import SwiftData

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

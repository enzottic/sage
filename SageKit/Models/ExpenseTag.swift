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
    // Stable UUIDs for built-in tags — must never change, used to
    // detect whether seeding has already occurred (e.g. via CloudKit sync).
    enum BuiltInID {
        static let shopping       = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        static let dining         = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        static let entertainment  = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        static let billsAndUtils  = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!
        static let groceries      = UUID(uuidString: "00000000-0000-0000-0000-000000000005")!
        static let subscriptions  = UUID(uuidString: "00000000-0000-0000-0000-000000000006")!
        static let travel         = UUID(uuidString: "00000000-0000-0000-0000-000000000007")!
        static let other          = UUID(uuidString: "00000000-0000-0000-0000-000000000008")!
    }

    static var builtInTags: [ExpenseTag] {
        return [
            ExpenseTag(id: BuiltInID.shopping,      name: "Shopping",          uiColor: .systemYellow, emoji: "🛍️"),
            ExpenseTag(id: BuiltInID.dining,         name: "Dining",            uiColor: .systemOrange, emoji: "🍔"),
            ExpenseTag(id: BuiltInID.entertainment,  name: "Entertainment",     uiColor: .systemPink,   emoji: "🍿"),
            ExpenseTag(id: BuiltInID.billsAndUtils,  name: "Bills & Utilities", uiColor: .systemBlue,   emoji: "🏠"),
            ExpenseTag(id: BuiltInID.groceries,      name: "Groceries",         uiColor: .systemGreen,  emoji: "🥗"),
            ExpenseTag(id: BuiltInID.subscriptions,  name: "Subscriptions",     uiColor: .systemTeal,   emoji: "💻"),
            ExpenseTag(id: BuiltInID.travel,         name: "Travel",            uiColor: .systemPurple, emoji: "✈️"),
            ExpenseTag(id: BuiltInID.other,          name: "Other",             uiColor: .systemGray,   emoji: "🔖"),
        ]
    }

    static var defaultTags: [ExpenseTag] { builtInTags }

    static var shopping: ExpenseTag {
        .init(id: BuiltInID.shopping, name: "Shopping", uiColor: .yellow, emoji: "🛍️")
    }

    static var dining: ExpenseTag {
        .init(id: BuiltInID.dining, name: "Dining", uiColor: .orange, emoji: "🍽️")
    }

    static var entertainment: ExpenseTag {
        .init(id: BuiltInID.entertainment, name: "Entertainment", uiColor: .systemPink, emoji: "🍿")
    }

    static var billsAndUtils: ExpenseTag {
        .init(id: BuiltInID.billsAndUtils, name: "Bills & Utilities", uiColor: .blue, emoji: "🏠")
    }

    static var groceries: ExpenseTag {
        .init(id: BuiltInID.groceries, name: "Groceries", uiColor: .green, emoji: "🥗")
    }

    static var subscriptions: ExpenseTag {
        .init(id: BuiltInID.subscriptions, name: "Subscriptions", uiColor: .systemTeal, emoji: "💻")
    }

    static var travel: ExpenseTag {
        .init(id: BuiltInID.travel, name: "Travel", uiColor: .purple, emoji: "✈️")
    }

    static var other: ExpenseTag {
        .init(id: BuiltInID.other, name: "Other", uiColor: .gray, emoji: "🔖")
    }
}

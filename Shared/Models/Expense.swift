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

extension Expense {
    static var example: Expense {
        .init(name: "My Expense", amount: 123.45, category: .wants, date: Date.now)
    }
}

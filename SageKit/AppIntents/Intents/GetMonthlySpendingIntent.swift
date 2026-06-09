//
//  GetMonthlySpendingIntent.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 6/8/26.
//

import Foundation
import AppIntents
import SwiftData

struct GetMonthlySpendingIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Monthly Spending"
    
    @Parameter(title: "Category") var category: ExpenseCategory?
    @Parameter(title: "Tag") var tag: ExpenseTagEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("How much have I spent this month?") {
            \.$category
            \.$tag
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = try ExpenseStore()
        
        if let tag {
            let total = store.monthlyTotal(tagId: tag.id)
            return .result(dialog: "You've spent \(total.currencyString) on \(tag.name.lowercased()) this month.")
        } else if let category {
            let total = store.monthlyTotal(category: category)
            return .result(dialog: "You've spent \(total.currencyString) on \(category.rawValue.lowercased()) this moonth.")
        }
        
        let total = store.monthlyTotal()
        return .result(dialog: "You've spent \(total.currencyString) this month.")
    }
}

//
//  GetBudgetRemainingIntent.swift
//  FinanceTracker
//

import Foundation
import AppIntents
import SwiftData

struct GetBudgetRemainingIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Budget Remaining"

    @Parameter(title: "Category") var category: ExpenseCategory?

    static var parameterSummary: some ParameterSummary {
        Summary("How much budget do I have left?") {
            \.$category
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = try ExpenseStore()
        if let category {
            let remaining = store.remainingBudget(for: category)
            if remaining >= 0 {
                return .result(dialog: "You have \(remaining.currencyString) remaining in your \(category.rawValue.lowercased()) budget.")
            } else {
                return .result(dialog: "You're \((-remaining).currencyString) over your \(category.rawValue.lowercased()) budget.")
            }
        } else {
            let remaining = store.totalRemainingBudget()
            if remaining >= 0 {
                return .result(dialog: "You have \(remaining.currencyString) left across all budgets this month.")
            } else {
                return .result(dialog: "You're \((-remaining).currencyString) over your total budget this month.")
            }
        }
    }
}

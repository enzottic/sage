//
//  GetMonthlySpendingIntent.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 6/8/26.
//

import Foundation
import AppIntents
import SwiftData

public struct GetMonthlySpendingIntent: AppIntent {
    public static var title: LocalizedStringResource = "Get Monthly Spending"
    
    @Parameter(title: "Category") var category: ExpenseCategory?
    @Parameter(title: "Tag") var tag: ExpenseTagEntity?

    public static var parameterSummary: some ParameterSummary {
        Summary("How much have I spent this month?") {
            \.$category
            \.$tag
        }
    }
    
    public init() { }

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = ExpenseStore.shared
        
        if let tag, let total = try? store.monthlyTotal(tagId: tag.id) {
            return .result(dialog: "You've spent \(total.currencyString) on \(tag.name.lowercased()) this month.")
        } else if let category, let total = try? store.monthlyTotal(category: category) {
            return .result(dialog: "You've spent \(total.currencyString) on \(category.rawValue.lowercased()) this moonth.")
        }
        
        if let total = try? store.monthlyTotal() {
            return .result(dialog: "You've spent \(total.currencyString) this month.")
        }
        
        return .result(dialog: "Unable to get monthly spending from Sage.")
    }
}

//
//  AddExpenseIntent.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 6/8/26.
//

import Foundation
import AppIntents
import SwiftData

struct AddExpenseAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Add New Expense"
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Name") var name: String
    @Parameter(title: "Amount") var amount: Double
    @Parameter(title: "Category") var category: ExpenseCategory
    @Parameter(title: "Tag") var tag: ExpenseTagEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$name) for \(\.$amount) in \(\.$category)") {
            \.$tag
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = try ExpenseStore()
        let expense = Expense(name: name, amount: amount, category: category)
        if let tagEntity = tag {
            expense.tag = store.fetchTag(id: tagEntity.id)
        }
        store.addExpense(expense)
        try store.save()
        return .result(dialog: "Added \(name) for \(amount.currencyString).")
    }
}

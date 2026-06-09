//
//  AddExpenseIntent.swift
//  SageKit
//
//  Created by Tyler McCormick on 6/8/26.
//

import Foundation
import AppIntents
import SwiftData

public struct AddExpenseAppIntent: AppIntent {
    public static var title: LocalizedStringResource = "Add New Expense"
    
    @available(anyAppleOS 26.0, *)
    public static var supportedModes: IntentModes = .background

    @Parameter(title: "Name") var name: String
    @Parameter(title: "Amount") var amount: Double
    @Parameter(title: "Date") var date: Date?
    @Parameter(title: "Category") var category: ExpenseCategory?
    @Parameter(title: "Tag") var tag: ExpenseTagEntity?

    public static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$name) for \(\.$amount)") {
            \.$category
            \.$date
            \.$tag
        }
    }

    public init() { }
    
    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = try ExpenseStore()
        
        let expense = Expense(
            name: name,
            amount: amount,
            category: .wants,
            date: date ?? .now
        )
        
        if let tagEntity = tag {
            expense.tag = store.fetchTag(id: tagEntity.id)
        }
        
        store.addExpense(expense)
        try store.save()
        return .result(dialog: "Added \(name) for \(amount.currencyString).")
    }
}

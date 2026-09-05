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
    
    @Parameter(title: "Name") var name: String
    @Parameter(title: "Amount") var amount: Double
    @Parameter(title: "Date") var date: Date?
    @Parameter(title: "Category") var category: ExpenseCategory?
    @Parameter(title: "Tag") var tag: ExpenseTagEntity?
    
    @Dependency
    var expenseStore: ExpenseStore

    public static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$name) for \(\.$amount)") {
            \.$category
            \.$date
            \.$tag
        }
    }

    public init() { }
    
    // MARK: Methods
    
    @MainActor
    public func perform() async throws -> some ReturnsValue<ExpenseEntity> {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw $name.needsValueError("Enter an expense name.")
        }
        guard amount.isFinite, amount > 0 else {
            throw $amount.needsValueError("Enter an amount greater than zero.")
        }

        let expense = Expense(
            name: trimmedName,
            amount: amount,
            category: category ?? .wants,
            date: date ?? .now
        )
        
        let entity = try expenseStore.addExpenseAndSave(expense, tagID: tag?.id)
        return .result(value: entity)
    }
}

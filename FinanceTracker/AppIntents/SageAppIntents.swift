//
//  SageAppIntents.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/4/25.
//

import Foundation
import AppIntents
import SwiftData

struct AddExpenseAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Add New Expense"
    
    @Parameter(title: "Name") var name: String
    @Parameter(title: "Amount") var amount: Double
    @Parameter(title: "Category") var category: ExpenseCategory
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(for: Expense.self)
        let context = ModelContext(container)
        
        let expense = Expense(name: name, amount: amount, category: category)
        
        context.insert(expense)
        try! context.save()
        
        return .result(dialog: "Expense Added")
    }
}

struct GetLatestExpensesAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Get Latest Expenses"
    
    @Parameter(title: "Latest Expenses")
    var expenses: [ExpenseEntity]
    
}

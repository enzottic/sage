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

struct LatestExpensesAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "View Recent Expenses" }

    func perform() async throws -> some IntentResult {
        .result()
    }
}

struct UtilizationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "TotalSpentThisMonth" }
    
    func perform() async throws -> some IntentResult {
        .result()
    }
}

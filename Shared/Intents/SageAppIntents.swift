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
    @Parameter(title: "Tag") var tag: ExpenseTagEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$name) for \(\.$amount) in \(\.$category)") {
            \.$tag
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try await SageModelContainer.make()
        let context = ModelContext(container)

        let expense = Expense(name: name, amount: amount, category: category)

        if let tagEntity = tag {
            let all = try context.fetch(FetchDescriptor<ExpenseTag>())
            expense.tag = all.first { $0.id == tagEntity.id }
        }

        context.insert(expense)
        try context.save()

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

struct CategorySpotlightAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Category Spotlight" }
    static var description = IntentDescription("Choose a budget category to spotlight.")

    @Parameter(title: "Category", default: .needs)
    var category: ExpenseCategory

    func perform() async throws -> some IntentResult {
        .result()
    }
}

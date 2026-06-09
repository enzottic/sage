//
//  AddExpenseShortcut.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/4/25.
//

import Foundation
import AppIntents

struct SageShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] = [
        AppShortcut(
            intent: AddExpenseAppIntent(),
            phrases: [
                "Add a new expense to ${applicationName}",
                "Create a new ${applicationName} expense",
            ],
            shortTitle: "Add Expense",
            systemImageName: "dollarsign"
        ),
        AppShortcut(
            intent: GetMonthlySpendingIntent(),
            phrases: [
                "How much have I spent in ${applicationName}",
                "How much have I spent on \(\.$category) in ${applicationName}",
                "Check my spending this month in ${applicationName}",
                "Check my \(\.$category) spending this month in ${applicationName}",
            ],
            shortTitle: "Monthly Spending",
            systemImageName: "chart.bar"
        ),
        AppShortcut(
            intent: GetBudgetRemainingIntent(),
            phrases: [
                "How much budget do I have left this month in ${applicationName}",
                "How much budget do I have left for \(\.$category) this month in ${applicationName}",
                "How much spending do I have left this month in ${applicationName}",
                "How much spending do I have left for \(\.$category) this month in ${applicationName}",
            ],
            shortTitle: "Budget Remaining",
            systemImageName: "creditcard"
        ),
    ]
}

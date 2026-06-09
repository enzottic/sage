//
//  AddExpenseShortcut.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/4/25.
//

import Foundation
import AppIntents

public struct SageShortcutsProvider: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] = [
        AppShortcut(
            intent: AddExpenseAppIntent(),
            phrases: [
                "Add a new expense to ${applicationName}",
                "Add an expense to ${applicationName}",
                "Create a new ${applicationName} expense",
                "Add expense in ${applicationName}",
                "Create a new expense in ${applicationName}"
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
        AppShortcut(
            intent: FindExpensesIntent(),
            phrases: [
                "How much did I spend \(\.$timePeriod) in ${applicationName}",
                "What did I pay for \(\.$tag) in ${applicationName}",
                "How much did I spend on \(\.$category) in ${applicationName}",
                "Find my expenses in ${applicationName}",
            ],
            shortTitle: "Find Expenses",
            systemImageName: "magnifyingglass"
        ),
    ]
}

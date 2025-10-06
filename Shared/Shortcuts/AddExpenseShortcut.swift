//
//  AddExpenseShortcut.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/4/25.
//

import Foundation
import AppIntents

struct AddExpenseShortcut: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] = [
        AppShortcut(
            intent: AddExpenseAppIntent(),
            phrases: ["Add a new expense to ${applicationName}"],
            shortTitle: "Add Expense",
            systemImageName: "dollarsign"
        ),
        AppShortcut(
            intent: UtilizationAppIntent(),
            phrases: ["Gets utilization stats for ${applicationName}"],
            shortTitle: "Get Total Spent",
            systemImageName: "dollarsign"
        )
    ]
    
}

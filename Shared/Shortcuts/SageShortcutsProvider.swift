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
            phrases: ["Add a new expense to ${applicationName}"],
            shortTitle: "Add Expense",
            systemImageName: "dollarsign"
        ),
    ]
    
}

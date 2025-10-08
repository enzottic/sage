//
//  ExpenseEntry.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/7/25.
//

import Foundation
import WidgetKit

struct SageWidgetTimelineEntry: TimelineEntry {
    var date: Date
    var totalSpent: Double
    var totalWants: Double
    var totalNeeds: Double
    var totalSavings: Double
    var wantsUtilization: Double
    var needsUtilization: Double
    var latestExpenses: [Expense]
    
    init(
        date: Date = .now,
        totalSpent: Double = 0.0,
        totalWants: Double = 0.0,
        totalNeeds: Double = 0.0,
        totalSavings: Double = 0.0,
        wantsUtilization: Double = 0.0,
        needsUtilization: Double = 0.0,
        latestExpenses: [Expense] = []
    ) {
        self.date = date
        self.totalSpent = totalSpent
        self.totalWants = totalWants
        self.totalNeeds = totalNeeds
        self.totalSavings = totalSavings
        self.wantsUtilization = wantsUtilization
        self.needsUtilization = needsUtilization
        self.latestExpenses = latestExpenses
    }
}

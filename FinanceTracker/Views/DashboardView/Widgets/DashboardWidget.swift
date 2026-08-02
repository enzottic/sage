//
//  DashboardWidget.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 7/12/26.
//
import Foundation
import SageKit

/// How a widget is being displayed, derived from its row — never stored:
/// `.full` when it's alone in a row (rendered as a native list section),
/// `.compact` when it shares the row with other widgets (rendered as a card).
enum DashboardWidgetLayout {
    case full
    case compact
}

enum DashboardWidget: Hashable, Codable {
    case monthlyOverview
    case categoryUtilization
    case upcomingRecurring
    case recentExpenses(ExpenseRowItem.Style)
    case singleCategoryUtilization(ExpenseCategory)
}

/// One dashboard row. A single widget stretches the full width; multiple
/// widgets (2, 3, ...) share the row as equal-width cards.
struct DashboardRowConfiguration: Codable, Hashable {
    var widgets: [DashboardWidget]
}

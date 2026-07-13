//
//  DashboardWidget.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 7/12/26.
//
import Foundation
import SageKit

enum DashboardWidgetSize: Hashable, Codable { case full, half }

enum DashboardWidget: Hashable, Codable {
    case monthlyOverview
    case categoryUtilization
//    case upcomingRecurring
    case recentExpenses
    case singleCategoryUtilization(ExpenseCategory)
}

struct DashboardWidgetConfiguration: Codable, Hashable {
    var widget: DashboardWidget
    var size: DashboardWidgetSize
}

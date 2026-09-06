//
//  DashboardWidget.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 7/12/26.
//
import Foundation
import SageKit

enum DashboardCardStyle {
    static let cornerRadius: CGFloat = 24
}

/// How a widget renders inside its dashboard column.
enum DashboardWidgetLayout: Codable, Hashable {
    case full
    case compact
}

enum DashboardWidget: Hashable, Codable {
    case monthlyOverview
    case expenseCalendar
    case mostSpentTags
    case categoryUtilization
    case upcomingRecurring
    case recentExpenses(ExpenseRowItem.Style)
    case singleCategoryUtilization(ExpenseCategory)
}

/// One vertical group of widgets within a dashboard row.
struct DashboardColumnConfiguration: Codable, Hashable {
    var widgets: [DashboardWidget]
    var presentation: DashboardWidgetLayout

    init(
        widgets: [DashboardWidget],
        presentation: DashboardWidgetLayout = .full
    ) {
        self.widgets = widgets
        self.presentation = presentation
    }
}

/// One dashboard row. Columns share the available width equally, and the
/// widgets in each column are arranged vertically.
struct DashboardRowConfiguration: Codable, Hashable {
    var columns: [DashboardColumnConfiguration]

    init(columns: [DashboardColumnConfiguration]) {
        self.columns = columns
    }

    /// Convenience initializer for simple rows. One widget uses the full-width
    /// presentation. Multiple widgets become equal compact columns.
    init(widgets: [DashboardWidget]) {
        switch widgets.count {
        case 0:
            columns = []
        case 1:
            columns = [.init(widgets: widgets)]
        default:
            columns = widgets.map {
                .init(widgets: [$0], presentation: .compact)
            }
        }
    }

    var standaloneWidget: DashboardWidget? {
        guard columns.count == 1,
              let column = columns.first,
              column.presentation == .full,
              column.widgets.count == 1 else {
            return nil
        }
        return column.widgets.first
    }
}

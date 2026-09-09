import SwiftUI
import SageKit

extension DashboardWidgetID {
    var title: LocalizedStringKey {
        switch self {
        case .monthlyOverview: "Monthly Overview"
        case .needs: "Needs"
        case .wants: "Wants"
        case .savings: "Savings"
        case .expenseCalendar: "Expense Calendar"
        case .mostSpentTags: "Top Tags"
        case .upcomingRecurring: "Upcoming Expenses"
        case .recentExpenses: "Recent Expenses"
        }
    }

    var symbol: String {
        switch self {
        case .monthlyOverview: "chart.pie"
        case .needs: "house"
        case .wants: "bag"
        case .savings: "banknote"
        case .expenseCalendar: "calendar"
        case .mostSpentTags: "tag"
        case .upcomingRecurring: "arrow.trianglehead.2.clockwise.rotate.90"
        case .recentExpenses: "list.bullet.rectangle"
        }
    }

    var widget: DashboardWidget {
        switch self {
        case .monthlyOverview: .monthlyOverview
        case .needs: .singleCategoryUtilization(.needs)
        case .wants: .singleCategoryUtilization(.wants)
        case .savings: .singleCategoryUtilization(.savings)
        case .expenseCalendar: .expenseCalendar
        case .mostSpentTags: .mostSpentTags
        case .upcomingRecurring: .upcomingRecurring
        case .recentExpenses: .recentExpenses(.regular)
        }
    }

    static func rows(for order: [Self], isPad: Bool) -> [DashboardRowConfiguration] {
        let width = isPad ? 2 : 1
        return stride(from: 0, to: order.count, by: width).map { start in
            DashboardRowConfiguration(columns: order[start..<min(start + width, order.count)].map { id in
                DashboardColumnConfiguration(
                    widgets: [id.widget],
                    presentation: isPad && (id == .mostSpentTags || id == .upcomingRecurring) ? .compact : .full
                )
            })
        }
    }
}

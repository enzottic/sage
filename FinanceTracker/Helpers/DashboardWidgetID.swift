import Foundation
import UIKit

/// Stable preference identifiers, independent of a widget's rendering style.
enum DashboardWidgetID: String, CaseIterable, Identifiable {
    case monthlyOverview, needs, wants, savings, expenseCalendar
    case mostSpentTags, upcomingRecurring, recentExpenses

    var id: String { rawValue }

    static var defaultOrder: [Self] {
        defaultOrder(isPad: UIDevice.current.userInterfaceIdiom == .pad)
    }

    static func defaultOrder(isPad: Bool) -> [Self] {
        isPad
            ? [.monthlyOverview, .needs, .wants, .savings, .expenseCalendar,
               .recentExpenses, .mostSpentTags, .upcomingRecurring]
            : allCases
    }

    static func resolvedOrder(_ saved: [String], defaultOrder: [Self] = Self.defaultOrder) -> [Self] {
        var seen = Set<Self>()
        return (saved.compactMap(Self.init(rawValue:)) + defaultOrder)
            .filter { seen.insert($0).inserted }
    }
}

//
//  WidgetConfigurationIntents.swift
//  FinanceTracker
//

import AppIntents
import WidgetKit

struct UtilizationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Budget Utilization" }
    static var description = IntentDescription("Shows your budget utilization across all categories.")
}

struct CategorySpotlightAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Category Spotlight" }
    static var description = IntentDescription("Choose a budget category to spotlight.")

    @Parameter(title: "Category", default: .needs)
    var category: ExpenseCategory
}

//
//  WidgetConfigurationIntents.swift
//  FinanceTracker
//

import AppIntents
import WidgetKit

public struct UtilizationAppIntent: WidgetConfigurationIntent {
    public static var title: LocalizedStringResource { "Budget Utilization" }
    public static var description = IntentDescription("Shows your budget utilization across all categories.")
    
    public init() { }
}

public struct CategorySpotlightAppIntent: WidgetConfigurationIntent {
    public static var title: LocalizedStringResource { "Category Spotlight" }
    public static var description = IntentDescription("Choose a budget category to spotlight.")

    @Parameter(title: "Category", default: .needs)
    public var category: ExpenseCategory
    
    public init() { }
}

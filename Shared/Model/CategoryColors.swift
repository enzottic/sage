//
//  CategoryColors.swift
//  FinanceTracker
//

import SwiftUI

struct CategoryColors: Equatable {
    var needs: Color
    var wants: Color
    var savings: Color

    static let `default` = CategoryColors(
        needs: Color("NeedColor"),
        wants: Color("WantColor"),
        savings: Color("SavingColor")
    )

    static func load() -> CategoryColors {
        let defaults = UserDefaults(suiteName: "group.me.enzottic.SageAppGroup") ?? .standard
        return CategoryColors(
            needs: defaults.sageColor(forKey: "categoryColorNeeds") ?? Color("NeedColor"),
            wants: defaults.sageColor(forKey: "categoryColorWants") ?? Color("WantColor"),
            savings: defaults.sageColor(forKey: "categoryColorSavings") ?? Color("SavingColor")
        )
    }

    func color(for category: ExpenseCategory) -> Color {
        switch category {
        case .needs: return needs
        case .wants: return wants
        case .savings: return savings
        }
    }
}

private struct CategoryColorsKey: EnvironmentKey {
    static let defaultValue = CategoryColors.default
}

extension EnvironmentValues {
    var categoryColors: CategoryColors {
        get { self[CategoryColorsKey.self] }
        set { self[CategoryColorsKey.self] = newValue }
    }
}

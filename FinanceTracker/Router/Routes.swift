//
//  Routes.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 7/12/26.
//
import SwiftUI
import SageKit

enum SageTab: Equatable, Hashable {
    case home
    case expenses
    case stats
    case settings
    case search
    case addExpense
}

/// Destinations pushed onto a tab's navigation stack. Shared across tabs because
/// pushes originate from shared components (e.g. `ExpenseList`).
enum AppRoute: Hashable {
    case expenseDetail(Expense)                     // drill-down / edit
    case categoryDetail(ExpenseCategory, Date)      // category budget breakdown, for the given month
}

/// Starting values for a new expense opened from a contextual empty state.
struct ExpenseDraftDefaults: Hashable {
    var category: ExpenseCategory = .needs
    var date: Date = .now
    var isRecurring = false

    static func forMonth(_ month: Date, category: ExpenseCategory = .needs) -> Self {
        let calendar = Calendar.current
        return Self(category: category, date: calendar.isDate(month, equalTo: .now, toGranularity: .month)
                    ? .now : calendar.dateInterval(of: .month, for: month)?.start ?? month)
    }
}

/// Modally presented flows, hosted once at `RootTabView` so they appear above any tab.
enum SageSheet: Identifiable, Hashable {
    case addExpense(
        Expense?,
        receiptData: Data? = nil,
        presentationID: UUID = UUID(),
        defaults: ExpenseDraftDefaults = ExpenseDraftDefaults()
    )

    var id: UUID {
        switch self {
        case .addExpense(_, _, let presentationID, _): presentationID
        }
    }
}

/// External URLs the app can open. Unknown hosts return `nil`.
enum SageDeepLink {
    case addExpense

    init?(url: URL) {
        guard url.scheme == "sage" || url.scheme == "sage-dev" else { return nil }
        switch url.host {
        case "add-expense":
            self = .addExpense
        default: return nil
        }
    }
}

struct SageToast {
    enum Kind: Equatable { case progress, success, error }
    let message: String
    let kind: Kind
}

extension View {
    /// Registers every `AppRoute` destination once. Applied at each navigation stack root
    /// in place of duplicated `.navigationDestination` blocks.
    func detailRouteDestinations() -> some View {
        navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .expenseDetail(let expense):
                ExpenseDetailView(expense: expense)
            case .categoryDetail(let category, let month):
                CategoryDetailView(category: category, month: month)
            }
        }
    }
}

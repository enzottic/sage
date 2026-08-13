//
//  Routes.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 7/12/26.
//
import SwiftUI
import SageKit

// MARK: - Tabs

enum SageTab: Equatable, Hashable {
    case home
    case expenses
    case stats
    case settings
    case search
    case addExpense
}

// MARK: - Navigation routes (push)

/// Destinations pushed onto a tab's navigation stack. Shared across tabs because
/// pushes originate from shared components (e.g. `ExpenseList`).
enum AppRoute: Hashable {
    case expenseDetail(Expense)                     // drill-down / edit
    case categoryDetail(ExpenseCategory, Date)      // category budget breakdown, for the given month
}

// MARK: - Sheets (modal)

/// Modally presented flows, hosted once at `RootTabView` so they appear above any tab.
enum SageSheet: Identifiable, Hashable {
    case addExpense(Expense?)            // nil = blank, non-nil = duplicate prefill

    var id: Self { self }
}

// MARK: - Deep links

/// External URLs the app can open. Unknown hosts return `nil`.
enum SageDeepLink {
    case addExpense

    init?(url: URL) {
        guard url.scheme == "sage" || url.scheme == "sage-dev" else { return nil }
        switch url.host {
        case "add-expense": self = .addExpense
        default: return nil
        }
    }
}

// MARK: - Toast

struct SageToast {
    enum Kind { case success, error }
    let message: String
    let kind: Kind
}

// MARK: - Route destinations

extension View {
    /// Registers every `AppRoute` destination once. Applied at each navigation stack root
    /// in place of duplicated `.navigationDestination` blocks.
    func appRouteDestinations() -> some View {
        navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .expenseDetail(let expense):
                ExpenseDetailView(expense: expense)
            case .categoryDetail(let category, let month):
                CategoryDetailScreen(category: category, month: month)
            }
        }
    }
}

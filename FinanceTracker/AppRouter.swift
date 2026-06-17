//
//  AppRouter.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 3/17/26.
//
import SwiftUI
import SageKit

enum SageTab: Equatable, Hashable {
    case home
    case expenses
    case stats
    case settings
    case search
    case addExpense(expense: Expense?)
}

/// Push value for the "add expense" flow when used as a navigation destination.
struct AddExpenseRoute: Hashable {}

struct SageToast {
    enum Kind { case success, error }
    let message: String
    let kind: Kind
}

@Observable
class AppRouter {
    var homeRouter = HomeRouter()
    var expensesViewRouter = ExpensesViewRouter()
    var settingsRouter = SettingsRouter()
    
    var selectedTab: SageTab = .home
    var expensesMonth: Date = .now
    var toast: SageToast? = nil

    private var dismissTask: Task<Void, Never>?

    func showToast(_ toast: SageToast) {
        dismissTask?.cancel()
        withAnimation(.spring(duration: 0.4)) { self.toast = toast }
        dismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(duration: 0.4)) { self.toast = nil }
        }
    }

    func navigateTo(tab: SageTab) {
        selectedTab = tab
    }
}

@Observable
class HomeRouter {
    var navigationPath = NavigationPath()

    enum Route: Hashable {
        case categoryDetail(category: ExpenseCategory)
        case addExpense(expense: Expense?)
    }

    func navigateTo(route: Route) {
        navigationPath.append(route)
    }
}

@Observable
class ExpensesViewRouter {
    var navigationPath = NavigationPath()
    
    enum Route: Hashable {
        case addExpense(expense: Expense?)
    }
    
    func navigateTo(route: Route) {
        navigationPath.append(route)
    }
}

@Observable
class SettingsRouter {
    var navigationPath: [SettingsPage] = []

    func navigate(to page: SettingsPage) {
        navigationPath = [page]
    }

    func popToRoot() {
        navigationPath = []
    }
}

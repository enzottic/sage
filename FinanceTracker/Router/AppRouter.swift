//
//  AppRouter.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 3/17/26.
//
import SwiftUI
import SageKit

@Observable
@MainActor
final class AppRouter {
    var selectedTab: SageTab = .home

    // Per-tab navigation stacks (typed).
    var homePath: [AppRoute] = []
    var expensesPath: [AppRoute] = []
    var searchPath: [AppRoute] = []
    var settingsPath: [SettingsPage] = []

    /// Single modal presented above any tab.
    var presentedSheet: SageSheet?

    /// "Show All" courier: hands the dashboard's month to the Expenses tab.
    var expensesMonth: Date = .now

    var toast: SageToast?

    private var dismissTask: Task<Void, Never>?

    // MARK: - Navigation

    /// Appends a route to the currently visible tab's stack.
    func push(_ route: AppRoute) {
        switch selectedTab {
        case .home: homePath.append(route)
        case .expenses: expensesPath.append(route)
        case .search: searchPath.append(route)
        default: break
        }
    }

    func presentSheet(_ sheet: SageSheet) {
        presentedSheet = sheet
    }

    func dismissSheet() {
        presentedSheet = nil
    }

    func navigate(to link: SageDeepLink) {
        switch link {
        case .addExpense: presentSheet(.addExpense(nil))
        }
    }

    // MARK: - Toast

    func showToast(_ toast: SageToast) {
        dismissTask?.cancel()
        withAnimation(.spring(duration: 0.4)) { self.toast = toast }

        guard toast.kind != .progress else { return }

        dismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(duration: 0.4)) { self.toast = nil }
        }
    }

    func dismissToast() {
        dismissTask?.cancel()
        withAnimation(.spring(duration: 0.4)) { toast = nil }
    }
}

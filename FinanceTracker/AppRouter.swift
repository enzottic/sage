//
//  AppRouter.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 3/17/26.
//
import SwiftUI

enum SageTab: Equatable, Hashable {
    case home
    case expenses
    case stats
    case settings
    case search
}

@Observable
class AppRouter {
    var homeRouter = HomeRouter()
    var selectedTab: SageTab = .home
    
    func navigateTo(tab: SageTab) {
        selectedTab = tab
    }
}

@Observable
class HomeRouter {
    var navigationPath = NavigationPath()
    
    enum Route: Hashable {
        case categoryDetail(category: ExpenseCategory)
    }
    
    func navigateTo(route: Route) {
        navigationPath.append(route)
    }
}

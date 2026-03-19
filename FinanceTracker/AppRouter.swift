//
//  AppRouter.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 3/17/26.
//
import SwiftUI

enum Tab: Int {
    case home = 0
    case expenses = 1
    case stats = 2
    case settings = 3
}

@Observable
class AppRouter {
    var homeRouter = HomeRouter()
    var selectedTab = Tab.home
    
    func navigateTo(tab: Tab) {
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

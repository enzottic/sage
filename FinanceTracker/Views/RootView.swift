//
//  ContentView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 9/21/25.
//

import SwiftUI
import SwiftData

struct RootView: View {
    
    @State private var appRouter = AppRouter()

    var body: some View {
        TabView(selection: $appRouter.selectedTab) {
            HomeView(router: appRouter.homeRouter)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(Tab.home)
            
            ExpensesView()
                .tabItem {
                    Label("Expenses", systemImage: "list.bullet")
                }
                .tag(Tab.expenses)

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }
                .tag(Tab.stats)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(Tab.settings)
            
        }
        .background(Color.ui.background)
        .tint(Color.ui.sageColor)
    }
}

@Observable
class AppRouter {
    var homeRouter = HomeRouter()
    var selectedTab = Tab.home
    
    func navigateTo(tab: Tab) {
        selectedTab = tab
    }
}

enum Tab: Int {
    case home = 0
    case expenses = 1
    case stats = 2
    case settings = 3
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

#Preview {
    @Previewable @State var appConfig = AppConfiguration()
    RootView()
        .modelContainer(ModelContainer.preview)
        .environment(appConfig)
        .preferredColorScheme(appConfig.selectedAppearance.colorScheme)
}

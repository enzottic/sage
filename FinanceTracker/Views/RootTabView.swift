//
//  RootTabView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 9/21/25.
//

import SwiftUI
import SwiftData

struct RootTabView: View {
    
    @State private var appRouter = AppRouter()
    
    var body: some View {
        TabView(selection: $appRouter.selectedTab) {
            
            Tab("Home", systemImage: "house", value: .home) {
                HomeView(router: appRouter.homeRouter)
            }
            
            Tab("Expenses", systemImage: "list.bullet", value: .expenses) {
                ExpensesView()
            }

            Tab("Stats", systemImage: "chart.bar", value: .stats) {
                StatsView()
            }
            
            Tab("Settings", systemImage: "gear", value: .settings) {
                SettingsView()
            }
            
            Tab("Search", systemImage: "magnifyingglass", value: .search, role: .search) {
                SearchExpensesView()
            }
            
        }
        .background(Color.ui.background)
        .tint(Color.ui.sage)
    }
}


#Preview {
    @Previewable @State var appConfig = AppConfiguration()
    RootTabView()
        .modelContainer(previewAppContainer)
        .environment(appConfig)
        .preferredColorScheme(appConfig.selectedAppearance.colorScheme)
}

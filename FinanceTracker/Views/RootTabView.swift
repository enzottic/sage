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


#Preview {
    @Previewable @State var appConfig = AppConfiguration()
    RootTabView()
        .modelContainer(previewAppContainer)
        .environment(appConfig)
        .preferredColorScheme(appConfig.selectedAppearance.colorScheme)
}

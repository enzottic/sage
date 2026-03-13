//
//  ContentView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 9/21/25.
//

import SwiftUI
import SwiftData

struct RootView: View {
    
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Overview", systemImage: "house")
                }
                .tag(0)
            
            ExpensesView()
                .tabItem {
                    Label("Expenses", systemImage: "list.bullet")
                }
                .tag(1)

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
            
        }
        .background(Color.ui.background)
        .tint(Color.ui.sageColor)
    }
}

#Preview {
    @Previewable @State var appConfig = AppConfiguration()
    RootView()
        .modelContainer(ModelContainer.preview)
        .environment(appConfig)
        .preferredColorScheme(appConfig.selectedAppearance.colorScheme)
}

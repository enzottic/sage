//
//  ContentView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 9/21/25.
//

import SwiftUI
import SwiftData

struct SageTabView: View {
    
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
                    Label("Expenses", systemImage: "chart.pie.fill")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
            
        }
        .tint(Color.ui.sageColor)
    }
}

#Preview {
    SageTabView()
        .modelContainer(ModelContainer.preview)
}

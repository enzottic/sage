//
//  ContentView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 9/21/25.
//

import SwiftUI
import SwiftData

struct FinanceTrackerTabView: View {
    
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            OverviewView()
                .tabItem {
                    Label("Overview", systemImage: "house")
                }
                .tag(0)
            
            ExpensesView()
                .tabItem {
                    Label("Expenses", systemImage: "chart.pie.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        
    }

}

#Preview {
    FinanceTrackerTabView()
        .modelContainer(ModelContainer.preview)
}

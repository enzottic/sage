//
//  RootTabView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 9/21/25.
//

import SwiftUI
import SwiftData
import SageKit

struct RootTabView: View {
    
    @State private var appRouter = AppRouter()
    
    var body: some View {
        TabView(selection: $appRouter.selectedTab) {

            Tab("Home", systemImage: "house", value: SageTab.home) {
                HomeView()
            }

            Tab("Expenses", systemImage: "list.bullet", value: SageTab.expenses) {
                ExpensesView()
            }

            Tab("Stats", systemImage: "chart.bar", value: SageTab.stats) {
                StatsView()
            }

            Tab("Settings", systemImage: "gear", value: SageTab.settings) {
                SettingsView()
            }
            
            if #available(anyAppleOS 27.0, *) {
                Tab("Add Expense", systemImage: "plus", value: SageTab.addExpense, role: .prominent) {
                    AddExpenseView()
                }
            }
        }
        .overlay(alignment: .top) {
            if let toast = appRouter.toast {
                ToastPill(toast: toast)
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .task {
                        try? await Task.sleep(for: .milliseconds(700))
                        let prefix = toast.kind == .success ? "Success" : "Error"
                        AccessibilityNotification.Announcement("\(prefix): \(toast.message)").post()
                    }
            }
        }
        .sensoryFeedback(.success, trigger: appRouter.toast?.message) { _, newValue in newValue != nil }
        .animation(.spring(duration: 0.4), value: appRouter.toast == nil)
        .environment(appRouter)
        .background(.background)
        .tint(.sage)
        .onOpenURL { url in handleDeepLink(url) }
    }
    
    @MainActor
    private func handleDeepLink(_ url: URL) {
        guard (url.scheme == "sage" || url.scheme == "sage-dev"), url.host == "add-expense" else { return }
        appRouter.selectedTab = .home
        appRouter.homeRouter.navigateTo(route: .addExpense)
    }
}


#Preview {
    RootTabView()
        .environmentInjection()
}

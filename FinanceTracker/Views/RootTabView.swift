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
                HomeView()
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
        .background(Color.ui.background)
        .tint(Color.ui.sage)
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

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

    /// Intercepts selection of the prominent "Add Expense" tab (iOS 27+): it presents the
    /// add sheet instead of switching tabs, and never writes `.addExpense` to `selectedTab`.
    private var tabSelection: Binding<SageTab> {
        Binding(
            get: { appRouter.selectedTab },
            set: { newValue in
                if newValue == .addExpense {
                    appRouter.presentSheet(.addExpense(nil))
                } else {
                    appRouter.selectedTab = newValue
                }
            }
        )
    }

    var body: some View {
        TabView(selection: tabSelection) {

            Tab("Home", systemImage: "house", value: SageTab.home) {
                DashboardView()
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
                    // Unreachable: selecting this tab presents the add sheet (see tabSelection).
                    Color.clear
                }
            } else {
                Tab("Search", systemImage: "magnifyingglass", value: SageTab.search, role: .search) {
                    SearchExpensesView()
                }
            }
        }
        .sheet(item: $appRouter.presentedSheet) { sheet in
            switch sheet {
            case .addExpense(let expense):
                NavigationStack {
                    AddExpenseView(expense: expense)
                }
            case .splitwiseImport:
                SplitwiseImportView()
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
        .onOpenURL { url in
            if let link = SageDeepLink(url: url) {
                appRouter.navigate(to: link)
            }
        }
    }
}


#Preview {
    RootTabView()
        .environmentInjection()
}

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
    @State private var whatsNewRelease: WhatsNewRelease?

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

        }
        .accessibilityIdentifier("main-tab-view")
        .sheet(item: $appRouter.presentedSheet) { sheet in
            switch sheet {
            case .addExpense(let expense):
                NavigationStack {
                    AddExpenseView(expense: expense)
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
        .onOpenURL { url in
            if let link = SageDeepLink(url: url) {
                appRouter.navigate(to: link)
            }
        }
        .task {
            whatsNewRelease = WhatsNewStore.releaseToPresent()
            // Marked seen at presentation, so dismissing by swipe counts the same as the button.
            WhatsNewStore.markCurrentVersionSeen()
        }
        .sheet(item: $whatsNewRelease) { release in
            WhatsNewSheet(release: release)
        }
    }
}


#Preview {
    RootTabView()
        .environmentInjection()
}

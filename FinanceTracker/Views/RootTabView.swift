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
    @State private var query: String? = nil
    @State private var tabSelection: SageTab = .home

    var body: some View {
        TabView(selection: $tabSelection) {

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
            
            Tab("Search", systemImage: "magnifyingglass", value: SageTab.search, role: .search) {
                SearchExpensesView()
            }

        }
        .tabViewSearchActivation(.searchTabSelection)
        .accessibilityIdentifier("main-tab-view")
        .sheet(item: $appRouter.presentedSheet) { sheet in
            switch sheet {
            case .addExpense(let expense, let receiptData):
                NavigationStack {
                    AddExpenseView(expense: expense, receiptData: receiptData)
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
                        let prefix: String
                        switch toast.kind {
                        case .progress: prefix = "In progress"
                        case .success: prefix = "Success"
                        case .error: prefix = "Error"
                        }
                        AccessibilityNotification.Announcement("\(prefix): \(toast.message)").post()
                    }
            }
        }
        .sensoryFeedback(.success, trigger: appRouter.toast?.kind == .success) { _, isSuccess in isSuccess }
        .animation(.spring(duration: 0.4), value: appRouter.toast == nil)
        .environment(appRouter)
        .background(.background)
        .tint(.sage)
        .onOpenURL { url in
            if url.isFileURL {
                appRouter.importReceipt(from: url)
            } else if let link = SageDeepLink(url: url) {
                appRouter.navigate(to: link)
            }
        }
        .task {
            whatsNewRelease = WhatsNewStore.releaseToPresent()
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

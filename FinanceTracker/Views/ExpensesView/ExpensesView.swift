//
//  ExpensesScreen.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 9/21/25.
//

import SwiftUI
import SwiftData
import SageKit

struct ExpensesView: View {
    @Environment(SplitwiseService.self) private var splitwiseService
    @Environment(AppRouter.self) private var appRouter

    @State private var selectedMonth: Date
    @State private var showSplitwiseImport: Bool = false
    @State private var slideDirection: Edge = .leading
    @State private var searchText: String = ""

    let calendar = Calendar.current
    let formatter: DateFormatter

    init(month: Date = Date()) {
        _selectedMonth = State(initialValue: Date())
        formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
    }

    var body: some View {
        NavigationStack(path: Bindable(appRouter.expensesViewRouter).navigationPath) {
            MonthExpensesList(month: selectedMonth, searchText: searchText)
                .frame(maxWidth: .infinity)
                .background(.sageBackground)
                .navigationTitle(formatter.string(from: selectedMonth))
                .searchable(text: $searchText, prompt: "Search expenses")
                .navigationDestination(for: ExpensesViewRouter.Route.self) { route in
                    switch route {
                    case .addExpense(let expense):
                        AddExpenseView(expense: expense)
                    }
                }
                .navigationDestination(for: Expense.self) { expense in
                    ExpenseDetailView(expense: expense)
                }
                .sheet(isPresented: $showSplitwiseImport) {
                    SplitwiseImportView()
                }
                .toolbar {
                    SageToolbar(
                        onPrevious: {
                            slideDirection = .leading
                            selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth)!
                        },
                        onNext: {
                            slideDirection = .trailing
                            selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth)!
                        },
                        onAdd: { appRouter.expensesViewRouter.navigateTo(route: .addExpense(expense: nil)) },
                        onImportFromSplitwise: splitwiseService.isConfigured
                            ? { showSplitwiseImport = true }
                            : nil,
                    )
                }
                .gradientBackground()
                .onChange(of: appRouter.expensesMonth) { _, month in
                    selectedMonth = month
                }
        }
    }
}


#Preview {
    ExpensesView()
        .environmentInjection()
}

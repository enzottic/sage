//
//  ExpensesScreen.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 9/21/25.
//

import SwiftUI
import SwiftData

struct ExpensesView: View {
    @Environment(SplitwiseService.self) private var splitwiseService
    @Environment(AppRouter.self) private var appRouter

    @State private var selectedMonth: Date
    @State private var showSplitwiseImport: Bool = false
    @State private var slideDirection: Edge = .leading
    @State private var searchText: String = ""
    @State private var navigationPath = NavigationPath()

    let calendar = Calendar.current
    let formatter: DateFormatter

    init(month: Date = Date()) {
        _selectedMonth = State(initialValue: Date())
        formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            MonthExpensesList(month: selectedMonth, searchText: searchText)
                .frame(maxWidth: .infinity)
                .background(Color.ui.background)
                .navigationTitle(formatter.string(from: selectedMonth))
                .searchable(text: $searchText, prompt: "Search expenses")
                .navigationDestination(for: Expense.self) { expense in
                    ExpenseDetailView(expense: expense)
                }
                .navigationDestination(for: AddExpenseRoute.self) { _ in
                    AddExpenseView()
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
                        onAdd: { navigationPath.append(AddExpenseRoute()) },
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
        .modelContainer(previewAppContainer)
}

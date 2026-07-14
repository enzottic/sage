//
//  RecentExpensesWidget.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 7/12/26.
//
import SwiftUI
import SwiftData
import SageKit

struct RecentExpensesWidget: View {
    @Environment(AppConfiguration.self) var config
    @Environment(AppRouter.self) var appRouter
    
    @Query var recentExpenses: [Expense]
    @State private var selectedMonth: Date
    let rowStyle: ExpenseRowItem.Style

    init(selectedMonth: Date = .now, rowStyle: ExpenseRowItem.Style = .condensed) {
        _recentExpenses = expenseQuery(for: selectedMonth, limit: 5)
        _selectedMonth = .init(initialValue: selectedMonth)
        self.rowStyle = rowStyle
    }

    var body: some View {
        if !recentExpenses.isEmpty {
            Section {
                ExpenseList(expenses: recentExpenses, rowStyle: rowStyle)
            } header: {
                HStack(alignment: .firstTextBaseline) {
                    Text("Recent Expenses")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Button("Show All") {
                        appRouter.expensesMonth = selectedMonth
                        appRouter.selectedTab = .expenses
                    }
                    .font(.subheadline)
                }
            }
        }
    }
}

#Preview {
    List {
        RecentExpensesWidget(selectedMonth: .now)
            .environmentInjection()
    }
}


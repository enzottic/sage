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
    
    private let calendar = Calendar.current
    
    @Query var recentExpenses: [Expense]
    @State private var selectedMonth: Date
    
    init(selectedMonth: Date = .now) {
        _recentExpenses = expenseQuery(for: .now, limit: 10)
        _selectedMonth = .init(initialValue: selectedMonth)
    }
    
    var recentExpensesByDay: [(day: Date, expenses: [Expense])] {
        let grouped = Dictionary(grouping: recentExpenses) {
            calendar.startOfDay(for: $0.date)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .prefix(7)
            .map { (day: $0.key, expenses: $0.value) }
    }
    
    var body: some View {
        if !recentExpenses.isEmpty {
            Section {
            } footer: {
                HStack(alignment: .firstTextBaseline) {
                    Text("Recent Expenses")
                    Spacer()
                    Button("Show All") {
                        appRouter.expensesMonth = selectedMonth
                        appRouter.selectedTab = .expenses
                    }
                }
                .font(.subheadline)
                .fontWeight(.semibold)
            }

            ForEach(recentExpensesByDay, id: \.day) { group in
                Section {
                    ExpenseList(expenses: group.expenses)
                } header: {
                    HStack {
                        Text(group.day.relative())
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(group.expenses.total.currencyString)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }
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


//
//  BudgetView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 9/21/25.
//

import SwiftUI
import SwiftData

struct ExpensesView: View {
    @Query private var expenses: [Expense]
    
    @State private var selectedMonth = Date()
    @State private var month: Date = Date()
    
    @AppStorage("totalMonthlyIncome") private var totalMonthlyIncome: Double = 0.0
    @AppStorage("wantsPercent") private var wantsPercent: Double = 0.3
    @AppStorage("needsPercent") private var needsPercent: Double = 0.5

    var formattedMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    var totalSpentThisMonth: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    var totalWants: Double {
        totalMonthlyIncome * wantsPercent
    }
    
    var totalNeeds: Double {
        totalMonthlyIncome * needsPercent
    }
    
    var wantsSpent: Double {
        expenses
            .filter { $0.category == .wants }
            .reduce(0) { $0 + $1.amount }
    }
    
    var needsSpent: Double {
        expenses
            .filter { $0.category == .needs }
            .reduce(0) { $0 + $1.amount }
    }

    init(month: Date = Date()) {
        self._selectedMonth = State(initialValue: month)
        
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: month)?.start ?? month
        let endOfMonth = calendar.dateInterval(of: .month, for: month)?.end ?? month
        
        _expenses = Query(
            filter: #Predicate<Expense> { expense in
                expense.date >= startOfMonth && expense.date < endOfMonth
            },
            sort: [SortDescriptor(\Expense.date, order: .reverse)]
        )
    }
    
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                if (expenses.isEmpty) {
                    ContentUnavailableView(
                        "No expenses",
                        systemImage: "dollarsign",
                        description: Text("Add expenses to start tracking")
                    )
                } else {
                    List {
                        Section(header:
                            Text(formattedMonthYear)
                                .font(.title)
                                .fontWeight(.bold)
                                .padding(.bottom, 8)
                        ) {
                            ExpenseListView(expenses: expenses)
                        }
                    }
                }
            }
            .navigationTitle("Monthly Expenses")
        }
    }
    
    private func budgetBlock(title: String, amount: Double, color: Color = .secondary) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(amount.formatted(.currency(code: "USD")))
                .font(.title)
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    ExpensesView()
        .modelContainer(ModelContainer.preview)
}

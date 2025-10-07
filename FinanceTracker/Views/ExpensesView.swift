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
    @State private var expenseToDelete: Expense? = nil
    @State private var showingDeleteConfirmation: Bool = false
    
    var selectableMonths: Set<Date> {
        let calendar = Calendar.current
        return Set (
            expenses.map { expense in
                calendar.date(from: calendar.dateComponents([.year, .month], from: expense.date))!
            }
        )
    }
    
    var groupedExpenses: [Date: [Expense]] {
        Dictionary(grouping: expenses) { expense in
            Calendar.current.startOfDay(for: expense.date)
        }
    }
    
    var sortedDates: [Date] {
        groupedExpenses.keys.sorted(by: >)
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
                        ForEach(sortedDates, id: \.self) { date in
                            Section(header: Text(date.formatted(date: .abbreviated, time: .omitted))) {
                                ExpenseListGroup(expenses: groupedExpenses[date] ?? [])
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Color.ui.background)
            .navigationTitle("Monthly Expenses")
            .onAppear {
                print(selectableMonths)
            }
        }
    }
    
    private func budgetBlock(title: String, amount: Double, color: Color = .secondary) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))
                .font(.title)
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func deleteExpense(indexSet: IndexSet) {
        
    }
}

#Preview {
    ExpensesView()
        .modelContainer(ModelContainer.preview)
}

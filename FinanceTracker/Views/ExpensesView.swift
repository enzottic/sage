//
//  ExpensesScreen.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 9/21/25.
//

import SwiftUI
import SwiftData

struct ExpensesView: View {
    @Query(sort: [SortDescriptor(\Expense.date, order: .reverse)])
    private var allExpenses: [Expense]
    
    @State private var selectedMonth = Date()
    @State private var selectedExpense: Expense? = nil
    @State private var transitionDirection: Edge = .leading
    @State private var showAddExpenseSheet: Bool = false
    
    let calendar = Calendar.current
    let formatter: DateFormatter
    
    var expensesForMonth: [Expense] {
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)?.start ?? selectedMonth
        let endOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)?.end ?? selectedMonth
            
        return allExpenses.filter { expense in
            expense.date >= startOfMonth && expense.date < endOfMonth
        }
    }

    var selectableMonths: Set<Date> {
        let calendar = Calendar.current
        return Set (
            allExpenses.map { expense in
                calendar.date(from: calendar.dateComponents([.year, .month], from: expense.date))!
            }
        )
    }
    
    var groupedExpenses: [Date: [Expense]] {
        Dictionary(grouping: expensesForMonth) { expense in
            Calendar.current.startOfDay(for: expense.date)
        }
    }
    
    var sortedDates: [Date] {
        groupedExpenses.keys.sorted(by: >)
    }

    init(month: Date = Date()) {
        self._selectedMonth = State(initialValue: month)
        formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if (expensesForMonth.isEmpty) {
                    ContentUnavailableView(
                        "No expenses for this month",
                        systemImage: "dollarsign",
                    )
                } else {
                    List {
                        ForEach(sortedDates, id: \.self) { date in
                            let expenses = groupedExpenses[date] ?? []
                            expensesList(in: date, expenses: expenses)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .id(selectedMonth)
               }
            }
            .frame(maxWidth: .infinity)
            .background(Color.ui.background)
            .navigationTitle(formatter.string(from: selectedMonth))
            .sheet(item: $selectedExpense) { expense in
                ExpenseDetailView(expense: expense)
                    .presentationDetents([.medium])
                    .presentationBackground(Color.ui.background)
            }
            .sheet(isPresented: $showAddExpenseSheet, content: {
                AddExpenseSheet()
                    .presentationDetents([.large])
                    .presentationBackground(Color.ui.background)
            })
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button {
                        withAnimation(.easeInOut) {
                            transitionDirection = .trailing
                            selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth)!
                        }
                    } label: {
                        Label("Previous Month", systemImage: "chevron.left")
                    }
                    
                    Button {
                        withAnimation(.easeInOut) {
                            transitionDirection = .leading
                            selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth)!
                        }
                    } label: {
                        Label("Next Month", systemImage: "chevron.right")
                    }
                }
                ToolbarItem {
                    Button {
                        showAddExpenseSheet = true
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                    .background(Color.ui.cardBackground)
                    .tint(Color.ui.sageColor)
                }
            }
        }
    }
    
    func expensesList(in date: Date, expenses: [Expense]) -> some View {
        Section {
            ExpenseListGroup(expenses: expenses, selectedExpense: $selectedExpense)
        } header: {
            Text(date.formatted(date: .abbreviated, time: .omitted))
                .foregroundStyle(.secondary)
                .font(.caption)
        }
    }
}


#Preview {
    ExpensesView()
        .modelContainer(ModelContainer.preview)
}

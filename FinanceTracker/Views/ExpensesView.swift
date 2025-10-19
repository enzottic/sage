//
//  BudgetView.swift
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
    @State private var expenseToDelete: Expense? = nil
    @State private var showingDeleteConfirmation: Bool = false
    @State private var selectedExpense: Expense? = nil
    @State private var transitionDirection: Edge = .leading
    
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
                HStack {
                    Button {
                        withAnimation(.easeInOut) {
                            transitionDirection = .trailing
                            selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth)!
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    
                    Spacer()
                    
                    Text(formatter.string(from: selectedMonth))
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.easeInOut) {
                            transitionDirection = .leading
                            selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth)!
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
                    
                if (expensesForMonth.isEmpty) {
                    ContentUnavailableView(
                        "No expenses for this month",
                        systemImage: "dollarsign",
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 25) {
                            ForEach(sortedDates, id: \.self) { date in
                                let expenses = groupedExpenses[date] ?? []
                                expensesList(in: date, expenses: expenses)
                            }
                        }
                    }
                    .id(selectedMonth)
               }
            }
            .padding([.horizontal, .top], 10)
            .frame(maxWidth: .infinity)
            .background(Color.ui.background)
            .navigationTitle("All Expenses")
            .sheet(item: $selectedExpense) { expense in
                ExpenseDetailView(expense: expense)
                    .presentationDetents([.medium])
            }
        }
    }
    
    func expensesList(in date: Date, expenses: [Expense]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(date.formatted(date: .abbreviated, time: .omitted))
                .foregroundStyle(.secondary)
                .font(.caption)
            
            Grid(alignment: .leading, horizontalSpacing: 8) {
                ForEach(expenses) { expense in
                    GridRow {
                        Circle()
                            .fill(expense.category.color)
                            .frame(width: 10, height: 10)
                        Text(expense.name)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: 150, alignment: .leading)
                        
                        TagCapsule(tag: expense.tag, .small)
                        
                        Spacer()
                        
                        Text(expense.amount.currencyStringWithFraction)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedExpense = expense
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}


#Preview {
    ExpensesView()
        .modelContainer(ModelContainer.preview)
}

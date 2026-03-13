//
//  MonthExpensesList.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 3/13/26.
//
import SwiftUI
import SwiftData

struct MonthExpensesList: View {
    @Query private var expenses: [Expense]
    @Binding var selectedExpense: Expense?
    
    init(month: Date, selectedExpense: Binding<Expense?>) {
        let calendar = Calendar.current
        let start = calendar.dateInterval(of: .month, for: month)?.start ?? month
        let end = calendar.dateInterval(of: .month, for: month)?.end ?? month

       _expenses = Query(
           filter: #Predicate<Expense> { expense in
               expense.date >= start && expense.date < end
           },
           sort: [SortDescriptor(\Expense.date, order: .reverse)]
       )
       _selectedExpense = selectedExpense
    }
    
    var groupedExpenses: [Date: [Expense]] {
        Dictionary(grouping: expenses) { expense in
            Calendar.current.startOfDay(for: expense.date)
        }
    }
    
    var sortedDates: [Date] {
        groupedExpenses.keys.sorted(by: >)
    }

    var body: some View {
        VStack {
            if (expenses.isEmpty) {
                ContentUnavailableView(
                    "No expenses for this month",
                    systemImage: "dollarsign",
                )
            } else {
                List {
                    ForEach(sortedDates, id: \.self) { date in
                        let expenses = groupedExpenses[date] ?? []
                        Section {
                            ExpenseListGroup(expenses: expenses, selectedExpense: $selectedExpense)
                        } header: {
                            Text(date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .sheet(item: $selectedExpense) { expense in
                    ExpenseDetailView(expense: expense)
                        .presentationDetents([.medium])
                        .presentationBackground(Color.ui.background)
                }
           }
        }
    }
}

#Preview {
    @Previewable @State var month = Date()
    @Previewable @State var selectedExpense: Expense? = nil
    
    MonthExpensesList(month: month, selectedExpense: $selectedExpense)
        .modelContainer(ModelContainer.preview)
}

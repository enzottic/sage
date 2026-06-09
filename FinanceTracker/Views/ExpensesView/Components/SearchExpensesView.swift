//
//  SearchExpensesView.swift
//  FinanceTracker
//
//  Created on 4/10/26.
//

import SwiftUI
import SwiftData

struct SearchExpensesView: View {
    @Query(sort: [SortDescriptor(\Expense.date, order: .reverse)]) private var expenses: [Expense]
    @State private var searchText: String = ""
    
    var filteredExpenses: [Expense] {
        if searchText.isEmpty { return [] }
        return expenses.filter { expense in
            expense.name.localizedCaseInsensitiveContains(searchText)
            || expense.note.localizedCaseInsensitiveContains(searchText)
            || (expense.tag?.name.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var groupedExpenses: [Date: [Expense]] {
        Dictionary(grouping: filteredExpenses) { expense in
            Calendar.current.startOfDay(for: expense.date)
        }
    }
    
    var sortedDates: [Date] {
        groupedExpenses.keys.sorted(by: >)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if searchText.isEmpty {
                    ContentUnavailableView(
                        "Search All Expenses",
                        systemImage: "magnifyingglass",
                        description: Text("Search by name, note, or tag")
                    )
                } else if filteredExpenses.isEmpty {
                    ContentUnavailableView(
                        "No matching expenses",
                        systemImage: "magnifyingglass"
                    )
                } else {
                    List {
                        ForEach(sortedDates, id: \.self) { date in
                            let expenses = groupedExpenses[date] ?? []
                            Section {
                                ExpenseList(expenses: expenses)
                            } header: {
                                Text(date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .frame(maxWidth: .infinity)
            .background(.sageBackground)
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Search expenses")
            .navigationDestination(for: Expense.self) { expense in
                ExpenseDetailView(expense: expense)
            }
            .gradientBackground()
        }
    }
}

#Preview {
    SearchExpensesView()
        .modelContainer(previewAppContainer)
}

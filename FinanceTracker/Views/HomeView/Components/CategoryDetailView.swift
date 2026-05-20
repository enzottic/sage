//
//  CategoryDetailView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 3/13/26.
//

import SwiftUI
import SwiftData

struct CategoryDetailView: View {
    let category: ExpenseCategory
    let utilization: Double
    let used: Double
    let total: Double

    @Query(sort: [SortDescriptor(\Expense.date, order: .reverse)])
    private var allExpenses: [Expense]

    var expenses: [Expense] {
        allExpenses.filter { $0.category == category }
    }

    var body: some View {
        List {
            Section {
                ExpenseList(expenses: expenses)
            } header: {
                Text("Recent Purchases")
            }
        }
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.large)
        .gradientBackground(color: category.color)
    }
}

#Preview {
    NavigationStack {
        CategoryDetailView(category: ExpenseCategory.wants, utilization: 0.3, used: 100, total: 300)
    }
    .modelContainer(previewAppContainer)
    .environment(AppRouter())
}

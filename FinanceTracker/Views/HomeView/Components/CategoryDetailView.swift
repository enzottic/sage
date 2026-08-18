//
//  CategoryDetailView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 3/13/26.
//

import SwiftUI
import SwiftData
import SageKit

struct CategoryDetailView: View {
    @Environment(\.categoryColors) private var categoryColors
    @Environment(AppConfiguration.self) private var config
    
    let category: ExpenseCategory
    let utilization: Double
    let used: Double
    let total: Double
    let month: Date

    @Query(sort: [SortDescriptor(\Expense.date, order: .reverse)])
    private var monthExpenses: [Expense]

    init(category: ExpenseCategory, utilization: Double, used: Double, total: Double, month: Date) {
        self.category = category
        self.utilization = utilization
        self.used = used
        self.total = total
        self.month = month

        let cal = Calendar.current
        let start = cal.dateInterval(of: .month, for: month)?.start ?? month
        let end = cal.dateInterval(of: .month, for: month)?.end ?? month
        _monthExpenses = Query(
            filter: #Predicate<Expense> { $0.date >= start && $0.date <= end },
            sort: [SortDescriptor(\Expense.date, order: .reverse)]
        )
    }

    var expenses: [Expense] {
        monthExpenses.filter { $0.category == category }
    }
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Text("Spending")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(used.currencyString)
                        .font(.largeTitle.bold())
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowBackground(Color.clear)
            }

            if !expenses.isEmpty {
                Section {
                    TopSpendingBreakdown(
                        expenses: expenses,
                        accentColor: category.color(in: categoryColors),
                        untaggedLabel: "Untagged"
                    )
                } header: {
                    Text("Top Tags")
                        .font(.subheadline)
                }
            }

            Section {
                ExpenseList(expenses: expenses)
            } header: {
                Text("Recent Purchases")
                    .font(.subheadline)
            }
        }
        .navigationTitle(category.rawValue)
        .navigationSubtitle(month.formatted(.dateTime.month(.wide).year()))
        .navigationBarTitleDisplayMode(.large)
        .listSectionSpacing(.compact)
        .scrollContentBackground(.hidden)
        .background(.sageBackground)
        .gradientBackground(color: category.color(in: categoryColors))
    }
}

#Preview {
    NavigationStack {
        CategoryDetailView(category: ExpenseCategory.wants, utilization: 0.3, used: 100, total: 300, month: .now)
    }
    .environmentInjection()
}

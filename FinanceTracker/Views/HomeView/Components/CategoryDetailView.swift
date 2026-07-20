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
            SingleCategoryUtilizationWidget(category: category, layout: .full, selectedMonth: month, isNavigable: false)

            if !expenses.isEmpty {
                Section {
                    TopSpendingBreakdown(
                        expenses: expenses,
                        accentColor: category.color(in: categoryColors),
                        title: "Top Tags",
                        untaggedLabel: "Untagged"
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }

            Section {
                ExpenseList(expenses: expenses)
            } header: {
                Text("Recent Purchases")
            }
        }
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.large)
        .listSectionSpacing(.compact)
        .monthScope(month)
        .gradientBackground(color: category.color(in: categoryColors))
    }
}

/// Shows which month a screen is scoped to, using the navigation subtitle where it
/// exists and a toolbar pill on older systems.
private struct MonthScopeModifier: ViewModifier {
    let month: Date

    private var label: String { month.formatted(.dateTime.month(.wide).year()) }

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.navigationSubtitle(label)
        } else {
            content.toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text(label)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(.quaternary))
                }
            }
        }
    }
}

private extension View {
    func monthScope(_ month: Date) -> some View {
        modifier(MonthScopeModifier(month: month))
    }
}

#Preview {
    NavigationStack {
        CategoryDetailView(category: ExpenseCategory.wants, utilization: 0.3, used: 100, total: 300, month: .now)
    }
    .environmentInjection()
}

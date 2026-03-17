//
//  ExpensesView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 9/21/25.
//

import SwiftUI
import SwiftData
import FoundationModels
import Charts

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppConfiguration.self) private var config
    
    @Query(sort: [SortDescriptor(\Expense.date, order: .reverse)])
    private var allExpenses: [Expense]
    
    @Bindable var router: HomeRouter
    @State private var selectedMonth: Date = .now
    @State private var selectedExpense: Expense? = nil
    @State private var addExpenseSheetIsPresented: Bool = false


    init(router: HomeRouter) {
        self.router = router
    }
    
    var monthlyExpenses: [Expense] {
        let startOfMonth = Calendar.current.dateInterval(of: .month, for: selectedMonth)?.start ?? selectedMonth
        let endOfMonth = Calendar.current.dateInterval(of: .month, for: selectedMonth)?.end ?? selectedMonth
        
        return allExpenses.filter { expense in
            expense.date >= startOfMonth && expense.date < endOfMonth
        }
    }
    
    var recentPurchases: [Expense] {
        Array(monthlyExpenses.prefix(10))
    }

    var totalSpent: Double {
        monthlyExpenses.total
    }
    
    func utilization(for category: ExpenseCategory) -> Double {
        switch category {
        case .wants: config.wantsBudget == 0 ? 0 : monthlyExpenses.wantsUsed / config.wantsBudget
        case .needs: config.needsBudget == 0 ? 0 : monthlyExpenses.needsUsed / config.needsBudget
        case .savings: config.savingsBudget == 0 ? 0 : monthlyExpenses.savingsUsed / config.savingsBudget
        }
    }
    
    func spent(for category: ExpenseCategory) -> Double {
        switch category {
        case .wants: monthlyExpenses.wantsUsed
        case .needs: monthlyExpenses.needsUsed
        case .savings: monthlyExpenses.savingsUsed
        }
    }
    
    func budget(for category: ExpenseCategory) -> Double {
        switch category {
        case .wants: config.wantsBudget
        case .needs: config.needsBudget
        case .savings: config.savingsBudget
        }
    }
    
    var body: some View {
        NavigationStack(path: $router.navigationPath) {
            List {
                monthlyOverview
                utilizationSection
                recentExpensesList
            }
            .navigationDestination(for: HomeRouter.Route.self) { route in
                switch route {
                case .categoryDetail(let category):
                    CategoryDetailView(category: category, utilization: utilization(for: category), used: spent(for: category),total: budget(for: category), selectedExpense: $selectedExpense)
                }
            }
            .navigationTitle("\(selectedMonth.formatted(.dateTime.month(.wide).year()))")
            .scrollContentBackground(.hidden)
            .background(Color.ui.background)
            .sheet(isPresented: $addExpenseSheetIsPresented) {
                AddExpenseSheet()
                    .presentationDetents([.large])
                    .presentationBackground(Color.ui.background)
            }
            .sheet(item: $selectedExpense) { expense in
                ExpenseDetailView(expense: expense)
                    .presentationDetents([.medium])
                    .presentationBackground(Color.ui.background)
            }
            .toolbar {
                SageToolbar(
                    onPrevious: {
                        selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth)!
                    },
                    onNext: {
                        selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth)!
                    },
                    onAdd: { addExpenseSheetIsPresented = true }
                )
            }
            .gradientBackground()
        }
    }
    
    var monthlyOverview: some View {
        Section {
            TotalSpentProgressView(wantsSpent: spent(for: .wants), needsSpent: spent(for: .needs), savingsSpent: spent(for: .savings), totalIncome: Double(config.totalMonthlyIncome))
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
        }
        .listRowBackground(Color.clear)
    }
    
    var utilizationSection: some View {
        Section {
            ForEach(ExpenseCategory.allCases, id: \.self) { category in
                NavigationLink(value: HomeRouter.Route.categoryDetail(category: category)) {
                    CategoryUtilizationView(
                        for: category,
                        utilization(for: category),
                        spent(for: category),
                        budget(for: category),
                    )
                }
                .tint(.primary)
                .listRowBackground(category.color.opacity(0.1))
                .listRowSeparator(.hidden)
            }
        } header: {
            Text("Categories")
        }
    }
    
    var recentExpensesList: some View {
        Section {
            if (recentPurchases.isEmpty) {
                ContentUnavailableView(
                    "No expenses",
                    systemImage: "dollarsign",
                    description: Text("Add expenses to start tracking")
                )
            } else {
                ExpenseList(expenses: recentPurchases, selectedExpense: $selectedExpense)
            }
        } header: {
            Text("Recent Expenses")
        }
    }
}

#Preview {
    @Previewable @State var config = AppConfiguration()
    HomeView(router: HomeRouter())
        .modelContainer(ModelContainer.preview)
        .environment(config)
}

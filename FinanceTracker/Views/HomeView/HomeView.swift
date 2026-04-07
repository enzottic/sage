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
    
    let calendar = Calendar.current
    
    init(router: HomeRouter) {
        self.router = router
    }
    
    var monthlyExpenses: [Expense] {
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)?.start ?? selectedMonth
        let endOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)?.end ?? selectedMonth
        
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
    
    var currentMonthPartialTotal: Double {
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)!.start
        return allExpenses.filter {
            $0.date >= startOfMonth && $0.date <= now
        }.total
    }
    
    var lastMonthPartialTotal: Double {
        let now = Date()
        let dayOfMonth = calendar.component(.day, from: now)
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: now)!
        let startOfLastMonth = calendar.dateInterval(of: .month, for: lastMonth)!.start
        let endOfLastMonth = calendar.dateInterval(of: .month, for: lastMonth)!.end
        
        var components = calendar.dateComponents([.year, .month], from: lastMonth)
        components.day = dayOfMonth
        let cutoffDate = calendar.date(from: components) ?? endOfLastMonth
        
        return allExpenses.filter {
            $0.date >= startOfLastMonth && $0.date <= cutoffDate
        }.total
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
    
    private var percentageChange: Double {
        guard lastMonthPartialTotal > 0 else { return 0 }
        return ((currentMonthPartialTotal - lastMonthPartialTotal) / lastMonthPartialTotal) * 100
    }
    
    private var isSpendingMore: Bool { percentageChange > 0 }
    
    var monthlyOverview: some View {
        Section {
            VStack(spacing: 20) {
                TotalSpentProgressView(wantsSpent: spent(for: .wants), needsSpent: spent(for: .needs), savingsSpent: spent(for: .savings), totalIncome: Double(config.totalMonthlyIncome))
                
                if lastMonthPartialTotal > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: isSpendingMore ? "arrow.up.right" : "arrow.down.right")
                            .foregroundStyle(isSpendingMore ? .red : .green)
                        
                        Text("\(abs(percentageChange), specifier: "%.0f")%")
                        
                        Text("from last month")
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(isSpendingMore ? Color.red.tertiary : Color.green.tertiary)
                    .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
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
    
    var _ = UserDefaults.standard.set(7300, forKey:"totalMonthlyIncome")
    
    HomeView(router: HomeRouter())
        .modelContainer(previewAppContainer)
        .environment(config)
}

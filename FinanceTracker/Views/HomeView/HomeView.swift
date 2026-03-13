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
    
    @State private var path = NavigationPath()
    @State private var selectedMonth: Date = .now
    @State private var selectedExpense: Expense? = nil
    @State private var addExpenseSheetIsPresented: Bool = false
    @State private var showingUtilization: Bool = true
    
    var monthlyExpenses: [Expense] {
        let startOfMonth = Calendar.current.dateInterval(of: .month, for: selectedMonth)?.start ?? selectedMonth
        let endOfMonth = Calendar.current.dateInterval(of: .month, for: selectedMonth)?.end ?? selectedMonth
        
        return allExpenses.filter { expense in
            expense.date >= startOfMonth && expense.date < endOfMonth
        }
    }
    
    var wantsUtilization: Double {
        config.wantsBudget == 0 ? 0 : monthlyExpenses.wantsUsed / config.wantsBudget
    }
    
    var needsUtilization: Double {
        config.needsBudget == 0 ? 0 : monthlyExpenses.needsUsed / config.needsBudget
    }
    
    var savingsUtilization: Double {
        config.savingsBudget == 0 ? 0 : monthlyExpenses.savingsUsed / config.savingsBudget
    }

    var recentPurchases: [Expense] {
        Array(monthlyExpenses.prefix(10))
    }
    
    var totalRemaining: Double {
        Double(config.totalMonthlyIncome) - monthlyExpenses.total
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            List {
                monthlyOverview
                utilizationSection
                recentExpensesList
            }
            .navigationTitle("Home")
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
        }
        .gradientBackground()
    }
    
    var monthlyOverview: some View {
        Section {
            VStack(alignment: .leading, spacing: 15) {
                Text("\(selectedMonth.formatted(.dateTime.month(.wide).year()))")
                    .foregroundStyle(.secondary)
                    .font(.title)
                
                HStack(alignment: .firstTextBaseline) {
                    if showingUtilization {
                        Text(monthlyExpenses.total.currencyString)
                           .font(.largeTitle)
                           .fontWeight(.black)
                           .fontWidth(.expanded)
                        
                        Text(" spent")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(totalRemaining.currencyString)
                           .font(.largeTitle)
                           .fontWeight(.black)
                           .fontWidth(.expanded)
                        
                        Text("remaining")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    var utilizationSection: some View {
        Section {
            NavigationLink {
                Text(ExpenseCategory.wants.rawValue)
            } label: {
                CategoryUtilizationView(for: .wants, wantsUtilization, monthlyExpenses.wantsUsed, config.wantsBudget)
            }
            
            CategoryUtilizationView(for: .needs,  needsUtilization, monthlyExpenses.needsUsed, config.needsBudget)
            CategoryUtilizationView(for: .savings, savingsUtilization, monthlyExpenses.savingsUsed, config.savingsBudget)
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
    HomeView()
        .modelContainer(ModelContainer.preview)
        .environment(config)
}

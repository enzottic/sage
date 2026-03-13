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
    
    let calendar = Calendar.current
    
    @Query(sort: [SortDescriptor(\Expense.date, order: .reverse)])
    private var allExpenses: [Expense]
    
    @State private var selectedMonth: Date = .now
    @State private var selectedExpense: Expense? = nil
    @State private var addExpenseSheetIsPresented: Bool = false
    @State private var showingDeleteConfirmation: Bool = false
    @State private var expenseToDelete: Expense? = nil
    @State private var showingUtilization: Bool = true
    
    var monthlyExpenses: [Expense] {
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)?.start ?? selectedMonth
        let endOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)?.end ?? selectedMonth
        
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
        NavigationStack {
            List {
                Group {
                    monthlyOverview
                    utilizationSection
                }
                .onTapGesture { showingUtilization.toggle() }
                
                expensesList
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
                        selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth)!
                    },
                    onNext: {
                        selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth)!
                    },
                    onAdd: { addExpenseSheetIsPresented = true }
                )
            }
          
        }
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
                        
                        Text("spent")
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
            utilizationView(for: .wants, utilization: wantsUtilization, used: monthlyExpenses.wantsUsed, total: config.wantsBudget)
            utilizationView(for: .needs, utilization: needsUtilization, used: monthlyExpenses.needsUsed, total: config.needsBudget)
            utilizationView(for: .savings, utilization: savingsUtilization, used: monthlyExpenses.savingsUsed, total: config.savingsBudget)
        } header: {
            Text("Categories")
        }
    }
    
    var expensesList: some View {
        Section {
            if (recentPurchases.isEmpty) {
                ContentUnavailableView(
                    "No expenses",
                    systemImage: "dollarsign",
                    description: Text("Add expenses to start tracking")
                )
            } else {
                ExpenseListGroup(expenses: recentPurchases, selectedExpense: $selectedExpense)
            }
        } header: {
            Text("Recent Purchases")
        }
    }
    
    private func utilizationView(for category: ExpenseCategory, utilization: Double, used: Double, total: Double) -> some View {
        HStack(spacing: 10) {
            CircularProgressView(progress: utilization, tint: category.color)
            
            VStack(alignment: .leading) {
                Text(category.rawValue)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if showingUtilization {
                    HStack(spacing: 5) {
                        Text(used.currencyString)
                            .fontWeight(.semibold)
                        Text("of \(total.currencyString)")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    let remaining = total - used
                    Text("\(remaining.currencyString) remaining")
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var config = AppConfiguration()
    HomeView()
        .modelContainer(ModelContainer.preview)
        .environment(config)
}

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
    let dataService = ExpenseDataService()
    
    @Query private var monthlyExpenses: [Expense]
    
    @State private var selectedExpense: Expense? = nil
    
    @State private var addExpenseSheetIsPresented: Bool = false
    @State private var showingDeleteConfirmation: Bool = false
    @State private var expenseToDelete: Expense? = nil
    
    @AppStorage("totalMonthlyIncome", store: UserDefaults(suiteName: "group.me.enzottic.SageAppGroup")) private var totalMonthlyIncome: Int = 4300
    @AppStorage("needsPercent", store: UserDefaults(suiteName: "group.me.enzottic.SageAppGroup")) private var needsPercent: Double = 0.5
    @AppStorage("wantsPercent", store: UserDefaults(suiteName: "group.me.enzottic.SageAppGroup")) private var wantsPercent : Double = 0.3
    @AppStorage("savingsPercent", store: UserDefaults(suiteName: "group.me.enzottic.SageAppGroup")) private var savingsPercent: Double = 0.2

    var wantsTotal: Double {
        Double(totalMonthlyIncome) * wantsPercent
    }
    
    var wantsUtilization: Double {
        wantsTotal == 0 ? 0 : monthlyExpenses.wantsUsed / wantsTotal
    }
    
    var needsTotal: Double {
        Double(totalMonthlyIncome) * needsPercent
    }
    
    var needsUtilization: Double {
        needsTotal == 0 ? 0 : monthlyExpenses.needsUsed / needsTotal
    }
    
    var savingsTotal: Double {
        Double(totalMonthlyIncome) * savingsPercent
    }
    
    var savingsUtilization: Double {
        savingsTotal == 0 ? 0 : monthlyExpenses.savingsUsed / savingsTotal
    }

    var recentPurchases: [Expense] {
        Array(monthlyExpenses.prefix(10))
    }
    
    init() {
        let calendar = Calendar.current
        let month = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: month)?.start ?? month
        let endOfMonth = calendar.dateInterval(of: .month, for: month)?.end ?? month
        
        _monthlyExpenses = Query(
            filter: #Predicate<Expense> { expense in
                expense.date >= startOfMonth && expense.date < endOfMonth
            },
            sort: [SortDescriptor(\Expense.date, order: .reverse)],
        )
    }
    
    var body: some View {
        NavigationStack {
            List {
                monthlyOverview
                expensesList
            }
            .navigationTitle("Home")
            .scrollContentBackground(.hidden)
            .background(Color.ui.background)
            .sheet(isPresented: $addExpenseSheetIsPresented) {
                AddExpenseSheet()
            }
            .sheet(item: $selectedExpense) { expense in
                ExpenseDetailView(expense: expense)
                    .presentationDetents([.medium])
            }
            .toolbar {
                ToolbarItem {
                    Button {
                        addExpenseSheetIsPresented = true
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                    .background(Color.ui.cardBackground)
                    .tint(Color.ui.sageColor)
                }
            }
          
        }
    }
    
    var monthlyOverview: some View {
        Section {
            VStack(spacing: 15) {
                Text("Spent in \(Date().formatted(.dateTime.month(.wide)))")
                    .foregroundStyle(.secondary)
                 Text(monthlyExpenses.total.currencyString)
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .fontWidth(.expanded)
                
                utilizationView(for: .wants, utilization: wantsUtilization, used: monthlyExpenses.wantsUsed, total: wantsTotal)
                utilizationView(for: .needs, utilization: needsUtilization, used: monthlyExpenses.needsUsed, total: needsTotal)
                utilizationView(for: .savings, utilization: savingsUtilization, used: monthlyExpenses.savingsUsed, total: savingsTotal)
            }
        } header: {
            Text("Monthly Overview")
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
        VStack(spacing: 0) {
            HStack {
                Text(category.rawValue.uppercased())
                Text(utilization, format: .percent.precision(.fractionLength(0)))
            }
            .font(.caption)
            .fontWidth(.expanded)
            .foregroundStyle(.secondary)
            
            HStack {
                Text(used.currencyString)
                ProgressView(value: utilization, total: 1)
                    .overlay(
                        LinearGradient(gradient: Gradient(colors: [category.color]), startPoint: .leading, endPoint: .trailing)
                        .mask(ProgressView(value: utilization, total: 1))
                      )
                Text(total.currencyString)
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(ModelContainer.preview)
}

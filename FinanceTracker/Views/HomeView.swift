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
    
    @Query private var monthlyExpenses: [Expense]
    
    @State private var selectedExpense: Expense? = nil
    @State private var addExpenseSheetIsPresented: Bool = false
    @State private var showingDeleteConfirmation: Bool = false
    @State private var expenseToDelete: Expense? = nil
    @State private var showingUtilization: Bool = true
    
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
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            showingUtilization.toggle()
                        }
                    }
                expensesList
            }
            .navigationTitle("Home")
            .scrollContentBackground(.hidden)
            .background(Color.ui.background)
            .sheet(isPresented: $addExpenseSheetIsPresented) {
                AddExpenseSheet()
                    .presentationDetents([.medium])
                    .presentationBackground(Color.ui.background)
            }
            .sheet(item: $selectedExpense) { expense in
                ExpenseDetailView(expense: expense)
                    .presentationDetents([.medium])
                    .presentationBackground(Color.ui.background)
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
                
                utilizationView(for: .wants, utilization: wantsUtilization, used: monthlyExpenses.wantsUsed, total: config.wantsBudget)
                utilizationView(for: .needs, utilization: needsUtilization, used: monthlyExpenses.needsUsed, total: config.needsBudget)
                utilizationView(for: .savings, utilization: savingsUtilization, used: monthlyExpenses.savingsUsed, total: config.savingsBudget)
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
                if showingUtilization {
                    Text(category.rawValue.uppercased())
                    Text(utilization, format: .percent.precision(.fractionLength(0)))
                } else {
                    Text((total - used).currencyString)
                    Text("REMAINING")
                }
            }
            .font(.caption)
            .fontWidth(.expanded)
            .foregroundStyle(.secondary)
            
            HStack {
                Text(used.currencyString)
                    .foregroundStyle(used > total ? .red : .secondary)
                ProgressView(value: utilization, total: 1)
                    .overlay(
                        LinearGradient(gradient: Gradient(colors: [category.color]), startPoint: .leading, endPoint: .trailing)
                        .mask(ProgressView(value: utilization, total: 1))
                      )
                Text(total.currencyString)
                    .foregroundStyle(used > total ? .red : .secondary)
            }
            .font(.subheadline)
        }
    }
}

#Preview {
    @Previewable @State var config = AppConfiguration()
    HomeView()
        .modelContainer(ModelContainer.preview)
        .environment(config)
}

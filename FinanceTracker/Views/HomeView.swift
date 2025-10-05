//
//  ExpensesView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 9/21/25.
//

import SwiftUI
import SwiftData
import FoundationModels

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var allExpensesThisMonth: [Expense]
    
    @State private var addExpenseSheetIsPresented: Bool = false
    @State private var showingDeleteConfirmation: Bool = false
    @State private var expenseToDelete: Expense? = nil
    
    @AppStorage("totalMonthlyIncome") private var totalMonthlyIncome: Int = 7300
    @AppStorage("needsPercent") private var needsPercent: Double = 0.5
    @AppStorage("wantsPercent") private var wantsPercent : Double = 0.3
    @AppStorage("savingsPercent") private var savingsPercent: Double = 0.2
    
    var totalSpentThisMonth: Double {
        allExpensesThisMonth.reduce(0) { $0 + $1.amount }
    }
    
    
    var totalSpendableIncome: Double {
        Double(totalMonthlyIncome) - (Double(totalMonthlyIncome) * savingsPercent)
    }
    
    var wantsTotal: Double {
        Double(totalMonthlyIncome) * wantsPercent
    }
    
    var wantsUsed: Double {
        allExpensesThisMonth
            .filter { $0.category == .wants }
            .reduce(0) { $0 + $1.amount }
    }
    
    var wantsUtilization: Double {
        wantsTotal == 0 ? 0 : wantsUsed / wantsTotal
    }
    
    var needsTotal: Double {
        Double(totalMonthlyIncome) * needsPercent
    }
    
    var needsUsed: Double {
        allExpensesThisMonth
            .filter { $0.category == .needs}
            .reduce(0) { $0 + $1.amount }
    }
    
    var needsUtilization: Double {
        needsTotal == 0 ? 0 : needsUsed / needsTotal
    }
    
    var recentPurchases: [Expense] {
        Array(allExpensesThisMonth.prefix(10))
    }

    init() {
        let calendar = Calendar.current
        let month = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: month)?.start ?? month
        let endOfMonth = calendar.dateInterval(of: .month, for: month)?.end ?? month
        
        _allExpensesThisMonth = Query(
            filter: #Predicate<Expense> { expense in
                expense.date >= startOfMonth && expense.date < endOfMonth
            },
            sort: [SortDescriptor(\Expense.date, order: .reverse)],
        )
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section(header: Text("Monthly Overview")) {
                        HStack(alignment: .center) {
                            Text(totalSpentThisMonth.formatted(.currency(code: "USD")))
                                .font(.largeTitle)
                            Text("/")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text(totalSpendableIncome.currencyString)
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            utilizationView("Wants", utilization: wantsUtilization, used: wantsUsed, total: wantsTotal)
                            Divider()
                            utilizationView("Needs", utilization: needsUtilization, used: needsUsed, total: needsTotal)
                        }
                    }
                    
                    Section(header: Text("Recent Purchases")) {
                        if (recentPurchases.isEmpty) {
                            ContentUnavailableView(
                                "No expenses",
                                systemImage: "dollarsign",
                                description: Text("Add expenses to start tracking")
                            )
                        } else {
                            ExpenseListGroup(expenses: recentPurchases)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem {
                    Button {
                        addExpenseSheetIsPresented = true
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $addExpenseSheetIsPresented) {
                AddExpenseSheet()
            }
            .alert("Delete Expense?", isPresented: $showingDeleteConfirmation, actions: {
                Button("Delete", role: .destructive) {
                    if let expense = expenseToDelete {
                        modelContext.delete(expense)
                    }
                }
                
                Button("Cancel", role: .cancel) {
                    expenseToDelete = nil
                }
            })
            .navigationTitle("Home")
        }
    }
     
    private func utilizationView(_ title: String, utilization: Double, used: Double, total: Double) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
            HStack(alignment: .center) {
                ProgressView(value: utilization)
                    .tint(title == "Wants" ? .green : .red)
                Text(utilization, format: .percent.precision(.fractionLength(0)))
            }
            Text("\(used.currencyString)/\(total.currencyString)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private func deleteExpense(at indexSet: IndexSet) {
        // ask for confirmation
        for index in indexSet {
            modelContext.delete(recentPurchases[index])
        }
    }
}


#Preview {
    HomeView()
        .modelContainer(ModelContainer.preview)
}

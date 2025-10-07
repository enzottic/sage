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
    
    @AppStorage("totalMonthlyIncome", store: UserDefaults(suiteName: "group.me.enzottic.SageAppGroup")) private var totalMonthlyIncome: Int = 4300
    @AppStorage("needsPercent", store: UserDefaults(suiteName: "group.me.enzottic.SageAppGroup")) private var needsPercent: Double = 0.5
    @AppStorage("wantsPercent", store: UserDefaults(suiteName: "group.me.enzottic.SageAppGroup")) private var wantsPercent : Double = 0.3
    @AppStorage("savingsPercent", store: UserDefaults(suiteName: "group.me.enzottic.SageAppGroup")) private var savingsPercent: Double = 0.2

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
            List {
                VStack(spacing: 10) {
                    Section {
                        VStack(spacing: 15) {
                            VStack {
                                Text(totalSpentThisMonth.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))
                                    .font(.largeTitle)
                                
                                Text("of \(totalMonthlyIncome.currencyString)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            VStack(spacing: 15) {
                                utilizationView(for: .wants, utilization: wantsUtilization, used: wantsUsed, total: wantsTotal)
                                utilizationView(for: .needs, utilization: needsUtilization, used: needsUsed, total: needsTotal)
                            }
                        }
                    } header: {
                        Text("This Month")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section {
                    if (recentPurchases.isEmpty) {
                        ContentUnavailableView(
                            "No expenses",
                            systemImage: "dollarsign",
                            description: Text("Add expenses to start tracking")
                        )
                    } else {
                        ExpenseListGroup(expenses: recentPurchases)
                    }
                } header: {
                    Text("Recent Purchases")
                        .foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.ui.background)
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
     
    private func utilizationView(for category: ExpenseCategory, utilization: Double, used: Double, total: Double) -> some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Text(category.rawValue)
                    .font(.subheadline)
                Spacer()
                VStack(alignment: .trailing) {
                    Text(used.currencyString)
                        .font(.subheadline)
                    Text("of \(total.currencyString)")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            HStack(alignment: .center) {
                ProgressView(value: utilization)
                    .tint(category.color)
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                Text(utilization, format: .percent.precision(.fractionLength(0)))
            }
        }
        .padding([.horizontal])
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

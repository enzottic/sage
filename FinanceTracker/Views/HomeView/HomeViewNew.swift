//
//  HomeViewNew.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 5/24/26.
//

import SwiftUI
import SwiftData
import WidgetKit
import Charts
import SageKit

struct HomeViewNew: View {
    @Environment(AppConfiguration.self) private var config
    @Environment(SplitwiseService.self) private var splitwiseService
    @Environment(AppRouter.self) private var appRouter
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\Expense.date, order: .reverse)])
    private var allExpenses: [Expense]

    @State private var selectedMonth: Date = .now
    @State private var showSplitwiseImport: Bool = false
    @State private var expenseToDelete: Expense? = nil
    @State private var showingDeleteConfirmation: Bool = false

    let calendar = Calendar.current

    // Estimated heights for the non-scrolling List frame calculation.
    // Adjust if row or header content changes significantly.
    private let listRowHeight: CGFloat = 60
    private let listHeaderHeight: CGFloat = 44

    var monthlyExpenses: [Expense] {
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)?.start ?? selectedMonth
        let endOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)?.end ?? selectedMonth
        return allExpenses.filter { $0.date >= startOfMonth && $0.date < endOfMonth }
    }

    var recentPurchases: [Expense] {
        Array(monthlyExpenses.prefix(10))
    }

    var recentExpensesByDay: [(day: Date, expenses: [Expense])] {
        let grouped = Dictionary(grouping: recentPurchases) {
            calendar.startOfDay(for: $0.date)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { (day: $0.key, expenses: $0.value) }
    }

    var estimatedRecentListHeight: CGFloat {
        CGFloat(recentExpensesByDay.count) * listHeaderHeight
            + CGFloat(recentPurchases.count) * listRowHeight
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
        NavigationStack(path: Bindable(appRouter.homeRouter).navigationPath) {
            ScrollView {
                LazyVStack(spacing: 20) {
                    monthlyOverview
                    categoryUtilization
                    recentExpensesList
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .navigationDestination(for: HomeRouter.Route.self) { route in
                switch route {
                case .categoryDetail(let category):
                    CategoryDetailView(category: category, utilization: utilization(for: category), used: spent(for: category), total: budget(for: category))
                case .addExpense:
                    AddExpenseView()
                }
            }
            .navigationDestination(for: Expense.self) { expense in
                ExpenseDetailView(expense: expense)
            }
            .navigationTitle(selectedMonth.formatted(.dateTime.month(.wide).year()))
            .background(.background)
            .sheet(isPresented: $showSplitwiseImport) {
                SplitwiseImportView()
            }
            .toolbar {
                SageToolbar(
                    onPrevious: {
                        selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth)!
                    },
                    onNext: {
                        selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth)!
                    },
                    onAdd: { appRouter.homeRouter.navigateTo(route: .addExpense) },
                    onImportFromSplitwise: splitwiseService.isConfigured
                        ? { showSplitwiseImport = true }
                        : nil,
                )
            }
            .gradientBackground()
        }
    }

    // MARK: - Monthly Overview

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

    var currentMonthPartialTotal: Double {
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)!.start
        return allExpenses.filter {
            $0.date >= startOfMonth && $0.date <= now
        }.total
    }

    private var percentageChange: Double {
        guard lastMonthPartialTotal > 0 else { return 0 }
        return ((currentMonthPartialTotal - lastMonthPartialTotal) / lastMonthPartialTotal) * 100
    }

    private var isSpendingMore: Bool { percentageChange > 0 }

    var monthlyOverview: some View {
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
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.cardBackground)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }

    // MARK: - Category Utilization

    var categoryUtilization: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CATEGORIES")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .tracking(0.6)
                .padding(.horizontal, 4)

            CardRowList(
                items: ExpenseCategory.allCases,
                navigationValue: { HomeRouter.Route.categoryDetail(category: $0) }
            ) { category in
                CategoryUtilizationView(
                    for: category,
                    utilization(for: category),
                    spent(for: category),
                    budget(for: category),
                )
            }
        }
    }

    // MARK: - Recent Expenses List

    var recentExpensesList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("RECENT EXPENSES")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .tracking(0.6)
                .padding(.horizontal, 4)

            if recentPurchases.isEmpty {
                ContentUnavailableView(
                    "No expenses",
                    systemImage: "dollarsign",
                    description: Text("Add expenses to start tracking")
                )
            } else {
                List {
                    ForEach(recentExpensesByDay, id: \.day) { group in
                        Section {
                            ForEach(group.expenses) { expense in
                                NavigationLink(value: expense) {
                                    ExpenseRowItem(expense: expense)
                                }
                                .tint(.primary)
                                .swipeActions {
                                    Button("Delete") {
                                        expenseToDelete = expense
                                        showingDeleteConfirmation = true
                                    }
                                    .tint(.red)
                                }
                            }
                        } header: {
                            HStack {
                                Text(group.day.relative())
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text(group.expenses.total.currencyString)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .textCase(nil)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollDisabled(true)
                .scrollContentBackground(.hidden)
                .background(.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                .frame(height: estimatedRecentListHeight)
                .alert("Delete Expense?", isPresented: $showingDeleteConfirmation) {
                    Button("Delete", role: .destructive) {
                        if let expense = expenseToDelete { deleteExpense(expense) }
                    }
                    Button("Cancel", role: .cancel) { expenseToDelete = nil }
                }
            }
        }
    }

    private func deleteExpense(_ expense: Expense) {
        withAnimation {
            modelContext.delete(expense)
            try! modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
            appRouter.showToast(SageToast(message: "Expense deleted", kind: .success))
        }
    }
}

#Preview {
    HomeViewNew()
        .environmentInjection()
}

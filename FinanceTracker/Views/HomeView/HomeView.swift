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
    @Environment(AppConfiguration.self) private var config
    @Environment(SplitwiseService.self) private var splitwiseService
    @Environment(AppRouter.self) private var appRouter

    @Query(sort: [SortDescriptor(\Expense.date, order: .reverse)])
    private var allExpenses: [Expense]

    @Query private var recurringRules: [RecurringExpenseRule]

    private var upcomingRules: [RecurringExpenseRule] {
        recurringRules
            .compactMap { rule -> (rule: RecurringExpenseRule, next: Date)? in
                guard let next = nextOccurrence(for: rule) else { return nil }
                return (rule, next)
            }
            .sorted { $0.next < $1.next }
            .prefix(5)
            .map { $0.rule }
    }

    private func nextOccurrence(for rule: RecurringExpenseRule) -> Date? {
        let calendar = Calendar.current
        let after = rule.lastGeneratedDate ?? rule.startDate
        let next: Date?
        switch rule.frequency {
        case .daily:    next = calendar.date(byAdding: .day, value: 1, to: after)
        case .weekly:   next = calendar.date(byAdding: .weekOfYear, value: 1, to: after)
        case .biweekly: next = calendar.date(byAdding: .weekOfYear, value: 2, to: after)
        case .monthly:  next = calendar.date(byAdding: .month, value: 1, to: after)
        }
        if let next, let endDate = rule.endDate, next > endDate { return nil }
        return next
    }

    @State private var selectedMonth: Date = .now
    @State private var showSplitwiseImport: Bool = false

    let calendar = Calendar.current

    var monthlyExpenses: [Expense] {
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)?.start ?? selectedMonth
        let endOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)?.end ?? selectedMonth

        return allExpenses.filter { expense in
            expense.date >= startOfMonth && expense.date < endOfMonth
        }
    }

    var recentExpensesByDay: [(day: Date, expenses: [Expense])] {
        let grouped = Dictionary(grouping: monthlyExpenses) {
            calendar.startOfDay(for: $0.date)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .prefix(7)
            .map { (day: $0.key, expenses: $0.value) }
    }

    var recentPurchases: [Expense] {
        recentExpensesByDay.flatMap { $0.expenses }
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
        NavigationStack(path: Bindable(appRouter.homeRouter).navigationPath) {
            List {
                monthlyOverview
                categoryUtilization
                upcomingRecurringSection
                recentExpensesList
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
            .scrollContentBackground(.hidden)
            .background(Color.ui.background)
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
        Section {
            TotalSpentProgressView(wantsSpent: spent(for: .wants), needsSpent: spent(for: .needs), savingsSpent: spent(for: .savings), totalIncome: Double(config.totalMonthlyIncome))
        } footer: {
            if lastMonthPartialTotal > 0 {
                HStack(spacing: 4) {
                    Image(systemName: isSpendingMore ? "arrow.up.right" : "arrow.down.right")
                        .foregroundStyle(isSpendingMore ? .red : .green)
                    Text("\(abs(percentageChange), specifier: "%.0f")%")
                    Text("from last month")
                }
                .foregroundStyle(isSpendingMore ? Color.red : Color.green)
            }
        }
    }

    // MARK: - Category Utilization

    var categoryUtilization: some View {
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
                .listRowSeparator(.hidden)
            }
        } header: {
            Text("Categories")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }

    // MARK: - Upcoming Recurring

    @ViewBuilder
    var upcomingRecurringSection: some View {
        if !upcomingRules.isEmpty {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(upcomingRules) { rule in
                            if let next = nextOccurrence(for: rule) {
                                UpcomingRecurringCard(rule: rule, nextDate: next)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } header: {
                Text("Upcoming Expenses")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
    }

    // MARK: - Recent Expenses List

    @ViewBuilder
    var recentExpensesList: some View {
        if !recentPurchases.isEmpty {
            Section {
            } footer: {
                HStack(alignment: .firstTextBaseline) {
                    Text("Recent Expenses")
                    Spacer()
                    Button("Show All") {
                        appRouter.expensesMonth = selectedMonth
                        appRouter.selectedTab = .expenses
                    }
                }
                .font(.subheadline)
                .fontWeight(.semibold)
            }

            ForEach(recentExpensesByDay, id: \.day) { group in
                Section {
                    ExpenseList(expenses: group.expenses)
                } header: {
                    HStack {
                        Text(group.day.relative())
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(group.expenses.total.currencyString)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

private struct UpcomingRecurringCard: View {
    @Environment(\.categoryColors) private var categoryColors
    let rule: RecurringExpenseRule
    let nextDate: Date

    private var daysAway: Int {
        max(0, Calendar.current.dateComponents([.day], from: .now, to: nextDate).day ?? 0)
    }

    private var isImminent: Bool { daysAway <= 3 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let emoji = rule.tag?.emoji {
                    Text(emoji)
                        .font(.title2)
                }
                Spacer()
                Text(daysAway == 0 ? "today" : daysAway == 1 ? "1 day" : "\(daysAway)d")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(isImminent ? .white : .secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(isImminent ? Color.orange : Color.secondary.opacity(0.15))
                    .clipShape(Capsule())
            }

            Text(rule.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)

            Text(rule.amount.currencyStringWithFraction)
                .font(.headline)
                .fontWeight(.bold)
        }
        .padding(14)
        .frame(width: 150)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    HomeView()
        .environmentInjection()
}

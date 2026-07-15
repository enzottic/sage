//
//  MonthlyOverviewWidget.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 7/12/26.
//
import SwiftUI
import SwiftData
import SageKit

struct MonthlyOverviewWidget: View {
    @Environment(AppConfiguration.self) private var config
    
    private let calendar = Calendar.current
    private let selectedMonth: Date

    @Query var monthlyExpenses: [Expense]
    @Query var comparisonExpenses: [Expense]

    /// True when the selected month is the month containing "today" — only
    /// then does it make sense to compare partial (month-to-date) totals.
    /// For a fully elapsed past month, both months are compared in full.
    private var isCurrentMonth: Bool {
        calendar.isDate(selectedMonth, equalTo: .now, toGranularity: .month)
    }

    var lastMonthPartialTotal: Double {
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth)!
        let startOfLastMonth = calendar.dateInterval(of: .month, for: lastMonth)!.start
        let endOfLastMonth = calendar.dateInterval(of: .month, for: lastMonth)!.end

        let cutoffDate: Date
        if isCurrentMonth {
            let dayOfMonth = calendar.component(.day, from: .now)
            var components = calendar.dateComponents([.year, .month], from: lastMonth)
            components.day = dayOfMonth
            cutoffDate = calendar.date(from: components) ?? endOfLastMonth
        } else {
            cutoffDate = endOfLastMonth
        }

        return comparisonExpenses.filter {
            $0.date >= startOfLastMonth && $0.date <= cutoffDate
        }.total
    }

    var currentMonthPartialTotal: Double {
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)!.start
        let cutoffDate = isCurrentMonth ? Date() : calendar.dateInterval(of: .month, for: selectedMonth)!.end
        return comparisonExpenses.filter {
            $0.date >= startOfMonth && $0.date <= cutoffDate
        }.total
    }

    private var percentageChange: Double {
        guard lastMonthPartialTotal > 0 else { return 0 }
        return ((currentMonthPartialTotal - lastMonthPartialTotal) / lastMonthPartialTotal) * 100
    }
    
    private var isSpendingMore: Bool { percentageChange > 0 }

    func utilization(for category: ExpenseCategory) -> Double {
        switch category {
        case .wants: config.wantsBudget == 0 ? 0 : monthlyExpenses.wantsUsed / config.wantsBudget
        case .needs: config.needsBudget == 0 ? 0 : monthlyExpenses.needsUsed / config.needsBudget
        case .savings: config.savingsBudget == 0 ? 0 : monthlyExpenses.savingsUsed / config.savingsBudget
        @unknown default: fatalError("Unknown expense category")
        }
    }

    func spent(for category: ExpenseCategory) -> Double {
        switch category {
        case .wants: monthlyExpenses.wantsUsed
        case .needs: monthlyExpenses.needsUsed
        case .savings: monthlyExpenses.savingsUsed
        @unknown default: fatalError("Unknown expense category")
        }
    }

    func budget(for category: ExpenseCategory) -> Double {
        switch category {
        case .wants: config.wantsBudget
        case .needs: config.needsBudget
        case .savings: config.savingsBudget
        @unknown default: fatalError("Unknown expense category")
        }
    }
    
    init(selectedMonth: Date) {
        self.selectedMonth = selectedMonth
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
        let startOfLastMonth = calendar.dateInterval(of: .month, for: lastMonth)?.start ?? lastMonth
        let endOfSelectedMonth = calendar.dateInterval(of: .month, for: selectedMonth)?.end ?? selectedMonth

        _monthlyExpenses = expenseQuery(for: selectedMonth)
        _comparisonExpenses = expenseQuery(start: startOfLastMonth, end: endOfSelectedMonth)
    }
    
    var body: some View {
        Section {
            TotalSpentProgressView(wantsSpent: spent(for: .wants), needsSpent: spent(for: .needs), savingsSpent: spent(for: .savings), totalIncome: Double(config.totalMonthlyIncome))
        } footer: {
            if lastMonthPartialTotal > 0 {
                HStack(spacing: 4) {
                    Image(systemName: isSpendingMore ? "arrow.up.right" : "arrow.down.right")
                        .foregroundStyle(isSpendingMore ? .red : .green)
                    Text(abs(percentageChange) / 100, format: .percent.precision(.fractionLength(0)))
                    Text("from last month")
                }
                .foregroundStyle(isSpendingMore ? Color.red : Color.green)
            }
        }
    }
}

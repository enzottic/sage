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

    @Query var monthlyExpenses: [Expense]
    @Query var comparisonExpenses: [Expense]
    
    var lastMonthPartialTotal: Double {
        let now = Date()
        let dayOfMonth = calendar.component(.day, from: now)
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: now)!
        let startOfLastMonth = calendar.dateInterval(of: .month, for: lastMonth)!.start
        let endOfLastMonth = calendar.dateInterval(of: .month, for: lastMonth)!.end

        var components = calendar.dateComponents([.year, .month], from: lastMonth)
        components.day = dayOfMonth
        let cutoffDate = calendar.date(from: components) ?? endOfLastMonth

        return comparisonExpenses.filter {
            $0.date >= startOfLastMonth && $0.date <= cutoffDate
        }.total
    }

    var currentMonthPartialTotal: Double {
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)!.start
        return comparisonExpenses.filter {
            $0.date >= startOfMonth && $0.date <= now
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
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: .now) ?? .now
        let startOfLastMonth = calendar.dateInterval(of: .month, for: lastMonth)?.start ?? lastMonth
        
        _monthlyExpenses = expenseQuery(for: selectedMonth)
        _comparisonExpenses = expenseQuery(start: startOfLastMonth, end: .now)
    }
    
    var body: some View {
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
}

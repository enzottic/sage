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
    @Environment(\.categoryColors) private var categoryColors

    private let calendar = Calendar.current
    private let selectedMonth: Date

    @Query var monthlyExpenses: [Expense]
    @Query var comparisonExpenses: [Expense]

    private var isCurrentMonth: Bool {
        calendar.isDate(selectedMonth, equalTo: .now, toGranularity: .month)
    }

    var lastMonthPartialTotal: Double {
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
        let startOfLastMonth = calendar.dateInterval(of: .month, for: lastMonth)?.start ?? lastMonth
        let endOfLastMonth = calendar.dateInterval(of: .month, for: lastMonth)?.end ?? lastMonth

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
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)?.start ?? selectedMonth
        let cutoffDate = isCurrentMonth ? Date() : calendar.dateInterval(of: .month, for: selectedMonth)?.end ?? selectedMonth
        return comparisonExpenses.filter {
            $0.date >= startOfMonth && $0.date <= cutoffDate
        }.total
    }

    private var percentageChange: Double {
        guard lastMonthPartialTotal > 0 else { return 0 }
        return ((currentMonthPartialTotal - lastMonthPartialTotal) / lastMonthPartialTotal) * 100
    }
    
    private var isSpendingMore: Bool { percentageChange > 0 }

    private var totalSpent: Double { monthlyExpenses.total }

    private var totalBudget: Double { Double(config.totalMonthlyIncome) }

    private var totalUtilization: Double {
        totalBudget == 0 ? 0 : totalSpent / totalBudget
    }

    private var remaining: Double { max(totalBudget - totalSpent, 0) }

    private var isOverBudget: Bool { totalSpent > totalBudget + 0.001 }

    private var tint: Color { isOverBudget ? .red : .sage }

    private var trendColor: Color { isSpendingMore ? .red : .green }

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
            VStack(spacing: 12) {
                ArcProgressGauge(progress: totalUtilization, tint: tint) {
                    gaugeLabel
                }
                .frame(maxWidth: 420)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)

                Divider()

                HStack {
                    Text(isOverBudget
                         ? "\((totalSpent - totalBudget).currencyString) over"
                         : "\(remaining.currencyString) left")
                        .font(.subheadline)
                        .foregroundStyle(isOverBudget ? .red : .secondary)

                    Spacer()

                    if lastMonthPartialTotal > 0 {
                        trendPill
                    }
                }
            }
        }
    }

    private var gaugeLabel: some View {
        VStack(spacing: 2) {
            Text(totalSpent.currencyString)
                .font(.largeTitle)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text("\(totalUtilization.formatted(.percent.precision(.fractionLength(0)))) of \(totalBudget.currencyString)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private var trendPill: some View {
        HStack(spacing: 4) {
            Image(systemName: isSpendingMore ? "arrow.up.right" : "arrow.down.right")
            Text("\((abs(percentageChange) / 100).formatted(.percent.precision(.fractionLength(0)))) vs last month")
        }
        .font(.caption)
        .fontWeight(.medium)
        .foregroundStyle(trendColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(trendColor.opacity(0.12), in: .capsule)
    }
}

#Preview {
    MonthlyOverviewWidget(selectedMonth: .now)
        .environmentInjection()
}

//
//  StatsView.swift
//  FinanceTracker
//
//  Created on 3/13/26.
//

import SwiftUI
import SwiftData
import Charts

struct MonthlySpendingData: Identifiable {
    let month: Date
    let monthLabel: String
    let total: Double
    let isCurrent: Bool

    var id: String { monthLabel }
}

struct StatsView: View {
    @Query(sort: [SortDescriptor(\Expense.date, order: .reverse)])
    private var allExpenses: [Expense]

    @State private var selectedCategory: ExpenseCategory? = nil
    @State private var selectedTag: ExpenseTag? = nil
    
    private var gradientColor: Color {
        if selectedCategory != nil { return selectedCategory!.color }
        if let tag = selectedTag, !tag.isDeleted { return tag.color }
        
        return .sage
    }

    private let calendar = Calendar.current

    var filteredExpenses: [Expense] {
        allExpenses.filter { expense in
            let matchesCategory = selectedCategory == nil || expense.category == selectedCategory
            let matchesTag = selectedTag == nil || selectedTag?.isDeleted == true || expense.tag?.id == selectedTag?.id
            return matchesCategory && matchesTag
        }
    }

    var chartData: [MonthlySpendingData] {
        let now = Date()
        return (0..<6).reversed().map { monthsAgo in
            let targetMonth = calendar.date(byAdding: .month, value: -monthsAgo, to: now)!
            let interval = calendar.dateInterval(of: .month, for: targetMonth)!
            let monthExpenses = filteredExpenses.filter {
                $0.date >= interval.start && $0.date < interval.end
            }
            let label = targetMonth.formatted(.dateTime.month(.abbreviated))
            return MonthlySpendingData(
                month: interval.start,
                monthLabel: label,
                total: monthExpenses.total,
                isCurrent: monthsAgo == 0
            )
        }
    }

    var currentMonthPartialTotal: Double {
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)!.start
        return filteredExpenses.filter {
            $0.date >= startOfMonth && $0.date <= now
        }.total
    }

    var lastMonthPartialTotal: Double {
        let now = Date()
        let dayOfMonth = calendar.component(.day, from: now)
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: now)!
        let startOfLastMonth = calendar.dateInterval(of: .month, for: lastMonth)!.start
        let endOfLastMonth = calendar.dateInterval(of: .month, for: lastMonth)!.end

        var components = calendar.dateComponents([.year, .month], from: lastMonth)
        components.day = dayOfMonth
        let cutoffDate = calendar.date(from: components) ?? endOfLastMonth

        return filteredExpenses.filter {
            $0.date >= startOfLastMonth && $0.date <= cutoffDate
        }.total
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    StatsFilterBar(
                        selectedCategory: $selectedCategory,
                        selectedTag: $selectedTag
                    )

                    SpendingComparisonCard(
                        currentMonthPartialTotal: currentMonthPartialTotal,
                        lastMonthPartialTotal: lastMonthPartialTotal
                    )
                    .padding(.horizontal)

                    spendingChart
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.ui.background)
            .navigationTitle("Stats")
            .gradientBackground(color: gradientColor)
        }
    }

    private var barColor: Color {
        if let category = selectedCategory {
            return category.color
        } else if let tag = selectedTag, !tag.isDeleted {
            return tag.color
        } else {
            return Color.ui.sageColor
        }
    }

    private var spendingChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Monthly Spending")
                .font(.headline)

            Chart(chartData) { item in
                BarMark(
                    x: .value("Month", item.monthLabel),
                    y: .value("Spending", item.total)
                )
                .foregroundStyle(item.isCurrent ? barColor : barColor.opacity(0.5))
                .cornerRadius(4)
                .annotation(position: .top, spacing: 4) {
                    if item.total > 0 {
                        Text(item.total.currencyString)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text(doubleValue.currencyString)
                                .font(.caption2)
                        }
                    }
                    AxisGridLine()
                }
            }
            .animation(.easeInOut, value: chartData.map(\.total))
            .frame(height: 220)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 15).fill(Color.ui.cardBackground))
    }
}

#Preview {
    @Previewable @State var config = AppConfiguration()
    StatsView()
        .modelContainer(previewAppContainer)
        .environment(config)
}

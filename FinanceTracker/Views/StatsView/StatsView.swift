//
//  StatsView.swift
//  FinanceTracker
//
//  Created on 3/13/26.
//

import SwiftUI
import SwiftData
import Charts
import SageKit

enum StatsTimeframe: String, CaseIterable, Identifiable {
    case monthly = "Monthly"
    case weekly = "Weekly"

    var id: String { rawValue }

    var calendarComponent: Calendar.Component {
        switch self {
        case .monthly: .month
        case .weekly: .weekOfYear
        }
    }
}

struct SpendingPeriodData: Identifiable {
    let periodStart: Date
    let label: String
    let total: Double
    let isCurrent: Bool

    var id: Date { periodStart }
}

struct StatsView: View {
    @Environment(\.categoryColors) private var categoryColors
    @Environment(AppConfiguration.self) private var config
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: [SortDescriptor(\Expense.date, order: .reverse)])
    private var allExpenses: [Expense]
    @Query private var recurringRules: [RecurringExpenseRule]

    @State private var timeframe: StatsTimeframe = .monthly
    @State private var selectedCategory: ExpenseCategory? = nil
    @State private var selectedTag: ExpenseTag? = nil

    private let calendar = Calendar.current
    private let periodCount = 6

    private var accentColor: Color {
        if let category = selectedCategory { return category.color(in: categoryColors) }
        if let tag = selectedTag, !tag.isDeleted { return tag.color }
        return .sage
    }

    var filteredExpenses: [Expense] {
        allExpenses.filter { expense in
            let matchesCategory = selectedCategory == nil || expense.category == selectedCategory
            let matchesTag = selectedTag == nil || selectedTag?.isDeleted == true || (expense.tags ?? []).contains { $0.id == selectedTag?.id }
            return matchesCategory && matchesTag
        }
    }

    /// Recurring rules matching the active category/tag filter.
    private var filteredRecurringRules: [RecurringExpenseRule] {
        recurringRules.filter { rule in
            let matchesCategory = selectedCategory == nil || rule.category == selectedCategory
            let matchesTag = selectedTag == nil || selectedTag?.isDeleted == true || (rule.tags ?? []).contains { $0.id == selectedTag?.id }
            return matchesCategory && matchesTag
        }
    }

    private var currentPeriodInterval: DateInterval {
        calendar.dateInterval(of: timeframe.calendarComponent, for: Date()) ?? DateInterval(start: Date(), duration: 0)
    }

    /// Filtered expenses recorded from the start of the current period through now.
    var currentPeriodExpenses: [Expense] {
        let now = Date()
        return filteredExpenses.filter {
            $0.date >= currentPeriodInterval.start && $0.date <= now
        }
    }

    var chartData: [SpendingPeriodData] {
        let now = Date()
        return (0..<periodCount).reversed().compactMap { periodsAgo in
            guard let target = calendar.date(byAdding: timeframe.calendarComponent, value: -periodsAgo, to: now),
                  let interval = calendar.dateInterval(of: timeframe.calendarComponent, for: target) else { return nil }
            let periodExpenses = filteredExpenses.filter {
                $0.date >= interval.start && $0.date < interval.end
            }
            let label = switch timeframe {
            case .monthly: target.formatted(.dateTime.month(.abbreviated))
            case .weekly: interval.start.formatted(.dateTime.month(.abbreviated).day())
            }
            return SpendingPeriodData(
                periodStart: interval.start,
                label: label,
                total: periodExpenses.total,
                isCurrent: periodsAgo == 0
            )
        }
    }

    /// Spending from the start of the current period through now.
    var currentPartialTotal: Double {
        currentPeriodExpenses.total
    }

    /// Spending in the previous period through the same elapsed time, for an apples-to-apples comparison.
    var previousPartialTotal: Double {
        let now = Date()
        let elapsed = now.timeIntervalSince(currentPeriodInterval.start)
        guard let previousDate = calendar.date(byAdding: timeframe.calendarComponent, value: -1, to: now),
              let previousInterval = calendar.dateInterval(of: timeframe.calendarComponent, for: previousDate) else { return 0 }
        let cutoff = min(previousInterval.start.addingTimeInterval(elapsed), previousInterval.end)
        return filteredExpenses.filter {
            $0.date >= previousInterval.start && $0.date <= cutoff
        }.total
    }

    /// Variable (non-recurring) spend totals for recent *complete* periods,
    /// used as the historical baseline for the projection.
    private var historicalVariableTotals: [Double] {
        let now = Date()
        return (1..<periodCount).compactMap { periodsAgo in
            guard let target = calendar.date(byAdding: timeframe.calendarComponent, value: -periodsAgo, to: now),
                  let interval = calendar.dateInterval(of: timeframe.calendarComponent, for: target) else { return nil }
            return filteredExpenses.filter {
                $0.date >= interval.start && $0.date < interval.end && $0.recurringExpenseId == nil
            }.total
        }
    }

    /// Recurring-aware, history-blended projection of total spend for the period.
    var projectedTotal: Double {
        SpendingProjection.project(
            periodExpenses: currentPeriodExpenses,
            recurringRules: filteredRecurringRules,
            interval: currentPeriodInterval,
            now: Date(),
            historicalVariableTotals: historicalVariableTotals,
            calendar: calendar
        )
    }

    private var projectedRemainder: Double {
        max(0, projectedTotal - currentPartialTotal)
    }

    private var periodBudget: Double? {
        guard timeframe == .monthly, config.totalMonthlyIncome > 0, selectedTag == nil else { return nil }
        switch selectedCategory {
        case .needs: return config.needsBudget
        case .wants: return config.wantsBudget
        case .savings: return config.savingsBudget
        case nil: return config.needsBudget + config.wantsBudget + config.savingsBudget
        @unknown default: return config.needsBudget + config.wantsBudget + config.savingsBudget
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    StatsFilterBar(
                        selectedCategory: $selectedCategory,
                        selectedTag: $selectedTag
                    )
                    .padding(.horizontal)

                    Picker("Timeframe", selection: $timeframe) {
                        ForEach(StatsTimeframe.allCases) { timeframe in
                            Text(timeframe.rawValue).tag(timeframe)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    spendingChart
                        .padding(.horizontal)
                    
                    if currentPartialTotal > 0 && selectedTag == nil {
                        TopSpendingBreakdown(
                            expenses: currentPeriodExpenses,
                            accentColor: accentColor,
                            contentPadding: 16
                        )
                        .padding(.horizontal)
                    }

                    SpendingComparisonCard(
                        currentPartialTotal: currentPartialTotal,
                        previousPartialTotal: previousPartialTotal,
                        projectedTotal: projectedTotal,
                        periodBudget: periodBudget,
                        timeframe: timeframe
                    )
                    .padding(.horizontal)

                }
                .padding(.vertical)
            }
            .background(.sageBackground)
            .navigationTitle("Stats")
            .gradientBackground(color: accentColor)
        }
    }

    private var spendingChart: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(timeframe == .monthly ? "Total Spending by Month" : "Total Spending by Week")
                .font(.headline)
                .padding(.bottom, 8)

            Chart {
                ForEach(chartData) { item in
                    BarMark(
                        x: .value("Period", item.label),
                        y: .value("Spending", item.total)
                    )
                    .foregroundStyle(item.isCurrent ? accentColor : accentColor.opacity(0.5))
                    .cornerRadius(4)
                    .accessibilityLabel(item.isCurrent ? "\(item.label), current period" : item.label)
                    .accessibilityValue(item.total.currencyString)
                    .annotation(position: .top, spacing: 4) {
                        if item.total > 0 && !(item.isCurrent && projectedRemainder > 0) {
                            // Rounded like the axis — six labels across the plot collide at full precision.
                            Text(item.total.currencyStringRounded)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if item.isCurrent && projectedRemainder > 0 {
                        BarMark(
                            x: .value("Period", item.label),
                            y: .value("Spending", projectedRemainder)
                        )
                        .foregroundStyle(accentColor.opacity(0.2))
                        .cornerRadius(4)
                        .accessibilityLabel("\(item.label), projected additional spending")
                        .accessibilityValue(projectedRemainder.currencyString)
                        .annotation(position: .top, spacing: 4) {
                            Text("\(projectedTotal.currencyStringRounded) est.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            // Axis labels are a scale, not amounts — cents would just crowd them.
                            Text(doubleValue.currencyStringRounded)
                                .font(.caption2)
                        }
                    }
                    AxisGridLine()
                }
            }
            .animation(reduceMotion ? nil : .easeInOut, value: chartData.map(\.total))
            .frame(height: 220)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 15).fill(.cardBackground))
    }
}

#Preview {
    StatsView()
        .environmentInjection()
}

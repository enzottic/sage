//
//  SpendingComparisonCard.swift
//  FinanceTracker
//
//  Created on 3/13/26.
//

import SwiftUI
import SageKit

struct SpendingComparisonCard: View {
    let currentPartialTotal: Double
    let previousPartialTotal: Double
    let projectedTotal: Double
    var periodBudget: Double? = nil
    let timeframe: StatsTimeframe

    private var percentageChange: Double {
        guard previousPartialTotal > 0 else { return 0 }
        return ((currentPartialTotal - previousPartialTotal) / previousPartialTotal) * 100
    }

    private var isSpendingMore: Bool { percentageChange > 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if previousPartialTotal > 0 {
                HStack(spacing: 4) {
                    Image(systemName: isSpendingMore ? "arrow.up.right" : "arrow.down.right")
                        .foregroundStyle(isSpendingMore ? .red : .green)

                    Text("\(abs(percentageChange), specifier: "%.0f")%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(isSpendingMore ? .red : .green)

                    switch timeframe {
                    case .monthly:
                        Text(isSpendingMore ? "more than last month" : "less than last month")
                    case .weekly:
                        Text(isSpendingMore ? "more than last week" : "less than last week")
                    }
                }

                switch timeframe {
                case .monthly:
                    Text("So far: \(currentPartialTotal.currencyString) vs \(previousPartialTotal.currencyString) at this point last month")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                case .weekly:
                    Text("So far: \(currentPartialTotal.currencyString) vs \(previousPartialTotal.currencyString) at this point last week")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if projectedTotal > 0 {
                if previousPartialTotal > 0 {
                    Divider()
                }

                HStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(.secondary)
                    switch timeframe {
                    case .monthly:
                        Text("On pace to spend \(projectedTotal.currencyString) this month")
                    case .weekly:
                        Text("On pace to spend \(projectedTotal.currencyString) this week")
                    }
                }
                .font(.subheadline)

                if let periodBudget {
                    let difference = projectedTotal - periodBudget
                    let isOver = difference > 0
                    HStack(spacing: 6) {
                        Image(systemName: isOver ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        if isOver {
                            Text("\(difference.currencyString) over your \(periodBudget.currencyString) budget")
                        } else {
                            Text("\(abs(difference).currencyString) under your \(periodBudget.currencyString) budget")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(isOver ? .red : .green)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 15).fill(.cardBackground))
    }
}

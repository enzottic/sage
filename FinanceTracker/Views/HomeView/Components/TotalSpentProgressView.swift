//
//  TotalSpentProgressView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 3/15/26.
//

import SwiftUI
import Charts
import SageKit

struct TotalSpentProgressView: View {
    @Environment(\.categoryColors) private var categoryColors
    let wantsSpent: Double
    let needsSpent: Double
    let savingsSpent: Double
    let totalIncome: Double

    var totalSpent: Double {
        wantsSpent + needsSpent + savingsSpent
    }

    var unspent: Double {
        max(totalIncome - totalSpent, 0)
    }

    private var chartData: [(category: String, amount: Double)] {
        var data: [(category: String, amount: Double)] = []
        if wantsSpent > 0 { data.append(("Wants", wantsSpent)) }
        if needsSpent > 0 { data.append(("Needs", needsSpent)) }
        if savingsSpent > 0 { data.append(("Savings", savingsSpent)) }
        if unspent > 0 { data.append(("Unspent", unspent)) }
        if data.isEmpty { data.append(("Unspent", 1)) }
        return data
    }

    private func color(for category: String) -> Color {
        switch category {
        case "Wants": categoryColors.wants
        case "Needs": categoryColors.needs
        case "Savings": categoryColors.savings
        default: .gray
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Chart(chartData, id: \.category) { item in
                SectorMark(
                    angle: .value("Amount", item.amount),
                    innerRadius: .ratio(0.75),
                    angularInset: 2
                )
                .cornerRadius(5)
                .foregroundStyle(by: .value("Category", item.category))
            }
            .chartBackground { chartProxy in
                GeometryReader { geo in
                    if let anchor = chartProxy.plotFrame {
                        let frame = geo[anchor]
                        VStack(spacing: 2) {
                            Text("SPENT")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text(totalSpent.currencyString)
                                .font(.title)
                                .fontWeight(.black)

                            Text("\(unspent.currencyString) left of \(totalIncome.currencyString)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                        }
                        .position(x: frame.midX, y: frame.midY)
                    }
                }
            }
            .chartLegend(.hidden)
            .chartForegroundStyleScale([
                "Wants": categoryColors.wants,
                "Needs": categoryColors.needs,
                "Savings": categoryColors.savings,
                "Unspent": Color.gray
            ])
            .frame(minHeight: 220)

            HStack(spacing: 16) {
                ForEach(chartData, id: \.category) { item in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(color(for: item.category))
                            .frame(width: 10, height: 10)
                        Text(item.category)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    TotalSpentProgressView(wantsSpent: 300, needsSpent: 400, savingsSpent: 100, totalIncome: 1000)
}

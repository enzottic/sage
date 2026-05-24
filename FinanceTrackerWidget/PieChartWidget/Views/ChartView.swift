//
//  ChartView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/7/25.
//
import SwiftUI
import Charts

struct ChartView: View {
    @Environment(\.categoryColors) private var categoryColors
    let chartData: [ExpenseData]

    var body: some View {
        Chart(chartData, id: \.category) { item in
            SectorMark(
                angle: .value("Count", item.count),
                innerRadius: .ratio(0.6),
                angularInset: 2
            )
            .cornerRadius(5)
            .foregroundStyle(by: .value("Expense Type", item.category))
        }
        .chartBackground { chartProxy in
            GeometryReader { geo in
                if let anchor = chartProxy.plotFrame {
                    let frame = geo[anchor]
                    Text("Categories")
                        .position(x: frame.midX, y: frame.midY)
                        .font(.caption)
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
    }
}

struct ExpenseData {
    var category: String
    var count: Double
}

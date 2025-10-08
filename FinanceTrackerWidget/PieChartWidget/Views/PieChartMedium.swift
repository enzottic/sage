//
//  PieChartMedium.swift
//  FinanceTrackerWidgetExtension
//
//  Created by Tyler McCormick on 10/7/25.
//

import SwiftUI

struct PieChartMedium: View {
    let chartData: [ExpenseData]
    
    var body: some View {
        HStack(spacing: 20) {
           ChartView(chartData: chartData)
                .scaledToFit()
            VStack(alignment: .leading, spacing: 10) {
                categoryLabel(for: .wants)
                categoryLabel(for: .needs)
                categoryLabel(for: .savings)
            }
        }
    }
        
    func categoryLabel(for category: ExpenseCategory) -> some View {
        HStack {
            Circle()
                .frame(width: 10, height: 10)
                .foregroundStyle(category.color)
            Text(category.rawValue)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

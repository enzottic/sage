//
//  PieChartSmall.swift
//  FinanceTrackerWidgetExtension
//
//  Created by Tyler McCormick on 10/7/25.
//

import SwiftUI

struct PieChartSmall: View {
    let chartData: [ExpenseData]
    
    var body: some View {
        VStack {
            ChartView(chartData: chartData)
        }
    }
}

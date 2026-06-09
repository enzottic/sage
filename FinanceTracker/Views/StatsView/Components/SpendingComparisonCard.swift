//
//  SpendingComparisonCard.swift
//  FinanceTracker
//
//  Created on 3/13/26.
//

import SwiftUI

struct SpendingComparisonCard: View {
    let currentMonthPartialTotal: Double
    let lastMonthPartialTotal: Double

    private var percentageChange: Double {
        guard lastMonthPartialTotal > 0 else { return 0 }
        return ((currentMonthPartialTotal - lastMonthPartialTotal) / lastMonthPartialTotal) * 100
    }

    private var isSpendingMore: Bool { percentageChange > 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if lastMonthPartialTotal > 0 {
                HStack(spacing: 4) {
                    Image(systemName: isSpendingMore ? "arrow.up.right" : "arrow.down.right")
                        .foregroundStyle(isSpendingMore ? .red : .green)
                    
                    Text("\(abs(percentageChange), specifier: "%.0f")%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(isSpendingMore ? .red : .green)
                    
                    Text(isSpendingMore ? "more than last month" : "less than last month")
                }
                
                let dayOfMonth = Calendar.current.component(.day, from: Date())
                Text("Through day \(dayOfMonth): \(currentMonthPartialTotal.currencyString) vs \(lastMonthPartialTotal.currencyString)")
                    .font(.caption)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 15).fill(.cardBackground))
    }
}

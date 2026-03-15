//
//  TotalSpentProgressView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 3/15/26.
//

import SwiftUI

struct TotalSpentProgressView: View {
    let utilization: Double
    let used: Double
    let total: Double
    
    let lineWidth: CGFloat = 15

    var body: some View {
        ZStack {
            Text(used.currencyString)
                .font(.largeTitle)
                .fontWeight(.black)
            
            CircularProgressView(progress: utilization, tint: .sage, lineWidth: lineWidth)
        }
    }
}

#Preview {
    TotalSpentProgressView(utilization: 0.5, used: 500, total: 1000)
}

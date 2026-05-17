//
//  CircularProgressView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 12/24/25.
//

import SwiftUI
import Charts

struct CircularProgressBar: View {
    let progress: Double
    let lineWidth: CGFloat
    let tint: Color
    
    init(progress: Double, tint: Color = .blue, lineWidth: CGFloat = 5) {
        self.progress = progress
        self.tint = tint
        self.lineWidth = lineWidth
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: lineWidth)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90)) // Start from top
                .animation(.easeInOut, value: progress)
            
            Text(progress.formatted(.percent.precision(.fractionLength(0))))
                .font(.caption)
        }
    }
}




#Preview {
    CircularProgressBar(progress: 0.7)
}

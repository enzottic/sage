//
//  CircularProgressView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 12/24/25.
//

import SwiftUI
import Charts

struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat = 5
    let tint: Color
    
    init(progress: Double, tint: Color = .blue) {
        self.progress = progress
        self.tint = tint
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
        }
        .frame(width: 50, height: 50)
    }
}


#Preview {
    CircularProgressView(progress: 0.7)
}

//
//  AllocationSlider.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/21/25.
//

import SwiftUI

struct AllocationSlider: View {
    let title: String
    @Binding var percentage: Double
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 30)

                Text(title)
                    .font(.headline)

                Spacer()

                Text("\(Int(percentage))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
            }

            Slider(value: Binding(
                get: { percentage },
                set: { newValue in
                    percentage = round(newValue / 5) * 5
                }
            ), in: 0...100, step: 5)
                .tint(color)
        }
        .padding()
        .background(Color.ui.cardBackground)
        .cornerRadius(15)
    }
}

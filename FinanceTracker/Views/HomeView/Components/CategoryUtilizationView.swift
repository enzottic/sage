//
//  CategoryUtilizationView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 3/13/26.
//
import SwiftUI

struct CategoryUtilizationView: View {
    @Environment(\.categoryColors) private var categoryColors
    let category: ExpenseCategory
    let utilization: Double
    let used: Double
    let total: Double

    init(for category: ExpenseCategory, _ utilization: Double, _ used: Double, _ total: Double) {
        self.category = category
        self.utilization = utilization
        self.used = used
        self.total = total
    }

    var body: some View {
        HStack(spacing: 10) {
            CircularProgressBar(progress: utilization, tint: category.color(in: categoryColors))
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading) {
                Text(category.rawValue)
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack(spacing: 5) {
                    Text(used.currencyString)
                        .fontWeight(.semibold)
                        .foregroundStyle(utilization > 1.0 ? .red : .primary)
                    Text("of \(total.currencyString)")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    CategoryUtilizationView(for: .wants, 0.3, 100, 300)
}

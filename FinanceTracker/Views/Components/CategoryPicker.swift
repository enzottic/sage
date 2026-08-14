//
//  CategorySelector.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/6/25.
//

import SwiftUI
import SageKit

struct CategoryPicker: View {
    @Environment(\.categoryColors) private var categoryColors
    @Binding var selectedCategory: ExpenseCategory

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                categoryButtons
            }

            VStack {
                categoryButtons
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var categoryButtons: some View {
            ForEach(ExpenseCategory.allCases, id: \.self) { category in
                let isSelected = selectedCategory == category
                Button {
                    selectedCategory = category
                } label: {
                    HStack {
                        Circle()
                            .frame(width: 10, height: 10)
                            .foregroundStyle(category.color(in: categoryColors))
                        
                        Text(category.rawValue)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isSelected ? Color.secondary : .cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .foregroundStyle(.primary)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityValue(isSelected ? "Selected" : "Not selected")
            }
    }
}

#Preview {
    @Previewable @State var selectedCategory: ExpenseCategory = .allCases.randomElement()!
    CategoryPicker(selectedCategory: $selectedCategory)
}

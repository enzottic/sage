//
//  CategorySelector.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/6/25.
//

import SwiftUI

struct CategoryPicker: View {
    @Binding var selectedCategory: ExpenseCategory
    
    var body: some View {
        HStack {
            ForEach(ExpenseCategory.allCases, id: \.self) { category in
                Button {
                    selectedCategory = category
                } label: {
                    HStack {
                        Circle()
                            .frame(width: 10, height: 10)
                            .foregroundStyle(category.color)
                        
                        Text(category.rawValue)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedCategory == category ? Color.secondary : Color.ui.cardBackground)
                .cornerRadius(15)
                .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    @Previewable @State var selectedCategory: ExpenseCategory = .allCases.randomElement()!
    CategoryPicker(selectedCategory: $selectedCategory)
}

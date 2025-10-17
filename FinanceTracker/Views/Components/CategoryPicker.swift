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
        VStack(alignment: .leading) {
            
            ForEach(ExpenseCategory.allCases, id: \.self) { category in
                Button {
                    selectedCategory = category
                } label: {
                    HStack {
                        Circle()
                            .frame(width: 10, height: 10)
                            .foregroundStyle(category.color)
                        VStack(alignment: .leading) {
                            Text(category.rawValue)
                            Text(category.description)
                                .font(.caption)
                        }
                        
                        Spacer()
                        
                        if selectedCategory == category {
                            Image(systemName: "checkmark")
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(Color.ui.cardBackground)
                .cornerRadius(15)
                .foregroundStyle(.primary)
            }
        }
    }
}

#Preview {
    @Previewable @State var selectedCategory: ExpenseCategory = .allCases.randomElement()!
    CategoryPicker(selectedCategory: $selectedCategory)
}

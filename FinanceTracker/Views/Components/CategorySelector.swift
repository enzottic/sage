//
//  CategorySelector.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/6/25.
//

import SwiftUI

struct CategorySelector: View {
    @Binding var selectedCategory: ExpenseCategory
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                HStack {
                    Circle()
                        .frame(width: 10, height: 10)
                        .foregroundStyle(Color.ui.needColor)
                    Text("Need")
                }
                Text("Essential expenses like groceries, utilities, gas")
                    .font(.caption)
            }
            .padding()
            .background(selectedCategory == .needs ? Color.ui.selectedNeed : Color.clear)
            .cornerRadius(5)
            .onTapGesture {
                selectedCategory = .needs
            }
            
            VStack(alignment: .leading) {
                HStack {
                    Circle()
                        .frame(width: 10, height: 10)
                        .foregroundStyle(Color.ui.wantColor)
                    Text("Want")
                }
                Text("Non-essentials like dining, entertainment, etc.")
                    .font(.caption)
            }
            .padding()
            .background(selectedCategory == .wants ? Color.ui.selectedWant : Color.clear)
            .cornerRadius(10)
            .onTapGesture {
                selectedCategory = .wants
            }
        }
    }
    
}

#Preview {
    @Previewable @State var selectedCategory: ExpenseCategory = .allCases.randomElement()!
    CategorySelector(selectedCategory: $selectedCategory)
}

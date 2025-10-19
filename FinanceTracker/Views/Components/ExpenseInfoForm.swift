//
//  ExpenseInfoForm.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/16/25.
//

import SwiftUI

struct ExpenseInfoForm: View {
    
    @Binding var name: String
    @Binding var amount: Double?
    @Binding var date: Date
    @Binding var category: ExpenseCategory
    @Binding var tag: ExpenseTag

    var body: some View {
        VStack(spacing: 20) {
            CustomDatePicker(selectedDate: $date)

            HStack {
                TextField("Expense Name", text: $name)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            Spacer()
            
            HStack {
                TextField("$0.00", value: $amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .keyboardType(.decimalPad)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
                
            CategoryPicker(selectedCategory: $category)
            
            TagPicker(selectedTag: $tag)
        }
    }
}

#Preview {
    @Previewable @State var name: String = "My Expense"
    @Previewable @State var amount: Double? = 1254.12
    @Previewable @State var date: Date = Date.now
    @Previewable @State var category: ExpenseCategory = .needs
    @Previewable @State var tag: ExpenseTag = .other
    ExpenseInfoForm(
        name: $name,
        amount: $amount,
        date: $date,
        category: $category,
        tag: $tag,
    )
}


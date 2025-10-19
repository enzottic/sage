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
    @Binding var tag: ExpenseTag?
    @Binding var note: String

    var body: some View {
        VStack(spacing: 20) {
            CustomDatePicker(selectedDate: $date)

            VStack {
                TextField("Expense Name", text: $name)
                    .font(.title)
                    .fontWeight(.bold)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                
                TextField("Add a note", text: $note)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            
            TextField("$0.00", value: $amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                .keyboardType(.decimalPad)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Spacer()
                
            CategoryPicker(selectedCategory: $category)
            
            TagPicker(selectedTag: $tag)
        }
        .multilineTextAlignment(.center)
    }
}

#Preview {
    @Previewable @State var name: String = "My Expense"
    @Previewable @State var amount: Double? = 1254.12
    @Previewable @State var date: Date = Date.now
    @Previewable @State var category: ExpenseCategory = .needs
    @Previewable @State var tag: ExpenseTag? = nil
    @Previewable @State var note: String = ""
    ExpenseInfoForm(
        name: $name,
        amount: $amount,
        date: $date,
        category: $category,
        tag: $tag,
        note: $note
    )
}


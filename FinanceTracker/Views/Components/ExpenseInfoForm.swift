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
        VStack(spacing: 16) {
            // Name and date at top
            CustomDatePicker(selectedDate: $date)

            TextField("Expense Name", text: $name)
                .font(.title)
                .fontWeight(.bold)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            TextField("Add a note", text: $note)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Amount in the middle
            Spacer()

            CentsFirstCurrencyField(amount: $amount)

            Spacer()

            // Category and tag at the bottom
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


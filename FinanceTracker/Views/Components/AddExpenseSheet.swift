//
//  AddExpenseSheet.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/4/25.
//

import SwiftUI
import SwiftData
import WidgetKit

struct AddExpenseSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var amount: Double? = nil
    @State private var date: Date = Date.now
    @State private var category: ExpenseCategory = .needs
    @State private var tag: ExpenseTag = .other

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                HStack {
                    TextField("Expense Name", text: $name)
                        .font(.title)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                HStack {
                    TextField("Amount (\(Locale.current.currency?.identifier ?? "USD"))", value: $amount, format: .number)
                        .keyboardType(.decimalPad)
                        .font(.title)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                    
                DatePicker("Date", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()

                VStack {
                    Text("Category")
                        .font(.headline)
                        .fontWeight(.semibold)
                    CategoryPicker(selectedCategory: $category)
                }
                
                VStack(spacing: 4) {
                    Text("Tag")
                        .font(.headline)
                        .fontWeight(.semibold)

                    TagPicker(selectedTag: $tag)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Save") { saveItem() }
                }
            }
        }
    }
    
    func saveItem() {
        guard !name.isEmpty, amount != nil else { return }
        
        withAnimation {
            let newItem = Expense(name: name, amount: amount!, category: category, date: date, tag: tag)
            modelContext.insert(newItem)
            
            do {
                try modelContext.save()
            } catch {
                print("damn son!")
            }
            
            WidgetCenter.shared.reloadAllTimelines()
            dismiss()
        }
    }
}

#Preview {
    AddExpenseSheet()
        .modelContainer(ModelContainer.preview)
}

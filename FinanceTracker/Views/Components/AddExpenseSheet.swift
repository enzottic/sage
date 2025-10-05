//
//  AddExpenseSheet.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/4/25.
//

import SwiftUI
import SwiftData

struct AddExpenseSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var amount: Double = 0
    @State private var date: Date = Date.now
    @State private var category: ExpenseCategory = .wants
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Expense Name", text: $name)
                
                HStack {
                    TextField("Amount", value: $amount, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                    
                    Button {
                        if let clipboardString = UIPasteboard.general.string, let amountFromClipboard = Double(clipboardString) {
                            amount = amountFromClipboard
                        }
                        
                    } label: {
                        Image(systemName: "doc.on.clipboard")
                    }
                }
                
                DatePicker("Date", selection: $date, displayedComponents: .date)
                
                Picker("Category", selection: $category) {
                    ForEach(ExpenseCategory.allCases, id: \.self) { option in
                        Text(option.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }
            .navigationTitle("Create New Expense")
            .navigationBarTitleDisplayMode(.large)
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
        guard !name.isEmpty else { return }
        
        withAnimation {
            let newItem = Expense(name: name, amount: amount, category: category, date: date)
            modelContext.insert(newItem)
            
            do {
                try modelContext.save()
            } catch {
                print("damn son!")
            }
            
            dismiss()
        }
    }
}

#Preview {
    AddExpenseSheet()
        .modelContainer(ModelContainer.preview)
}

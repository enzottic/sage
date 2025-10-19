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
    
    @State private var showDatePopover: Bool = false
    
    @State private var name: String = ""
    @State private var amount: Double? = nil
    @State private var date: Date = Date.now
    @State private var category: ExpenseCategory = .needs
    @State private var tag: ExpenseTag? = nil
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            ExpenseInfoForm(name: $name, amount: $amount, date: $date, category: $category, tag: $tag, note: $note)
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

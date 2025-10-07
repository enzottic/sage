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
    @State private var category: ExpenseCategory = .wants
    @State private var tag: ExpenseTag = .other

    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    TextField("Expense Name", text: $name)
                    
                    HStack {
                        TextField("Amount (\(Locale.current.currency?.identifier ?? "USD"))", value: $amount, format: .number)
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
                    
                    Picker("Tag", selection: $tag) {
                        ForEach(ExpenseTag.allCases, id: \.self) { option in
                            Text(option.rawValue)
                        }
                    }
                }
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
        guard !name.isEmpty, amount != nil else { return }
        
        withAnimation {
            let newItem = Expense(name: name, amount: amount!, category: category, date: date)
            modelContext.insert(newItem)
            
            do {
                try modelContext.save()
            } catch {
                print("damn son!")
            }
            
            WidgetCenter.shared.reloadAllTimelines()
            
//            WidgetCenter.shared.getCurrentConfigurations { result in
//                guard case .success(let widgets) = result else { return }
//
//                // Iterate over the WidgetInfo elements to find one that matches
//                // the character from the push notification.
//                if let widget = widgets.first(
//                    where: { widget in
//                        let intent = widget.configuration as? LatestExpensesAppIntent
//                    }
//                ) {
//                    WidgetCenter.shared.reloadTimelines(ofKind: widget.kind)
//                }
//            }
            
            dismiss()
        }
    }
}

#Preview {
    AddExpenseSheet()
        .modelContainer(ModelContainer.preview)
}

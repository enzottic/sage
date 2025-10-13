//
//  ExpenseDetailView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/11/25.
//
import SwiftUI
import SwiftData

struct ExpenseDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    let expense: Expense
    
    @State private var isEditing: Bool = false
//    @State private var editedName: String
//    @State private var editedAmount: Double
//    @State private var editedDate: Date
//    @State private var editedCategory: ExpenseCategory
//    @State private var editedTag: ExpenseTag
//       
//    init(expense: Expense) {
//        self.expense = expense
//        _editedName = State(initialValue: expense.name)
//        _editedAmount = State(initialValue: expense.amount)
//        _editedDate = State(initialValue: expense.date)
//        _editedCategory = State(initialValue: expense.category)
//        _editedTag = State(initialValue: expense.tag)
//    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isEditing {
                    EditExpenseSheet(expense: expense)
                } else {
                    VStack(alignment: .center, spacing: 20) {
                        Text(expense.name)
                            .font(.title)
                            .fontWeight(.heavy)
                        
                        Text(expense.amount.currencyStringWithFraction)
                            .font(.title)
                            .fontWeight(.heavy)

                        TagCapsule(tag: expense.tag)
                        
                        Spacer()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if !isEditing {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    if !isEditing {
                        Button("Edit") {
                            isEditing = true
                        }
                        //                        Button("Save") {
                        //                            save()
                        //                        }
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    ExpenseDetailView(expense: Expense.example)
        .modelContainer(ModelContainer.preview)
}

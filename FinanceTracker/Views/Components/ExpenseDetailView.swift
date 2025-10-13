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
    
    var body: some View {
        NavigationStack {
            Group {
                if isEditing {
                    EditExpenseSheet(expense: expense) {
                        isEditing = false
                    }
                } else {
                    VStack(alignment: .center, spacing: 20) {
                        Text(expense.date.formatted(date: .complete, time: .omitted))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(expense.name)
                            .font(.title)
                            .fontWeight(.heavy)
                        
                            Text(expense.amount.currencyStringWithFraction)
                                .font(.title)
                                .fontWeight(.heavy)
                        
                        HStack {
                            VStack {
                                Text("TAG")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TagCapsule(tag: expense.tag)
                            }
                        }
                        
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

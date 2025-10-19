//
//  ExpenseDetailView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/11/25.
//
import SwiftUI
import SwiftData
import WidgetKit

struct ExpenseDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    let expense: Expense
    
    @State private var isEditing: Bool = false
    @State private var workingExpense: EditableExpense
    @State private var showingDeleteConfirmation: Bool = false

    init(expense: Expense) {
        self.expense = expense
        _workingExpense = State(initialValue: EditableExpense(
            name: expense.name,
            amount: expense.amount,
            date: expense.date,
            category: expense.category,
            tag: expense.tag
        ))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isEditing {
                    ExpenseInfoForm(
                        name: $workingExpense.name,
                        amount: Binding<Double?>(
                            get: { workingExpense.amount },
                            set: { workingExpense.amount = $0 ?? 0 }
                        ),
                        date: $workingExpense.date,
                        category: $workingExpense.category,
                        tag: $workingExpense.tag,
                    )
                } else {
                    VStack(spacing: 20) {
                        Text(expense.date.formatted(date: .long, time: .omitted))
                            .foregroundStyle(.secondary)
                            .fontWeight(.bold)
                        
                        HStack {
                            Text(expense.name)
                                .font(.title)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        Spacer()
                        
                        HStack {
                            Text(expense.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                        }
                        
                        Spacer()
                        
                        HStack {
                            Circle()
                                .frame(width: 10, height: 10)
                                .foregroundStyle(expense.category.color)
                            
                            Text(expense.category.rawValue)
                        }
                        .padding()
                        .background(Color.ui.cardBackground)
                        .cornerRadius(15)
                        .foregroundStyle(.primary)

                        TagCapsule(tag: expense.tag, .medium)
                    }
                    .alert("Delete Expense?", isPresented: $showingDeleteConfirmation, actions: {
                        Button("Delete", role: .destructive) {
                            withAnimation {
                                dismiss()
                                modelContext.delete(expense)
                                try! modelContext.save()
                                WidgetCenter.shared.reloadAllTimelines()
                            }
                        }
                        
                        Button("Cancel", role: .cancel) {
                            
                        }
                    })
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !isEditing {
                        Button("Delete", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                        .tint(.red)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    if !isEditing {
                        Button("Edit") {
                            isEditing = true
                        }
                    } else {
                        Button("Save") {
                            saveItem()
                            isEditing = false
                        }
                    }
                }
            }
        }
    }
    
    func saveItem() {
        expense.name = workingExpense.name
        expense.amount = workingExpense.amount ?? 0
        expense.date = workingExpense.date
        expense.category = workingExpense.category
        expense.tag = workingExpense.tag
        try! modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

private struct EditableExpense {
    var name: String
    var amount: Double?
    var date: Date
    var category: ExpenseCategory
    var tag: ExpenseTag
}

#Preview {
    @Previewable @State var expense = Expense.example
    ExpenseDetailView(expense: expense)
        .modelContainer(ModelContainer.preview)
}

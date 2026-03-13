//
//  ExpensesScreen.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 9/21/25.
//

import SwiftUI
import SwiftData

struct ExpensesView: View {
    @State private var selectedMonth: Date
    @State private var selectedExpense: Expense? = nil
    @State private var showAddExpenseSheet: Bool = false
    @State private var slideDirection: Edge = .leading
    
    let calendar = Calendar.current
    let formatter: DateFormatter
    
    init(month: Date = Date()) {
        _selectedMonth = State(initialValue: Date())
        formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
    }

    var body: some View {
        NavigationStack {
            MonthExpensesList(month: selectedMonth, selectedExpense: $selectedExpense)
                .frame(maxWidth: .infinity)
                .background(Color.ui.background)
                .navigationTitle(formatter.string(from: selectedMonth))
                .sheet(isPresented: $showAddExpenseSheet, content: {
                    AddExpenseSheet()
                        .presentationDetents([.large])
                        .presentationBackground(Color.ui.background)
                })
                .toolbar {
                    SageToolbar(
                        onPrevious: {
                            slideDirection = .leading
                            selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth)!
                        },
                        onNext: {
                            slideDirection = .trailing
                            selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth)!
                        },
                        onAdd: { showAddExpenseSheet = true }
                    )
                }
        }
        .gradientBackground()
    }
}


#Preview {
    ExpensesView()
        .modelContainer(ModelContainer.preview)
}

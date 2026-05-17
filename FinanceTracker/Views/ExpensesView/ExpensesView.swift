//
//  ExpensesScreen.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 9/21/25.
//

import SwiftUI
import SwiftData

struct ExpensesView: View {
    @Environment(SplitwiseService.self) private var splitwiseService

    @State private var selectedMonth: Date
    @State private var selectedExpense: Expense? = nil
    @State private var showAddExpenseSheet: Bool = false
    @State private var showSplitwiseImport: Bool = false
    @State private var slideDirection: Edge = .leading
    @State private var searchText: String = ""
    
    let calendar = Calendar.current
    let formatter: DateFormatter
    
    init(month: Date = Date()) {
        _selectedMonth = State(initialValue: Date())
        formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
    }

    var body: some View {
        NavigationStack {
            MonthExpensesList(month: selectedMonth, selectedExpense: $selectedExpense, searchText: searchText)
                .frame(maxWidth: .infinity)
                .background(Color.ui.background)
                .navigationTitle(formatter.string(from: selectedMonth))
                .searchable(text: $searchText, prompt: "Search expenses")
                .sheet(isPresented: $showAddExpenseSheet, content: {
                    AddExpenseSheet()
                        .presentationDetents([.large])
                        .presentationBackground(Color.ui.background)
                })
                .sheet(isPresented: $showSplitwiseImport) {
                    SplitwiseImportView()
                }
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
                        onAdd: { showAddExpenseSheet = true },
                        onImportFromSplitwise: splitwiseService.isConfigured
                            ? { showSplitwiseImport = true }
                            : nil
                    )
                }
                .gradientBackground()
        }
    }
}


#Preview {
    ExpensesView()
        .modelContainer(previewAppContainer)
}

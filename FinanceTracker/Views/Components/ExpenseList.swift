//
//  ExpenseListGroup.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/4/25.
//

import SwiftUI
import SwiftData
import WidgetKit
import SageKit

struct ExpenseList: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var appRouter

    let expenses: [Expense]
    var rowStyle: ExpenseRowItem.Style = .regular

    @State private var expenseToDelete: Expense? = nil
    @State private var showingDeleteConfirmation: Bool = false

    var body: some View {
        Group {
            ForEach(expenses) { expense in
                NavigationLink(value: expense) {
                    ExpenseRowItem(expense: expense, style: rowStyle)
                }
                .buttonStyle(.plain)
                .swipeActions {
                    Button("Delete") {
                        expenseToDelete = expense
                        showingDeleteConfirmation = true
                    }
                    .tint(.red)
                    
                    Button("Duplicate") {
                        print("duplicate")
                        appRouter.navigateTo(tab: .home)
                        appRouter.homeRouter.navigateTo(route: .addExpense(expense: expense))
                    }
                }
            }
        }
        .alert("Delete Expense?", isPresented: $showingDeleteConfirmation, actions: {
            Button("Delete", role: .destructive) {
                if let expense = expenseToDelete {
                    deleteExpense(expense)
                }
            }
            Button("Cancel", role: .cancel) {
                expenseToDelete = nil
            }
        })
    }
    
    private func deleteExpense(_ expense: Expense) {
        withAnimation {
            modelContext.delete(expense)
            try! modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
            appRouter.showToast(SageToast(message: "Expense deleted", kind: .success))
        }
    }
}

#Preview {
    NavigationStack {
        List {
            ExpenseList(expenses: [Expense.example, Expense.example])
        }
    }
    .modelContainer(previewAppContainer)
    .environment(AppRouter())
}

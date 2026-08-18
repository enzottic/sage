//
//  MostSpentTagsWidget.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 8/17/26.
//
import SwiftUI
import SwiftData
import SageKit

struct MostSpentTagsWidget: View {
    @Query private var monthlyExpenses: [Expense]

    init(selectedMonth: Date) {
        _monthlyExpenses = expenseQuery(for: selectedMonth)
    }

    var body: some View {
        Section {
            TopSpendingBreakdown(
                expenses: monthlyExpenses,
                accentColor: .sage,
                maximumRows: 3,
                includesUntaggedExpenses: false
            )
        } header: {
            Text("Top Tags")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    MostSpentTagsWidget(selectedMonth: .now)
        .environmentInjection()
}

//
//  SageToolbar.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 3/13/26.
//

import SwiftUI
import TipKit

struct SageToolbar: ToolbarContent {
    var onPrevious: () -> Void
    var onNext: () -> Void
    var onAdd: () -> Void
    var isNextDisabled: Bool = false
    
    var addExpenseTip = AddExpenseTip()

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            Button(action: onPrevious) {
                Label("Previous Month", systemImage: "chevron.left")
            }

            Button(action: onNext) {
                Label("Next Month", systemImage: "chevron.right")
            }
            .disabled(isNextDisabled)
        }

        ToolbarItem(placement: .topBarTrailing) {
            HStack {
                addButton
            }
        }
    }

    @ViewBuilder
    private var addButton: some View {
        Button {
            addExpenseTip.invalidate(reason: .actionPerformed)
            onAdd()
        } label: {
            addLabel
        }
        .accessibilityLabel("Add Expense")
        .accessibilityIdentifier("add-expense-button")
        .tint(.sage)
        .buttonStyle(.borderedProminent)
        .popoverTip(addExpenseTip)
    }

    private var addLabel: some View {
        Image(systemName: "plus")
//            .font(.title3.weight(.semibold))
//            .foregroundStyle(.white)
    }
}

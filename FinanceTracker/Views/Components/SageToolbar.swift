//
//  SageToolbar.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 3/13/26.
//

import SwiftUI

struct SageToolbar: ToolbarContent {
    var onPrevious: () -> Void
    var onNext: () -> Void
    var onAdd: () -> Void
    var isNextDisabled: Bool = false

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
            addButton
        }
    }

    @ViewBuilder
    private var addButton: some View {
        Button(action: onAdd) {
            addLabel
        }
        .accessibilityLabel("Add Expense")
        .accessibilityIdentifier("add-expense-button")
        .tint(.sage)
        .buttonStyle(.borderedProminent)
    }

    private var addLabel: some View {
        Image(systemName: "plus")
//            .font(.title3.weight(.semibold))
//            .foregroundStyle(.white)
    }
}

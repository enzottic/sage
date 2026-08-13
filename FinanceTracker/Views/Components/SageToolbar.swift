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
    var onImportFromSplitwise: (() -> Void)? = nil

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            Button(action: onPrevious) {
                Label("Previous Month", systemImage: "chevron.left")
            }

            Button(action: onNext) {
                Label("Next Month", systemImage: "chevron.right")
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            addButton
        }
    }

    @ViewBuilder
    private var addButton: some View {
        if let onImportFromSplitwise {
            Menu {
                Button {
                    onAdd()
                } label: {
                    Label("Add Expense", systemImage: "plus")
                }

                Button {
                    onImportFromSplitwise()
                } label: {
                    Label("Import from Splitwise", systemImage: "square.and.arrow.down")
                }
            } label: {
                addLabel
            }
            .tint(.sage)
            .buttonStyle(.borderedProminent)
        } else {
            Button(action: onAdd) {
                addLabel
            }
            .tint(.sage)
            .buttonStyle(.borderedProminent)
        }
    }

    private var addLabel: some View {
        Image(systemName: "plus")
//            .font(.title3.weight(.semibold))
//            .foregroundStyle(.white)
    }
}

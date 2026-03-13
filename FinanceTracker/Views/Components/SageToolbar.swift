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

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            Button(action: onPrevious) {
                Label("Previous Month", systemImage: "chevron.left")
            }

            Button(action: onNext) {
                Label("Next Month", systemImage: "chevron.right")
            }
        }

        ToolbarItem {
            Button(action: onAdd) {
                Label("Add Item", systemImage: "plus")
            }
            .background(Color.ui.cardBackground)
            .tint(Color.ui.sageColor)
        }
    }
}

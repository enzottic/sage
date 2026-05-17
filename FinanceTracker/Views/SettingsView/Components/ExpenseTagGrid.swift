//
//  ExpenseTagGrid.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/19/25.
//

import SwiftUI
import SwiftData

struct ExpenseTagGrid: View {
    @Environment(\.modelContext) var modelContext
    let expenseTags: [ExpenseTag]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    @State private var showAddTagSheet: Bool = false
    @State private var tagToEdit: ExpenseTag? = nil

    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(expenseTags.filter { !$0.isDeleted }.sorted { $0.name < $1.name }, id: \.self) { tag in
                TagCapsule(tag: tag, .medium)
                    .contextMenu {
                        Button("Edit") {
                            tagToEdit = tag
                        }
                        Button("Delete", role: .destructive) {
                            withAnimation {
                                modelContext.delete(tag)
                            }
                        }
                    }
            }

            Button("Add Tag") {
                showAddTagSheet = true
            }
        }
        .sheet(isPresented: $showAddTagSheet) {
            AddExpenseTagSheet()
                .presentationBackground(Color.ui.background)
                .presentationDetents([.medium])
        }
        .sheet(item: $tagToEdit) { tag in
            AddExpenseTagSheet(tagToEdit: tag)
                .presentationBackground(Color.ui.background)
                .presentationDetents([.medium])
        }
    }
}

#Preview {
    ExpenseTagGrid(expenseTags: ExpenseTag.defaultTags)
}

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
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(expenseTags, id: \.self) { tag in
                TagCapsule(tag: tag, .medium)
                    .contextMenu {
                        Button("Edit") { }
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
            .buttonStyle(.glass)
        }
        .sheet(isPresented: $showAddTagSheet) {
            AddExpenseTagSheet()
                .presentationBackground(Color.ui.background)
                .presentationDetents([.medium])
        }
    }
}

#Preview {
    ExpenseTagGrid(expenseTags: ExpenseTag.defaultTags)
}

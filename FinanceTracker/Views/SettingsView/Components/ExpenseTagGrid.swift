//
//  ExpenseTagGrid.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/19/25.
//

import SwiftUI

struct ExpenseTagGrid: View {
    let expenseTags: [ExpenseTag]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(expenseTags, id: \.self) { tag in
                TagCapsule(tag: tag, .medium)
                    .contextMenu {
                        Button("Edit") { }
                        Button("Delete", role: .destructive) { }
                    }
            }
            Button("Add Tag") {
                
            }
            .buttonStyle(.glassProminent)
        }
    }
}

#Preview {
    ExpenseTagGrid(expenseTags: ExpenseTag.defaultTags)
}

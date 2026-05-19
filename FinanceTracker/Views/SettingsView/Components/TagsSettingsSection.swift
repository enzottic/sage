//
//  TagsSettingsSection.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 5/19/26.
//

import SwiftUI
import SwiftData

struct TagsSettingsSection: View {
    @Query var expenseTags: [ExpenseTag]
    
    @State private var showAddTagSheet: Bool = false
    
    var body: some View {
        List {
            ExpenseTagGrid(expenseTags: expenseTags)
            Button("Add Tag") {
                
            }
        }
        .sheet(isPresented: $showAddTagSheet) {
            AddExpenseTagSheet()
                .presentationBackground(Color.ui.background)
                .presentationDetents([.medium])
        }
    }
}

#Preview {
    TagsSettingsSection()
        .modelContainer(previewAppContainer)
}

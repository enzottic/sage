//
//  AddExpenseTagSheet.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/19/25.
//

import SwiftUI
import SwiftData

struct AddExpenseTagSheet: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var color: Color = .gray
    @State private var emoji: String = "💰"
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Name", text: $name)
                .font(.largeTitle)
            
            ColorPicker("Color", selection: $color)
                .labelsHidden()
            
            Button("Add") {
                let newExpenseTag = ExpenseTag(name: name, uiColor: UIColor(color), emoji: emoji)
                modelContext.insert(newExpenseTag)
                try? modelContext.save()
                dismiss()
            }
            .buttonStyle(.glassProminent)
        }
        .multilineTextAlignment(.center)
    }
}

#Preview {
    AddExpenseTagSheet()
}

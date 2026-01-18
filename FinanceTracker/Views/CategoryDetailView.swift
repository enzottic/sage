//
//  CategoryDetailView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 12/26/25.
//

import SwiftUI
import SwiftData

struct CategoryDetailView: View {
    let category: ExpenseCategory
    let monthlyExpenses: [Expense]
    
    var body: some View {
        Text(category.rawValue)
    }
}

#Preview {
    @Previewable @State var config = AppConfiguration()
    CategoryDetailView(category: .wants, monthlyExpenses: [Expense.example, Expense.example])
        .modelContainer(ModelContainer.preview)
        .environment(config)
}

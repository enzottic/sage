//
//  Item.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 9/21/25.
//

import Foundation
import SwiftData
import SwiftUI
import FoundationModels

@Model
final class Expense {
    var id: UUID
    var name: String
    var amount: Double
    var category: ExpenseCategory
    var date: Date
    
    enum ExpenseCategory: String, CaseIterable, Codable {
        case wants = "Wants"
        case needs = "Needs"
        case savings = "Savings"
        
        var color: Color {
            switch (self) {
            case .wants: return .green
            case .needs: return .red
            case .savings: return .orange
            }
        }
    }

    init(
        name: String,
        amount: Double,
        category: ExpenseCategory = .wants,
        date: Date = Date.now
    ) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.category = category
        self.date = date
    }
    
}

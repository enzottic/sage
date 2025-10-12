//
//  ExpenseTag.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/7/25.
//
import SwiftUI

enum ExpenseTag: String, Codable, CaseIterable {
    case shopping = "Shopping"
    case dining = "Dining"
    case entertainment = "Entertainment"
    case billsAndUtils = "Bills & Utilities"
    case groceries = "Groceries"
    case subscription = "Subscriptions"
    case travel = "Travel"
    case other = "Other"
    
    var color: Color {
        switch (self) {
        case .shopping: .yellow
        case .dining: .orange
        case .entertainment: .pink
        case .billsAndUtils: .blue
        case .groceries: .green
        case .subscription: .teal
        case .travel: .purple
        case .other: .gray
        }
    }
}

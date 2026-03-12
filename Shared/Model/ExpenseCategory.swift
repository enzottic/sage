//
//  ExpenseCategory.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/5/25.
//
import SwiftUI
import AppIntents

enum ExpenseCategory: String, CaseIterable, Codable, AppEnum {
    case needs = "Needs"
    case wants = "Wants"
    case savings = "Savings"
    
    var color: Color {
        switch (self) {
        case .wants: return .want
        case .needs: return .need
        case .savings: return .teal
        }
    }
    
    var description: String {
        switch self {
        case .needs: "Essentials like bills and groceries."
        case .wants: "Non-essentials like entertainment, dining-out, etc."
        case .savings: "Money set aside to save."
        }
    }
}

extension ExpenseCategory {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Expense Category")
    }
    
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] {
        [
            .wants: "Wants",
            .needs: "Needs",
            .savings: "Savings"
        ]
    }
}

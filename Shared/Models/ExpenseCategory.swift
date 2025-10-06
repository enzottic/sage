//
//  ExpenseCategory.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/5/25.
//
import AppIntents
import SwiftUI

enum ExpenseCategory: String, CaseIterable, Codable, AppEnum {
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

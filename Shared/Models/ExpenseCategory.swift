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
        case .wants: return Color.ui.wantColor
        case .needs: return Color.ui.needColor
        case .savings: return .gray
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

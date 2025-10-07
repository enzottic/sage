//
//  Date+Relative.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 9/21/25.
//

import Foundation

extension Date {
    func relative() -> String {
        let calendar = Calendar.current
        let now = Date()
        
        // Check if it's today
        if calendar.isDateInToday(self) {
            return "Today"
        }
        
        // Check if it's yesterday
        if calendar.isDateInYesterday(self) {
            return "Yesterday"
        }
        
        // Check if it's within the last week (2-7 days ago)
        let daysDifference = calendar.dateComponents([.day], from: self, to: now).day ?? 0
        if daysDifference >= 2 && daysDifference < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE" // Full day name
            return formatter.string(from: self)
        }
        
        // Default to MM/DD/YYYY format
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yyyy"
        return formatter.string(from: self)
    }
}


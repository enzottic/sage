//
//  ExpenseExportManager.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 11/22/25.
//

import Foundation

class ExpenseExportService {
    static let shared = ExpenseExportService()
    
    func exportExpenses(expenses: [Expense]) {
        let csvContent = try? generateCsvString(from: expenses)
        print(csvContent ?? "Nope")
//        let directory = URL.documentsDirectory
    }
    
    private func generateCsvString<T: Identifiable>(from objects: [T]) throws -> String {
        guard let firstObject = objects.first else { return "" }
        
        let mirror = Mirror(reflecting: firstObject)
        let header = mirror.children.compactMap { $0.label }.joined(separator: ",")
        
        var csvRows: [String] = [header]
        
        for object in objects {
            let values = Mirror(reflecting: object).children.map { child in
                let stringValue = String(describing: child.value)
                if stringValue.contains(",") || stringValue.contains("\"") || stringValue.contains("\n") {
                    let escapedValue = stringValue.replacingOccurrences(of: "\"", with: "\"\"")
                    return "\"\(escapedValue)\""
                }
                return stringValue
            }
            csvRows.append(values.joined(separator: ","))
        }
        
        return csvRows.joined(separator: "\n")
    }
}

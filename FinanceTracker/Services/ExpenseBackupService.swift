//
//  ExpenseExportManager.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 11/22/25.
//

import Foundation

class ExpenseBackupService {
    static let shared = ExpenseBackupService()

    func exportExpenses(expenses: [Expense]) -> Result<String, ExpenseExportServiceError> {
        do {
            let csvContent = try generateCsvString(from: expenses.toExportable())
            print(csvContent)
            let fileName = "sage-export.csv"
            
            let documentsDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            
            try csvContent.data(using: .utf8)?.write(to: fileURL, options: .atomic)
            
            print("File saved successfully at: \(fileURL.path)")
            
        } catch {
            print("Error: \(error.localizedDescription)")
            return .failure(.filesystemError("Error saving file: \(error.localizedDescription)"))
        }
        
        
        return .success("File saved successfully")
    }
    
    // Returns an array of ExportableExpense, to be inserted into the SwiftData model on import
    func readExpenses(from filePath: URL) -> Result<[ExportableExpense], ExpenseExportServiceError> {
        guard let fileContents = try? String(contentsOf: filePath, encoding: .utf8) else {
            return .failure(.fileReadError("Could not read file at \(filePath)"))
        }
        
        let expenses = fileContents.split(separator: "\n")
            .dropFirst()
            .map { line in
                let components = line.split(separator: ",", omittingEmptySubsequences: false)
                let name = String(components[0])
                print(String(components[1]))
                let date = try! Date(String(components[1]), strategy: .iso8601)
                let amount = Double(String(components[2]))!
                let category = String(components[3])
                let tag = String(components[4])
                let note = String(components[5])

                return ExportableExpense(name: name, date: date, amount: amount, category: category, tag: tag, note: note)
            }
        
        return .success(expenses)
    }
    
    private func generateCsvString(from objects: [ExportableExpense]) throws -> String {
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

enum ExpenseExportServiceError: Error {
    case serializationError(String)
    case dataConversionError(String)
    case filesystemError(String)
    
    case fileReadError(String)
}
    
class ExportableExpense: Identifiable {
    let name: String
    let date: Date
    let amount: Double
    let category: String
    let tag: String
    let note: String
    
    init(name: String, date: Date, amount: Double, category: String, tag: String, note: String) {
        self.name = name
        self.date = date
        self.amount = amount
        self.category = category
        self.tag = tag
        self.note = note
    }
}

extension [Expense] {
    func toExportable() -> [ExportableExpense] {
        self.map {
            ExportableExpense(name: $0.name, date: $0.date, amount: $0.amount, category: $0.category.rawValue, tag: $0.tag?.name ?? "Other", note: $0.note)
        }
    }
}

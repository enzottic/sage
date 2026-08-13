//
//  ExpenseExportManager.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 11/22/25.
//

import Foundation
import OSLog
import SageKit

final class ExpenseBackupService {
    static let shared = ExpenseBackupService()
    private let logger = Logger(subsystem: "me.enzottic.FinanceTracker", category: "ExpenseBackup")

    func exportExpenses(expenses: [Expense]) -> Result<String, ExpenseExportServiceError> {
        do {
            let csvContent = ExpenseCSVCodec.encode(expenses.toExportable())
            let fileName = "sage-export.csv"
            
            let documentsDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            
            guard let csvData = csvContent.data(using: .utf8) else {
                return .failure(.dataConversionError("Could not encode the CSV file as UTF-8."))
            }
            try csvData.write(to: fileURL, options: .atomic)
            
            logger.info("Expense export completed.")
            
        } catch {
            logger.error("Expense export failed: \(error.localizedDescription, privacy: .private(mask: .hash))")
            return .failure(.filesystemError("Error saving file: \(error.localizedDescription)"))
        }
        
        
        return .success("File saved successfully")
    }
    
    // Returns an array of ExportableExpense, to be inserted into the SwiftData model on import
    func readExpenses(from filePath: URL) -> Result<[ExportableExpense], ExpenseExportServiceError> {
        guard let fileContents = try? String(contentsOf: filePath, encoding: .utf8) else {
            return .failure(.fileReadError("Could not read file at \(filePath)"))
        }
        
        do {
            return .success(try ExpenseCSVCodec.decode(fileContents))
        } catch let error as ExpenseCSVError {
            return .failure(.serializationError(error.localizedDescription))
        } catch {
            return .failure(.serializationError("Could not parse the CSV file: \(error.localizedDescription)"))
        }
    }
}

enum ExpenseExportServiceError: LocalizedError {
    case serializationError(String)
    case dataConversionError(String)
    case filesystemError(String)
    
    case fileReadError(String)

    var errorDescription: String? {
        switch self {
        case .serializationError(let message),
             .dataConversionError(let message),
             .filesystemError(let message),
             .fileReadError(let message):
            return message
        }
    }
}

extension [Expense] {
    func toExportable() -> [ExportableExpense] {
        self.map {
            ExportableExpense(name: $0.name, date: $0.date, amount: $0.amount, category: $0.category.rawValue, tag: ($0.tags ?? []).map(\.name).joined(separator: "|"), note: $0.note)
        }
    }
}

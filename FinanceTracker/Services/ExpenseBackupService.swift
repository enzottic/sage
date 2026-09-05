//
//  ExpenseExportManager.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 11/22/25.
//

import Foundation
import OSLog
import SageKit

final class ExpenseBackupService: Sendable {
    static let shared = ExpenseBackupService()
    nonisolated private static let logger = Logger(
        subsystem: "me.enzottic.FinanceTracker",
        category: "ExpenseBackup"
    )

    func exportExpenses(expenses: [ExportableExpense], currencyCode: String) async -> Result<Void, ExpenseExportServiceError> {
        await Task.detached(priority: .userInitiated) {
            Self.writeExport(expenses: expenses, currencyCode: currencyCode)
        }.value
    }

    func readExpenses(from filePath: URL, currencyCode: String) async -> Result<[ExportableExpense], ExpenseExportServiceError> {
        await Task.detached(priority: .userInitiated) {
            Self.readExport(from: filePath, currencyCode: currencyCode)
        }.value
    }

    nonisolated private static func writeExport(expenses: [ExportableExpense], currencyCode: String) -> Result<Void, ExpenseExportServiceError> {
        do {
            let csvContent = try ExpenseCSVCodec.encode(expenses, currencyCode: currencyCode)
            let fileName = "sage-export.csv"
            
            let documentsDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            
            guard let csvData = csvContent.data(using: .utf8) else {
                return .failure(.dataConversionError("Could not prepare the CSV. Try exporting again."))
            }
            try csvData.write(to: fileURL, options: .atomic)
            
            logger.info("Expense export completed.")
            
        } catch let error as ExpenseCSVError {
            return .failure(.serializationError(error.localizedDescription))
        } catch {
            logger.error("Expense export failed: \(error.localizedDescription, privacy: .private(mask: .hash))")
            return .failure(.filesystemError("Could not save the CSV. Check available storage and try again."))
        }
        
        return .success(())
    }
    
    // Returns an array of ExportableExpense, to be inserted into the SwiftData model on import
    nonisolated private static func readExport(from filePath: URL, currencyCode: String) -> Result<[ExportableExpense], ExpenseExportServiceError> {
        guard let fileContents = try? String(contentsOf: filePath, encoding: .utf8) else {
            return .failure(.fileReadError("Could not read the CSV. Choose another file and try again."))
        }
        
        do {
            let expenses = try ExpenseCSVCodec.decode(fileContents)
            // Reading may stage legacy data; the UI still requires explicit confirmation before writing.
            try ExpenseCSVCodec.validateCurrency(expenses, ledgerCurrencyCode: currencyCode, allowLegacy: true)
            return .success(expenses)
        } catch let error as ExpenseCSVError {
            return .failure(.serializationError(error.localizedDescription))
        } catch {
            return .failure(.serializationError("Could not parse the CSV file: \(error.localizedDescription)"))
        }
    }
}

enum ExpenseExportServiceError: LocalizedError, Sendable {
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

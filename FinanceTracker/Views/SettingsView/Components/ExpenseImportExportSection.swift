//
//  ExpenseImportExportSection.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 5/16/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ExpenseImportExportSection: View {
    @Environment(\.modelContext) var modelContext
    
    @Query var expenses: [Expense]
    @Query var expenseTags: [ExpenseTag]

    @State private var showFileImporter: Bool = false
    @State private var showExportConfirmation: Bool = false
    @State private var showImportConfirmation: Bool = false
    @State private var showImportSuccess: Bool = false
    @State private var pendingImportExpenses: [ExportableExpense] = []
    
    let expenseExporter = ExpenseBackupService.shared

    var body: some View {
        HStack(spacing: 15) {
            Button {
                showFileImporter = true
            } label: {
                Text("Import")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ui.cardBackground)
                    .cornerRadius(15)
            }

            Button {
                let result = expenseExporter.exportExpenses(expenses: expenses)
                if case .success = result {
                    showExportConfirmation = true
                }
            } label: {
                Text("Export")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ui.sage)
                    .cornerRadius(15)
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [UTType.commaSeparatedText],
            allowsMultipleSelection: false,
            onCompletion: importExpenses
        )
        .alert("Export Saved", isPresented: $showExportConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your expenses have been exported to the Files app as sage-export.csv.")
        }
        .alert("Import Expenses", isPresented: $showImportConfirmation) {
            Button("Import") {
                toNormalExpenses(pendingImportExpenses).forEach { modelContext.insert($0) }
                save()
                showImportSuccess = true
                pendingImportExpenses = []
            }
            Button("Cancel", role: .cancel) {
                pendingImportExpenses = []
            }
        } message: {
            Text("Import \(pendingImportExpenses.count) expense\(pendingImportExpenses.count == 1 ? "" : "s") from this file?")
        }
        .alert("Import Complete", isPresented: $showImportSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your expenses have been imported successfully.")
        }
    }
    
    private func importExpenses(filePickerResult: Result<[URL], any Error>) {
        switch (filePickerResult) {
        case .success(let urls):
            if let url = urls.first {
                if url.startAccessingSecurityScopedResource() {
                    print("Accessing file \(url.lastPathComponent)")
                    let readFileResult = expenseExporter.readExpenses(from: url)
                    
                    switch (readFileResult) {
                    case .success(let importedExpenses):
                        pendingImportExpenses = importedExpenses
                        showImportConfirmation = true
                    case .failure(let error):
                        print("Failed to read file: \(error.localizedDescription)")
                    }
                    
                }
            }
        case .failure(let error):
            print("Failed yo: \(error.localizedDescription)")
        }
    }
    
    private func toNormalExpenses(_ importedExpenses: [ExportableExpense]) -> [Expense] {
        importedExpenses.map { e in
            let tag = expenseTags.first { tag in e.tag == tag.name } ?? nil
            
            return Expense(name: e.name, amount: e.amount, category: ExpenseCategory(rawValue: e.category)!, date: e.date, tag: tag, note: e.note)
        }
    }
        
    private func save() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save model context: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ExpenseImportExportSection()
}

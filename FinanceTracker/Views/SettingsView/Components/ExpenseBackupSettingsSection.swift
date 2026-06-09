//
//  ExpenseImportExportSection.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 5/16/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import SageKit

struct ExpenseBackupSettingsSection: View {
    @Environment(\.modelContext) var modelContext
    @Environment(AppConfiguration.self) var config
    @Environment(AppRouter.self) var appRouter
    
    @Query var expenses: [Expense]
    @Query var expenseTags: [ExpenseTag]

    @State private var showFileImporter: Bool = false
    @State private var showExportConfirmation: Bool = false
    @State private var showImportConfirmation: Bool = false
    @State private var showImportSuccess: Bool = false
    @State private var pendingImportExpenses: [ExportableExpense] = []
    
    let expenseExporter = ExpenseBackupService.shared

    var body: some View {
        @Bindable var config = config
        List {
            Section {
                Toggle(isOn: $config.isCloudSyncEnabled) {
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: 35, height: 35)
                                .foregroundStyle(.blue)
                            Image(systemName: "arrow.triangle.2.circlepath.icloud.fill")
                                .frame(width: 35)
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading) {
                            Text("Enable iCloud Sync")
                        }
                    }
                }
            } header: {
                Text("iCloud Sync")
            } footer: {
                Text("Sync your expenses across all your Apple devices.")
            }

            Section {
                Button {
                    showFileImporter = true
                } label: {
                    SettingsListItem(text: "Import from CSV", icon: "square.and.arrow.down", color: .green)
                }

                Button {
                    let result = expenseExporter.exportExpenses(expenses: expenses)
                    switch (result) {
                    case .success:
                        appRouter.showToast(SageToast(message: "Expenses saved to Files app.", kind: .success))
                    case .failure(let error):
                        appRouter.showToast(SageToast(message: error.localizedDescription, kind: .error))
                    }
                } label: {
                    SettingsListItem(text: "Export to CSV", icon: "square.and.arrow.up", color: .orange)
                }
            } header: {
                Text("CSV Backup")
            } footer: {
                Text("Export your expenses as a CSV list. Recurring expense rules are not exported.")
            }
        }
        .navigationTitle("Backup")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [UTType.commaSeparatedText],
            allowsMultipleSelection: false,
            onCompletion: importExpenses
        )
        .alert("Import Expenses", isPresented: $showImportConfirmation) {
            Button("Import") {
                toNormalExpenses(pendingImportExpenses).forEach { modelContext.insert($0) }
                save()
                appRouter.showToast(SageToast(message: "Successfully imported expenses", kind: .success))
                pendingImportExpenses = []
            }
            Button("Cancel", role: .cancel) {
                pendingImportExpenses = []
            }
        } message: {
            Text("Import \(pendingImportExpenses.count) expense\(pendingImportExpenses.count == 1 ? "" : "s") from this file?")
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
    @Previewable @State var config = AppConfiguration()
    @Previewable @State var router = AppRouter()
    ExpenseBackupSettingsSection()
        .environment(config)
        .environment(router)
}

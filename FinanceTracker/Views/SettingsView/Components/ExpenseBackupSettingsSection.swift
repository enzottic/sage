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
    @State private var pendingImportTags: [ExpenseTag] = []
    @State private var unknownTagNames: [String] = []
    @State private var showUnknownTagsSheet: Bool = false
    
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
                importPendingExpenses()
            }
            Button("Cancel", role: .cancel) {
                clearPendingImport()
            }
        } message: {
            Text("Import \(pendingImportExpenses.count) expense\(pendingImportExpenses.count == 1 ? "" : "s") from this file?")
        }
        .sheet(isPresented: $showUnknownTagsSheet) {
            UnknownTagsSheet(
                unknownTagNames: unknownTagNames,
                onResolve: { createdTags in
                    pendingImportTags = createdTags
                    unknownTagNames = []
                    showImportConfirmation = true
                }
            )
            .presentationDetents([.medium])
        }
    }
    
    private func importExpenses(filePickerResult: Result<[URL], any Error>) {
        switch filePickerResult {
        case .success(let urls):
            guard let url = urls.first, url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }

            switch expenseExporter.readExpenses(from: url) {
            case .success(let importedExpenses):
                pendingImportExpenses = importedExpenses

                let knownNames = Set(expenseTags.map(\.name))
                let unknown = importedExpenses
                    .flatMap(\.tagNames)
                    .filter { !knownNames.contains($0) }
                let uniqueUnknown = Array(Set(unknown)).sorted()

                if uniqueUnknown.isEmpty {
                    showImportConfirmation = true
                } else {
                    unknownTagNames = uniqueUnknown
                    showUnknownTagsSheet = true
                }
            case .failure(let error):
                appRouter.showToast(SageToast(message: error.localizedDescription, kind: .error))
            }
        case .failure(let error):
            appRouter.showToast(SageToast(message: error.localizedDescription, kind: .error))
        }
    }

    private func toNormalExpenses(_ importedExpenses: [ExportableExpense]) -> [Expense] {
        importedExpenses.compactMap { e in
            let availableTags = expenseTags + pendingImportTags
            let tagsByName = Dictionary(availableTags.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
            let tags = e.tagNames.compactMap { tagsByName[$0] }
            guard let category = ExpenseCategory(rawValue: e.category) else { return nil }
            return Expense(name: e.name, amount: e.amount, category: category, date: e.date, tags: tags, note: e.note)
        }
    }

    private func importPendingExpenses() {
        let expensesToInsert = toNormalExpenses(pendingImportExpenses)
        guard expensesToInsert.count == pendingImportExpenses.count else {
            appRouter.showToast(SageToast(message: "The import contains an invalid expense category.", kind: .error))
            clearPendingImport()
            return
        }

        pendingImportTags.forEach { modelContext.insert($0) }
        expensesToInsert.forEach { modelContext.insert($0) }

        do {
            try modelContext.save()
            appRouter.showToast(SageToast(message: "Successfully imported expenses", kind: .success))
        } catch {
            modelContext.rollback()
            appRouter.showToast(
                SageToast(message: "The import failed. No expenses were saved: \(error.localizedDescription)", kind: .error)
            )
        }

        clearPendingImport()
    }

    private func clearPendingImport() {
        pendingImportExpenses = []
        pendingImportTags = []
        unknownTagNames = []
    }
}

struct UnknownTagsSheet: View {
    let unknownTagNames: [String]
    let onResolve: ([ExpenseTag]) -> Void

    @State private var selectedNames: Set<String>

    init(unknownTagNames: [String], onResolve: @escaping ([ExpenseTag]) -> Void) {
        self.unknownTagNames = unknownTagNames
        self.onResolve = onResolve
        _selectedNames = State(initialValue: Set(unknownTagNames))
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Image(systemName: "tag.slash.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.orange)
                    .padding(.top, 24)

                Text("Unknown Tags Found")
                    .font(.title3.bold())

                Text("\(unknownTagNames.count) tag\(unknownTagNames.count == 1 ? "" : "s") in this file don't exist yet. Select the ones you'd like to create, or skip to leave those expenses untagged.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
            }

            List(unknownTagNames, id: \.self) { name in
                Button {
                    if selectedNames.contains(name) {
                        selectedNames.remove(name)
                    } else {
                        selectedNames.insert(name)
                    }
                } label: {
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundStyle(.orange)
                        Text(name)
                            .foregroundStyle(.primary)
                        Spacer()
                        if selectedNames.contains(name) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.sage)
                        } else {
                            Image(systemName: "circle")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)

            VStack(spacing: 10) {
                Button {
                    let newTags = unknownTagNames
                        .filter { selectedNames.contains($0) }
                        .map { ExpenseTag(name: $0, uiColor: .systemGray, emoji: "🏷️") }
                    onResolve(newTags)
                } label: {
                    Text(selectedNames.isEmpty ? "Continue Without Creating" : "Create \(selectedNames.count) Tag\(selectedNames.count == 1 ? "" : "s")")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.sage)
                        .cornerRadius(15)
                }

                Button("Skip") {
                    onResolve([])
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
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

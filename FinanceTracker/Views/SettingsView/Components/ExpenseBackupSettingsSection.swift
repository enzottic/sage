//
//  ExpenseImportExportSection.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 5/16/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import WidgetKit
import SageKit

struct ExpenseBackupSettingsSection: View {
    @Environment(\.modelContext) var modelContext
    @Environment(AppConfiguration.self) var config
    @Environment(AppRouter.self) var appRouter
    
    @Query var expenses: [Expense]

    @State private var showFileImporter: Bool = false
    @State private var showImportConfirmation: Bool = false
    @State private var pendingImportExpenses: [ExportableExpense] = []
    @State private var pendingImportCurrencyCode: String?
    // Nil means unresolved/cancelled; an empty selection means explicitly skipping new tags.
    @State private var pendingImportTagNames: [String]?
    @State private var unknownTagNames: [String] = []
    @State private var showUnknownTagsSheet: Bool = false
    @State private var isReadingImport = false
    @State private var isImporting = false
    @State private var isExporting = false
    @State private var importedExpenseCount = 0
    @State private var importTotal = 0
    
    let expenseExporter = ExpenseBackupService.shared

    private var isWorking: Bool {
        isReadingImport || isImporting || isExporting
    }

    var body: some View {
        List {
            Section {
                Toggle(isOn: cloudSyncBinding) {
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
                .disabled(isWorking)
            } header: {
                Text("iCloud Sync")
            } footer: {
                Text("Changes take effect the next time you open the app.")
            }

            Section {
                Button {
                    guard !isWorking else { return }
                    showFileImporter = true
                } label: {
                    SettingsListItem(text: "Import from CSV", icon: "square.and.arrow.down", color: .green)
                }
                .disabled(isWorking)

                Button {
                    exportExpenses()
                } label: {
                    SettingsListItem(text: "Export to CSV", icon: "square.and.arrow.up", color: .orange)
                }
                .disabled(isWorking)
            } header: {
                Text("CSV Backup")
            } footer: {
                Text("Export your expenses as a CSV list. Recurring expense rules are not exported.")
            }
        }
        .settingsBackground()
        .navigationTitle("Backup")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if isWorking {
                operationProgress
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [UTType.commaSeparatedText],
            allowsMultipleSelection: false,
            onCompletion: importExpenses
        )
        .alert("Import Expenses", isPresented: $showImportConfirmation) {
            Button("Import") {
                Task { await importPendingExpenses() }
            }
            .disabled(isWorking)
            Button("Cancel", role: .cancel) {
                clearPendingImport()
            }
        } message: {
            if pendingImportExpenses.contains(where: { $0.currencyCode == nil }) {
                Text("This file has no currency information. Import \(pendingImportExpenses.count) expenses as \(pendingImportCurrencyCode ?? "unconfirmed")? Confirm these amounts were entered in that currency. No conversion will occur.")
            } else {
                Text("Import \(pendingImportExpenses.count) expense\(pendingImportExpenses.count == 1 ? "" : "s") in \(pendingImportCurrencyCode ?? "unconfirmed") from this file? No conversion will occur.")
            }
        }
        .sheet(isPresented: $showUnknownTagsSheet, onDismiss: {
            if pendingImportTagNames != nil {
                showImportConfirmation = true
            } else {
                clearPendingImport()
            }
        }) {
            UnknownTagsSheet(
                unknownTagNames: unknownTagNames,
                onResolve: { selectedNames in
                    pendingImportTagNames = selectedNames
                    showUnknownTagsSheet = false
                }
            )
            .presentationDetents([.medium])
        }
    }

    private var cloudSyncBinding: Binding<Bool> {
        Binding(
            get: { config.isCloudSyncEnabled },
            set: { enabled in
                if config.updateCloudSyncEnabled(enabled) {
                    let state = enabled ? "enabled" : "disabled"
                    appRouter.showToast(
                        SageToast(message: "iCloud sync will be \(state) when you reopen Sage.", kind: .success)
                    )
                } else {
                    appRouter.showToast(
                        SageToast(
                            message: "Sage saved the sync setting on this device. Connect to iCloud, then try again.",
                            kind: .error
                        )
                    )
                }
            }
        )
    }

    @ViewBuilder
    private var operationProgress: some View {
        VStack(spacing: 6) {
            if isImporting {
                ProgressView(value: Double(importedExpenseCount), total: Double(max(importTotal, 1))) {
                    Text("Importing expenses")
                } currentValueLabel: {
                    Text("\(importedExpenseCount) of \(importTotal)")
                }
            } else if isReadingImport {
                ProgressView("Reading CSV")
            } else {
                ProgressView("Creating CSV export")
            }
        }
        .font(.subheadline)
        .padding()
        .frame(maxWidth: .infinity)
        .background(.bar)
        .accessibilityElement(children: .combine)
    }
    
    private func importExpenses(filePickerResult: Result<[URL], any Error>) {
        guard !isWorking else { return }
        clearPendingImport()
        guard let currencyCode = config.ledgerCurrencyCode else {
            appRouter.showToast(SageToast(message: LedgerCurrency.Error.notEstablished.localizedDescription, kind: .error))
            return
        }

        switch filePickerResult {
        case .success(let urls):
            guard let url = urls.first else {
                appRouter.showToast(SageToast(message: "No CSV file was selected. Choose a file and try again.", kind: .error))
                return
            }
            guard url.startAccessingSecurityScopedResource() else {
                appRouter.showToast(SageToast(message: "Sage cannot access this CSV. Choose another file and try again.", kind: .error))
                return
            }

            isReadingImport = true
            appRouter.showToast(SageToast(message: "Reading CSV import…", kind: .progress))

            Task {
                let result = await expenseExporter.readExpenses(from: url, currencyCode: currencyCode)
                url.stopAccessingSecurityScopedResource()
                isReadingImport = false

                switch result {
                case .success(let importedExpenses):
                    pendingImportExpenses = importedExpenses
                    pendingImportCurrencyCode = currencyCode

                    let knownNames: Set<String>
                    do {
                        // Only persisted tags can be resolved by the isolated import context.
                        let readContext = ModelContext(modelContext.container)
                        readContext.autosaveEnabled = false
                        knownNames = Set(try readContext.fetch(FetchDescriptor<ExpenseTag>()).map(\.name))
                    } catch {
                        clearPendingImport()
                        appRouter.showToast(SageToast(message: "Sage could not read your tags. Try importing again.", kind: .error))
                        return
                    }
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
                    appRouter.showToast(SageToast(message: "CSV is ready to import.", kind: .success))
                case .failure(let error):
                    appRouter.showToast(
                        SageToast(message: error.localizedDescription, kind: .error)
                    )
                }
            }
        case .failure:
            appRouter.showToast(SageToast(message: "Sage could not open this CSV. Choose another file and try again.", kind: .error))
        }
    }

    private func exportExpenses() {
        guard !isWorking else { return }
        guard let currencyCode = config.ledgerCurrencyCode else {
            appRouter.showToast(SageToast(message: LedgerCurrency.Error.notEstablished.localizedDescription, kind: .error))
            return
        }

        let exportableExpenses = expenses.toExportable()
        isExporting = true
        appRouter.showToast(SageToast(message: "Creating CSV export…", kind: .progress))

        Task {
            let result = await expenseExporter.exportExpenses(expenses: exportableExpenses, currencyCode: currencyCode)
            isExporting = false

            switch result {
            case .success:
                appRouter.showToast(SageToast(message: "CSV export saved to Files.", kind: .success))
            case .failure(let error):
                appRouter.showToast(SageToast(message: error.localizedDescription, kind: .error))
            }
        }
    }

    private func importPendingExpenses() async {
        guard !isWorking else { return }
        let currentCode: String
        do {
            currentCode = try LedgerCurrency.requireCode()
            guard pendingImportCurrencyCode == currentCode else {
                throw ExpenseCSVError.currencyMismatch(expected: currentCode, actual: pendingImportCurrencyCode ?? "unconfirmed")
            }
        } catch {
            appRouter.showToast(SageToast(message: error.localizedDescription, kind: .error))
            clearPendingImport()
            return
        }

        isImporting = true
        importedExpenseCount = 0
        importTotal = pendingImportExpenses.count
        appRouter.showToast(SageToast(message: "Importing expenses…", kind: .progress))
        defer { isImporting = false }

        do {
            // Reached only from the confirmation alert, which explicitly labels legacy amounts.
            let count = try await ExpenseImportService(modelContainer: modelContext.container).importExpenses(
                pendingImportExpenses,
                ledgerCurrencyCode: currentCode,
                allowLegacy: true,
                creatingTagNames: pendingImportTagNames ?? [],
                progress: { importedExpenseCount = $0 }
            )
            WidgetCenter.shared.reloadAllTimelines()
            appRouter.showToast(
                SageToast(message: "Imported \(count) expense\(count == 1 ? "" : "s").", kind: .success)
            )
        } catch let error as ExpenseCSVError {
            appRouter.showToast(SageToast(message: error.localizedDescription, kind: .error))
        } catch {
            appRouter.showToast(
                SageToast(message: "Sage could not import the CSV. No expenses were saved. Check storage and try again.", kind: .error)
            )
        }

        clearPendingImport()
    }

    private func clearPendingImport() {
        pendingImportExpenses = []
        pendingImportCurrencyCode = nil
        pendingImportTagNames = nil
        unknownTagNames = []
        showImportConfirmation = false
    }
}

struct UnknownTagsSheet: View {
    let unknownTagNames: [String]
    let onResolve: ([String]) -> Void

    @State private var selectedNames: Set<String>

    init(unknownTagNames: [String], onResolve: @escaping ([String]) -> Void) {
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
                    onResolve(unknownTagNames.filter { selectedNames.contains($0) })
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
    @Previewable @State var container = try! SageModelContainer.make(for: .previewEmpty)

    NavigationStack {
        ExpenseBackupSettingsSection()
    }
    .environmentInjection(container: container)
}

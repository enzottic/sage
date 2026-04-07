//
//  SettingsView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 9/21/25.
//
import SwiftUI
import UniformTypeIdentifiers
import WidgetKit
import SwiftData

struct SettingsView: View {
    @Environment(AppConfiguration.self) private var config: AppConfiguration
    @Environment(\.modelContext) var modelContext
    
    @Query var expenseTags: [ExpenseTag]
    @Query var expenses: [Expense]

    @FocusState private var needsFocus: Bool
    @State private var showAddTagSheet: Bool = false
    @State private var showFileImporter: Bool = false
    
    let expenseExporter = ExpenseBackupService.shared


    var body: some View {
        @Bindable var config = config
        
        NavigationStack {
            ScrollView {
                VStack(spacing: 40) {
                    SettingsPanel(title: "Appearance", description: "Choose the default appearance for Sage") {
                        AppearancePicker(appearance: $config.selectedAppearance)
                    }
                    
                    SettingsPanel(title: "Monthly Income", description: "Enter your monthly spendable income in \(Locale.current.currency?.identifier ?? "USD")") {
                        WholeNumberCurrencyField(amount: $config.totalMonthlyIncome, isFocused: $needsFocus)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.ui.cardBackground)
                            .cornerRadius(15)
                            .onChange(of: config.totalMonthlyIncome) { oldValue, newValue in
                                WidgetCenter.shared.reloadAllTimelines()
                            }
                    }
                    
                    SettingsPanel(title: "Budget Allocation", description: "Set percentages for wants and needs.") {
                        VStack(spacing: 20) {
                            AllocationSlider(
                                title: "Wants",
                                percentage: Binding(
                                    get: { config.wantsPercent * 100 },
                                    set: { config.updateWants($0 / 100) }
                                ),
                                color: Color.ui.want,
                                icon: "cart.fill"
                            )

                            AllocationSlider(
                                title: "Needs",
                                percentage: Binding(
                                    get: { config.needsPercent * 100 },
                                    set: { config.updateNeeds($0 / 100) }
                                ),
                                color: Color.ui.need,
                                icon: "house.fill"
                            )

                            HStack {
                                Image(systemName: "banknote.fill")
                                    .foregroundStyle(.teal)
                                    .frame(width: 30)

                                Text("Savings")
                                    .font(.headline)

                                Spacer()

                                Text("\(Int(round(config.savingsPercent * 100)))%")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.teal)
                            }
                            .padding()
                            .background(Color.ui.cardBackground)
                            .cornerRadius(15)
                        }
                    }
                    
                    SettingsPanel(title: "Expense Tags", description: "Add or remove tags for expenses") {
                        ExpenseTagGrid(expenseTags: expenseTags)
                    }
                    
                    SettingsPanel(title: "Export Expenses", description: "Export your expenses as a CSV") {
                        Button("Export") {
                            expenseExporter.exportExpenses(expenses: expenses)
                        }
                        
                        Button("Import") {
                            showFileImporter = true
                        }
                    }
                }
            }
            .padding()
            .background(Color.ui.background)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        needsFocus = false
                    }
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [UTType.commaSeparatedText],
                allowsMultipleSelection: false,
                onCompletion: importExpenses
            )
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
                        toNormalExpenses(importedExpenses) .forEach { modelContext.insert($0) }
                        save()
                    case .failure(let error):
                        print("Failed to read file: \(error.localizedDescription)")
                    }
                    
                }
            }
        case .failure(let error):
            print("Failed yo: \(error.localizedDescription)")
        }
    }
    
    private func save() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save model context: \(error.localizedDescription)")
        }
    }
    
    private func toNormalExpenses(_ importedExpenses: [ExportableExpense]) -> [Expense] {
        importedExpenses.map { e in
            let tag = expenseTags.first { tag in e.tag == tag.name } ?? nil
            
            return Expense(name: e.name, amount: e.amount, category: ExpenseCategory(rawValue: e.category)!, date: e.date, tag: tag, note: e.note)
        }
    }
}

#Preview {
    @Previewable @State var appConfig: AppConfiguration = AppConfiguration()
    SettingsView()
        .environment(appConfig)
        .modelContainer(previewAppContainer)
}


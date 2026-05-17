//
//  SettingsView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 9/21/25.
//
import SwiftUI
import WidgetKit
import SwiftData
import FoundationModels

struct SettingsView: View {
    @Environment(AppConfiguration.self) private var config: AppConfiguration
    
    @Query var expenseTags: [ExpenseTag]

    @FocusState private var needsFocus: Bool
    @State private var showAddTagSheet: Bool = false
    @State private var showSyncRestartAlert: Bool = false

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
                    
                    SettingsPanel(title: "iCloud Sync", description: "Sync your expenses across all your devices") {
                        Toggle(isOn: $config.isCloudSyncEnabled) {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath.icloud.fill")
                                    .foregroundStyle(Color.ui.sage)
                                    .frame(width: 30)
                                Text("Enable iCloud Sync")
                                    .font(.headline)
                            }
                        }
                        .padding()
                        .background(Color.ui.cardBackground)
                        .cornerRadius(15)
                        .onChange(of: config.isCloudSyncEnabled) { _, _ in
                            showSyncRestartAlert = true
                        }
                    }
                    
                    SettingsPanel(title: "Smart Tagging", description: "Select the mode of smart tagging to use. Smart tagging automatically picks a tag for each expense based on the name.") {
                            Picker("Smart Tagging", selection: $config.smartTaggingMode) {
                                ForEach(SmartTaggingMode.allCases, id: \.self) {
                                    Text($0.rawValue)
                                }
                        }
                        .pickerStyle(.menu)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.ui.cardBackground)
                        .cornerRadius(15)
                    }

                    SettingsPanel(title: "Expense Tags", description: "Add or remove tags for expenses") {
                        ExpenseTagGrid(expenseTags: expenseTags)
                    }

                    SettingsPanel(title: "Recurring Expenses", description: "View and manage your recurring expense rules") {
                        RecurringRulesSection()
                    }

                    SettingsPanel(title: "Export Expenses", description: "Export your expenses as a CSV") {
                        ExpenseImportExportSection()
                    }

                    SettingsPanel(title: "Splitwise", description: "Connect your Splitwise account to import shared expenses into Sage") {
                        SplitwiseSettingsSection()
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
            .alert("Restart Required", isPresented: $showSyncRestartAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please restart the app for iCloud sync changes to take effect.")
            }
        }
    }

}

#Preview {
    @Previewable @State var appConfig: AppConfiguration = AppConfiguration()
    SettingsView()
        .environment(appConfig)
        .modelContainer(previewAppContainer)
}


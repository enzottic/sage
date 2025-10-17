//
//  SettingsView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 9/21/25.
//
import SwiftUI
import WidgetKit

struct SettingsView: View {
    @Environment(AppConfiguration.self) private var config: AppConfiguration
    
    @FocusState private var needsFocus: Bool
    
    private func updateNeeds(_ newNeeds: Double) {
        let clampedNeeds = min(max(newNeeds, 0), 1)
        var newWants = config.wantsPercent
        if clampedNeeds + newWants > 1 {
            newWants = 1 - clampedNeeds
        }
        let newSavings = max(1 - (clampedNeeds + newWants), 0)
        config.needsPercent = clampedNeeds
        config.wantsPercent = newWants
        config.savingsPercent = newSavings
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func updateWants(_ newWants: Double) {
        let clampedWants = min(max(newWants, 0), 1)
        var newNeeds = config.needsPercent
        if newNeeds + clampedWants > 1 {
            newNeeds = 1 - clampedWants
        }
        let newSavings = max(1 - (newNeeds + clampedWants), 0)
        config.needsPercent = newNeeds
        config.wantsPercent = clampedWants
        config.savingsPercent = newSavings
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    var body: some View {
        @Bindable var config = config
        
        NavigationStack {
            ScrollView {
                SettingsPanel(title: "Appearance", description: "Choose the default appearance for Sage") {
                    AppearancePicker(appearance: $config.selectedMode)
                }
                
                SettingsPanel(title: "Monthly Income", description: "Enter your monthly spendable income in \(Locale.current.currency?.identifier ?? "USD")") {
                    TextField("Monthly Income", value: $config.totalMonthlyIncome, format: .number)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.ui.cardBackground)
                        .cornerRadius(15)
                        .focused($needsFocus)
                        .onChange(of: config.totalMonthlyIncome) { oldValue, newValue in
                            WidgetCenter.shared.reloadAllTimelines()
                        }
                }
                
                SettingsPanel(title: "Budget Allocation", description: "Set percentages for wants and needs.") {
                    VStack {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Wants (%)")
                                    .foregroundStyle(.gray)
                                TextField("Wants", value: Binding(get: {config.wantsPercent * 100}, set: { updateWants($0 / 100) }), format: .number)
                                    .padding()
                                    .background(Color.ui.cardBackground)
                                    .cornerRadius(15)
                                    .focused($needsFocus)
                            }

                            VStack(alignment: .leading, spacing: 5) {
                                Text("Needs (%)")
                                    .foregroundStyle(.gray)
                                TextField("Needs", value: Binding(get: {config.needsPercent * 100}, set: { updateNeeds($0 / 100) }), format: .number)
                                    .padding()
                                    .background(Color.ui.cardBackground)
                                    .cornerRadius(15)
                                    .focused($needsFocus)
                            }
                        }
                        Text("Savings Percentage: \(Int(config.savingsPercent * 100))")
                            .foregroundStyle(.secondary)
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
        }
    }
}



#Preview {
    @Previewable @State var appConfig: AppConfiguration = AppConfiguration()
    SettingsView()
        .environment(appConfig)
}



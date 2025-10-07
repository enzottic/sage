//
//  SettingsView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 9/21/25.
//
import SwiftUI
import WidgetKit

struct SettingsView: View {
    
    @AppStorage("totalMonthlyIncome", store: UserDefaults(suiteName: "group.me.enzottic.SageAppGroup")) private var totalMonthlyIncome: Int = 4300
    @AppStorage("needsPercent", store: UserDefaults(suiteName: "group.me.enzottic.SageAppGroup")) private var needsPercent: Double = 0.5
    @AppStorage("wantsPercent", store: UserDefaults(suiteName: "group.me.enzottic.SageAppGroup")) private var wantsPercent : Double = 0.3
    @AppStorage("savingsPercent", store: UserDefaults(suiteName: "group.me.enzottic.SageAppGroup")) private var savingsPercent: Double = 0.2
    
    // Clamp and adjust needsPercent and wantsPercent so their sum ≤ 1.0, and update savingsPercent accordingly
    private func updateNeeds(_ newNeeds: Double) {
        let clampedNeeds = min(max(newNeeds, 0), 1)
        var newWants = wantsPercent
        if clampedNeeds + newWants > 1 {
            newWants = 1 - clampedNeeds
        }
        let newSavings = max(1 - (clampedNeeds + newWants), 0)
        needsPercent = clampedNeeds
        wantsPercent = newWants
        savingsPercent = newSavings
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func updateWants(_ newWants: Double) {
        let clampedWants = min(max(newWants, 0), 1)
        var newNeeds = needsPercent
        if newNeeds + clampedWants > 1 {
            newNeeds = 1 - clampedWants
        }
        let newSavings = max(1 - (newNeeds + clampedWants), 0)
        needsPercent = newNeeds
        wantsPercent = clampedWants
        savingsPercent = newSavings
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    SettingsPanel(title: "Monthly Income", description: "Enter your monthly spendable income in \(Locale.current.currency?.identifier ?? "USD")") {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Amount")
                                .foregroundStyle(.gray)
                            
                            TextField("MonthlyIncome", value: $totalMonthlyIncome, format: .number)
                                .sageStyle()
                                .onChange(of: totalMonthlyIncome) {
                                    WidgetCenter.shared.reloadAllTimelines()
                                }
                        }
                    }
                }
                
                Section {
                    SettingsPanel(title: "Budget Allocation", description: "Set percentages for wants and needs.") {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Wants (%)")
                                    .foregroundStyle(.gray)
                                TextField("Wants", value: Binding(get: {wantsPercent * 100}, set: { updateWants($0 / 100) }), format: .number)
                                    .sageStyle()
                            }
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Needs (%)")
                                    .foregroundStyle(.gray)
                                TextField("Needs", value: Binding(get: {needsPercent * 100}, set: { updateNeeds($0 / 100) }), format: .number)
                                    .sageStyle()
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.ui.background)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
    
}

struct SageTextInput: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .keyboardType(.decimalPad)
            .scrollDismissesKeyboard(.immediately)
            .cornerRadius(8)
            .glassEffect()
    }
}

extension View {
    func sageStyle() -> some View {
        modifier(SageTextInput())
    }
}

#Preview {
    SettingsView()
}

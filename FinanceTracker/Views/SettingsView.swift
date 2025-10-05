//
//  SettingsView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 9/21/25.
//
import SwiftUI

struct SettingsView: View {
    
    @AppStorage("totalMonthlyIncome") private var totalMonthlyIncome: Int = 7300
    @AppStorage("needsPercent") private var needsPercent: Double = 0.5
    @AppStorage("wantsPercent") private var wantsPercent : Double = 0.3
    @AppStorage("savingsPercent") private var savingsPercent: Double = 0.2
    
    private var currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currencyAccounting
        return formatter
    }()
    
    private var percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
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
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Total Monthly Income")) {
                    TextField("Total Monthly Income:", value: $totalMonthlyIncome, formatter: currencyFormatter)
                        .keyboardType(.decimalPad)
                        .scrollDismissesKeyboard(.immediately)
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
                
                Section(header: Text("Budget Allocation")) {
                    HStack {
                        Text("Needs")
                        Spacer()
                        TextField("", value: Binding(
                            get: { needsPercent * 100 },
                            set: { newValue in
                                updateNeeds(newValue / 100)
                            }
                        ), formatter: NumberFormatter()) // Raw number, no % sign here
                        .frame(width: 55)
                        .keyboardType(.decimalPad)
                        .scrollDismissesKeyboard(.interactively)
                        Text("%")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Wants")
                        Spacer()
                        TextField("", value: Binding(
                            get: { wantsPercent * 100 },
                            set: { newValue in
                                updateWants(newValue / 100)
                            }
                        ), formatter: NumberFormatter())
                        .frame(width: 55)
                        .keyboardType(.decimalPad)
                        .scrollDismissesKeyboard(.interactively)
                        Text("%")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Savings")
                        Spacer()
                        Text("\(Int((savingsPercent * 100).rounded()))%")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}

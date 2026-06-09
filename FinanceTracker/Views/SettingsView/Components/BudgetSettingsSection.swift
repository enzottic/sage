//
//  BudgetSettingsSection.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 5/18/26.
//

import SwiftUI
import WidgetKit

struct BudgetSettingsSection: View {
    @Environment(AppConfiguration.self) private var config

    @FocusState private var needsFocus: Bool

    var body: some View {
        @Bindable var config = config
        List {
            Section {
                WholeNumberCurrencyField(amount: $config.totalMonthlyIncome, isFocused: $needsFocus)
                    .onChange(of: config.totalMonthlyIncome) { oldValue, newValue in
                        WidgetCenter.shared.reloadAllTimelines()
                    }
            } header: {
                Text("Monthly Income")
            }
            
            Section {
                    AllocationSlider(
                        title: "Wants",
                        color: .want,
                        icon: "cart.fill",
                        percentage: Binding(
                            get: { config.wantsPercent * 100 },
                            set: { config.updateWants($0 / 100) }
                        )
                    )

                    AllocationSlider(
                        title: "Needs",
                        color: .need,
                        icon: "house.fill",
                        percentage: Binding(
                            get: { config.needsPercent * 100 },
                            set: { config.updateNeeds($0 / 100) }
                        )
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
            } header: {
                Text("Budget Allocation")
            }
        }
        .navigationTitle("Budget and Allocation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                Button("Done") {
                    needsFocus = false
                }
            }
        }
    }
}

#Preview {
    BudgetSettingsSection()
        .environmentInjection()
}

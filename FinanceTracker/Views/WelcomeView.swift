//
//  WelcomeView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/21/25.
//

import SwiftUI

struct WelcomePageView<Content: View>: View {
    let title: String
    let description: String
    let content: () -> Content
    
    var body: some View  {
        VStack(spacing: 40) {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(description)
            
            Spacer()
            
            content()
            
            Spacer()
        }
        .padding()
    }
}

struct WelcomeView: View {
    @Environment(AppConfiguration.self) var config
    
    @AppStorage("hasOpenedAppOnce") var hasOpenedAppOnce: Bool = false
    
    var body: some View {
        @Bindable var config = config
        
        TabView {
            VStack(spacing: 40) {
                HStack {
                    Text("Welcome to")
                    Text("Sage")
                        .foregroundColor(Color.ui.sageColor)
                }
                .font(.largeTitle)
                .fontWeight(.bold)
                
                Text("Keep track of your monthly expenses with simple wants, needs, and savings categories")
            }
            .padding()
            
            WelcomePageView(title: "Set Monthly Income", description: "Set the total spendable income you have available each month") {
                    TextField("$0.00", value: $config.totalMonthlyIncome, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .multilineTextAlignment(.center)
                        .font(.largeTitle)
                        .bold()
            }
            
            WelcomePageView(title: "Set Budget", description: "Set percentages for wants and needs spending. Savings will be calculated automatically") {
                VStack {
                    HStack {
                        VStack(alignment: .center, spacing: 5) {
                            Text("Wants (%)")
                                .foregroundStyle(.gray)
                            TextField("Wants", value: Binding(get: {config.wantsPercent * 100}, set: { updateWants($0 / 100) }), format: .number)
                                .font(.largeTitle)
                                .bold()
                                .multilineTextAlignment(.center)
                        }
                        
                        VStack(alignment: .center, spacing: 5) {
                            Text("Needs (%)")
                                .foregroundStyle(.gray)
                            TextField("Needs", value: Binding(get: {config.needsPercent * 100}, set: { updateNeeds($0 / 100) }), format: .number)
                                .font(.largeTitle)
                                .bold()
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    Button("Let's Go") {
                        hasOpenedAppOnce = true
                    }
                }
            }
        }
        .tabViewStyle(.page)
    }
    
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
    }
}

#Preview {
    @Previewable @State var appConfig = AppConfiguration()
    WelcomeView()
        .environment(appConfig)
    
}

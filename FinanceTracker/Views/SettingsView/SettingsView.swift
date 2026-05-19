//
//  SettingsView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 9/21/25.
//
import SwiftUI
import WidgetKit
import SwiftData

struct SettingsView: View {
    @Environment(AppConfiguration.self) private var config: AppConfiguration
    
    @Query var expenseTags: [ExpenseTag]

    @State private var showAddTagSheet: Bool = false
    @State private var showSyncRestartAlert: Bool = false

    private var availableTaggingModes: [SmartTaggingMode] {
        let aiAvailable = TagSuggestionService.isAIAvailable
        return SmartTaggingMode.allCases.filter { mode in
            switch mode {
            case .ai, .both: return aiAvailable
            case .history, .none: return true
            }
        }
    }

    var body: some View {
        @Bindable var config = config
        
        NavigationStack {
            ScrollView {
                VStack(spacing: 40) {
                    SettingsPanel(title: "Smart Tagging", description: "Smart tagging automatically picks a tag for each expense based on its name. AI options require iOS 26 and Apple Intelligence.") {
                        Picker("Smart Tagging", selection: $config.smartTaggingMode) {
                            ForEach(availableTaggingModes, id: \.self) {
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
                }
            }
            .padding()
            .background(Color.ui.background)
            .alert("Restart Required", isPresented: $showSyncRestartAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please restart the app for iCloud sync changes to take effect.")
            }
        }
    }

}

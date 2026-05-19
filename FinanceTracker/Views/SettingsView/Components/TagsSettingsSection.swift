//
//  TagsSettingsSection.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 5/19/26.
//

import SwiftUI
import SwiftData

struct TagsSettingsSection: View {
    @Query(sort: \ExpenseTag.name) var expenseTags: [ExpenseTag]
    @Environment(\.modelContext) private var modelContext
    @Environment(AppConfiguration.self) private var config

    @State private var showAddTagSheet = false
    @State private var tagToEdit: ExpenseTag? = nil

    private var availableTaggingModes: [SmartTaggingMode] {
        SmartTaggingMode.allCases.filter { mode in
            switch mode {
            case .ai, .both: return TagSuggestionService.isAIAvailable
            case .history, .none: return true
            }
        }
    }

    var body: some View {
        @Bindable var config = config
        List {
            Section {
                Picker("Smart Tagging Mode", selection: $config.smartTaggingMode) {
                    ForEach(availableTaggingModes, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Smart Tagging")
            } footer: {
                VStack(alignment: .leading) {
                    let aiSection = TagSuggestionService.isAIAvailable ? "AI mode uses Apple Intelligence to determine a tag for the expense. \nHistory + AI starts by searching for a matching expense, and falls back to AI if a match is not found." : ""
                    Text("Automatically suggests tags when creating a new expense.")
                    Text(aiSection)
                }
            }

            Section("Tags") {
                ForEach(expenseTags.filter { !$0.isDeleted }) { tag in
                    Button {
                        tagToEdit = tag
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(tag.color)
                                    .frame(width: 35, height: 35)
                                Text(tag.emoji)
                                    .font(.system(size: 18))
                            }
                            Text(tag.name)
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                    }
                }
                .onDelete { indexSet in
                    let visible = expenseTags.filter { !$0.isDeleted }
                    for index in indexSet {
                        modelContext.delete(visible[index])
                    }
                }
            }
        }
        .navigationTitle("Tags")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddTagSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddTagSheet) {
            AddExpenseTagSheet()
                .presentationBackground(Color.ui.background)
                .presentationDetents([.medium])
        }
        .sheet(item: $tagToEdit) { tag in
            AddExpenseTagSheet(tagToEdit: tag)
                .presentationBackground(Color.ui.background)
                .presentationDetents([.medium])
        }
    }
}

#Preview {
    @Previewable @State var config = AppConfiguration()
    TagsSettingsSection()
        .environment(config)
        .modelContainer(previewAppContainer)
}

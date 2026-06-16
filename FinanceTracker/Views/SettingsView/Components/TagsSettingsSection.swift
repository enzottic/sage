//
//  TagsSettingsSection.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 5/19/26.
//

import SwiftUI
import SwiftData
import SageKit

struct TagsSettingsSection: View {
    @Query(sort: \ExpenseTag.name) var expenseTags: [ExpenseTag]
    @Environment(\.modelContext) private var modelContext
    @Environment(AppConfiguration.self) private var config

    @State private var showAddTagSheet = false
    @State private var tagToEdit: ExpenseTag? = nil
    @State private var tagPendingDelete: ExpenseTag? = nil

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
                        let tag = visible[index]
                        if (tag.expenses ?? []).isEmpty {
                            modelContext.delete(tag)
                        } else {
                            tagPendingDelete = tag
                        }
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
                .presentationBackground(.sageBackground)
                .presentationDetents([.medium])
        }
        .sheet(item: $tagToEdit) { tag in
            AddExpenseTagSheet(tagToEdit: tag)
                .presentationBackground(.background)
                .presentationDetents([.medium])
        }
        .alert("Remove Tag from Expenses?", isPresented: Binding(
            get: { tagPendingDelete != nil },
            set: { if !$0 { tagPendingDelete = nil } }
        )) {
            Button("Delete Tag", role: .destructive) {
                if let tag = tagPendingDelete {
                    modelContext.delete(tag)
                }
                tagPendingDelete = nil
            }
            Button("Cancel", role: .cancel) {
                tagPendingDelete = nil
            }
        } message: {
            if let tag = tagPendingDelete {
                let count = tag.expenses?.count ?? 0
                Text("\(count) expenses have the \(tag.name) tag. Deleting it will remove the tag from those expenses.")
            }
        }
    }
}

#Preview {
    @Previewable @State var config = AppConfiguration()
    TagsSettingsSection()
        .environment(config)
        .modelContainer(previewAppContainer)
}

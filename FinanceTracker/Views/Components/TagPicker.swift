//
//  TagPicker.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/15/25.
//

import SwiftUI
import SwiftData

struct TagPicker: View {
    @Binding var selectedTag: ExpenseTag?
    /// Whether the currently selected tag was suggested by the AI (shows rainbow border).
    var tagIsAISuggested: Bool = false

    @State private var isExpanded = false
    @State private var newTagSheetIsPresented: Bool = false
    
    @Query(sort: \ExpenseTag.name) var expenseTags: [ExpenseTag]
    
    var body: some View {
        Group {
            if isExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .center, spacing: 10) {
                        ForEach(expenseTags, id: \.self) { option in
                            Button {
                                withAnimation(.easeInOut) {
                                    selectedTag = option
                                    isExpanded = false
                                }
                            } label: {
                                TagCapsule(tag: option, .medium)
                            }
                        }
                        
                        Button {
                            newTagSheetIsPresented.toggle()
                        } label: {
                            Image(systemName: "plus")
                                .accessibilityLabel(Text("Add new tag"))
                        }
                    }
                    .padding(2)
                    .padding(.horizontal, 8)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        Button {
                            withAnimation(.easeInOut) {
                                isExpanded = true
                            }
                        } label: {
                            if selectedTag == nil {
                                Text("Add a Tag")
                            } else {
                                TagCapsule(tag: selectedTag, .medium, aiSuggested: tagIsAISuggested)
                            }
                        }

                        if selectedTag != nil {
                            Button {
                                withAnimation(.easeInOut) {
                                    selectedTag = nil
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                                    .accessibilityLabel(Text("Remove tag"))
                            }
                        }
                    }
                    .padding(2)
                    .containerRelativeFrame(.horizontal)
                }
            }
        }
        .animation(.easeInOut, value: isExpanded)
        .sheet(isPresented: $newTagSheetIsPresented) {
            AddExpenseTagSheet { newTag in
                selectedTag = newTag
                isExpanded = false
            }
        }
    }
}

#Preview {
    @Previewable @State var selectedTag: ExpenseTag? = .dining
    @Previewable @State var noTag: ExpenseTag? = nil
    VStack(spacing: 20) {
        TagPicker(selectedTag: $selectedTag)
        TagPicker(selectedTag: $selectedTag, tagIsAISuggested: true)
    }
    .modelContainer(previewAppContainer)
}

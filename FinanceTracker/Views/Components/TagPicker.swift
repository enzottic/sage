//
//  TagPicker.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/15/25.
//

import SwiftUI
import SwiftData
import SageKit

struct TagPicker: View {
    @Binding var selectedTag: ExpenseTag?
    /// Whether the currently selected tag was suggested by the AI (shows rainbow border).
    var tagIsAISuggested: Bool = false

    @State private var newTagSheetIsPresented: Bool = false
    @Namespace private var tagNamespace

    @Query(sort: \ExpenseTag.name) var expenseTags: [ExpenseTag]

    var body: some View {
        ZStack(alignment: .leading) {
            if let selectedTag {
                // A tag is selected — show just that tag with a deselect button
                HStack(spacing: 6) {
                    TagCapsule(tag: selectedTag, .medium, aiSuggested: tagIsAISuggested)
                        .matchedGeometryEffect(id: selectedTag.persistentModelID, in: tagNamespace)
                    Button {
                        withAnimation(.spring(duration: 0.35)) {
                            self.selectedTag = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .accessibilityLabel(Text("Remove tag"))
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
            } else {
                // No tag selected — show all tags
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .center, spacing: 10) {
                        ForEach(expenseTags, id: \.self) { option in
                            Button {
                                withAnimation(.spring(duration: 0.35)) {
                                    selectedTag = option
                                }
                            } label: {
                                TagCapsule(tag: option, .medium)
                                    .matchedGeometryEffect(id: option.persistentModelID, in: tagNamespace)
                            }
                            .buttonStyle(.plain)
                        }

                        Button {
                            newTagSheetIsPresented.toggle()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("Add")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.sageAccent))
                            .accessibilityLabel(Text("Add new tag"))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 10)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .clipped()
        .padding(.vertical, 2)
        .animation(.spring(duration: 0.35), value: selectedTag == nil)
        .sheet(isPresented: $newTagSheetIsPresented) {
            AddExpenseTagSheet { newTag in
                selectedTag = newTag
            }
        }
    }
}

#Preview {
    @Previewable @State var selectedTag: ExpenseTag? = .dining
    VStack(spacing: 20) {
        TagPicker(selectedTag: $selectedTag)
        Text("Item down here)")
    }
    .environmentInjection()
}

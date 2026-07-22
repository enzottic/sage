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
    @Binding var selectedTags: [ExpenseTag]
    /// IDs of currently-selected tags that were suggested by the AI (shows rainbow border).
    var aiSuggestedTagIDs: Set<UUID> = []

    @State private var newTagSheetIsPresented: Bool = false
    @Namespace private var tagNamespace

    @Query(sort: \ExpenseTag.name) var expenseTags: [ExpenseTag]

    private func isSelected(_ tag: ExpenseTag) -> Bool {
        selectedTags.contains { $0.id == tag.id }
    }

    private func toggle(_ tag: ExpenseTag) {
        if let index = selectedTags.firstIndex(where: { $0.id == tag.id }) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: 10) {
                ForEach(expenseTags, id: \.self) { option in
                    let selected = isSelected(option)
                    Button {
                        withAnimation(.spring(duration: 0.35)) {
                            toggle(option)
                        }
                    } label: {
                        TagCapsule(tag: option, .medium, aiSuggested: aiSuggestedTagIDs.contains(option.id))
                            // Selected chips read at full strength with a ring in the tag's own
                            // colour; unselected ones recede. The ring is drawn inside the
                            // capsule's bounds so it can't be clipped by the scroll view.
                            .opacity(selected ? 1 : 0.4)
                            .overlay {
                                if selected, !aiSuggestedTagIDs.contains(option.id) {
                                    Capsule().strokeBorder(option.color, lineWidth: 2)
                                }
                            }
                            .matchedGeometryEffect(id: option.persistentModelID, in: tagNamespace)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
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
            .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $newTagSheetIsPresented) {
            AddExpenseTagSheet { newTag in
                selectedTags.append(newTag)
            }
        }
    }
}

#Preview {
    @Previewable @State var selectedTags: [ExpenseTag] = [.dining]
    VStack(spacing: 20) {
        TagPicker(selectedTags: $selectedTags)
        Text("Item down here)")
    }
    .environmentInjection()
}

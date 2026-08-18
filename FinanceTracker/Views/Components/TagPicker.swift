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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding var selectedTags: [ExpenseTag]
    /// IDs of currently-selected tags that were suggested by the AI (shows rainbow border).
    var aiSuggestedTagIDs: Set<UUID> = []
    var onInteraction: () -> Void = {}

    @State private var newTagSheetIsPresented: Bool = false

    /// Alphabetical and deliberately never reordered: chips stay put as they're tapped, so
    /// positions are predictable and nothing moves out from under a finger.
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
        // Every tag wraps into view rather than scrolling off the edge, so a selected tag can
        // never end up hidden.
        FlowLayout(spacing: 8, alignment: .leading) {
            ForEach(expenseTags, id: \.self) { option in
                let selected = isSelected(option)
                Button {
                    onInteraction()
                    withAnimation(reduceMotion ? nil : .spring(duration: 0.2)) {
                        toggle(option)
                    }
                } label: {
                    TagCapsule(
                        tag: option,
                        .medium,
                        aiSuggested: aiSuggestedTagIDs.contains(option.id),
                        isSelected: selected
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
                .accessibilityValue(selected ? "Selected" : "Not selected")
            }

            Button {
                onInteraction()
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

//
//  StatsFilterBar.swift
//  FinanceTracker
//
//  Created on 3/13/26.
//

import SwiftUI
import SwiftData
import SageKit

struct StatsFilterBar: View {
    @Environment(\.categoryColors) private var categoryColors
    @Binding var selectedCategory: ExpenseCategory?
    @Binding var selectedTag: ExpenseTag?
    @Query(sort: \ExpenseTag.name) var expenseTags: [ExpenseTag]

    var body: some View {
        HStack(spacing: 8) {
            Menu {
                Picker("Category", selection: $selectedCategory.animation()) {
                    Text("All Categories").tag(nil as ExpenseCategory?)
                    ForEach(ExpenseCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category as ExpenseCategory?)
                    }
                }
            } label: {
                menuChip(
                    label: Text(selectedCategory?.rawValue ?? String(localized: "Category")),
                    tint: selectedCategory?.color(in: categoryColors)
                )
            }

            Menu {
                Picker("Tag", selection: $selectedTag.animation()) {
                    Text("All Tags").tag(nil as ExpenseTag?)
                    ForEach(expenseTags, id: \.id) { tag in
                        if !tag.isDeleted {
                            TagMenuLabel(tag: tag).tag(tag as ExpenseTag?)
                        }
                    }
                }
            } label: {
                menuChip(label: tagChipLabel, tint: selectedTagColor)
            }

            Spacer()
        }
    }

    private var tagChipLabel: Text {
        if let tag = selectedTag, !tag.isDeleted {
            return Text(glyph: tag.glyph, name: tag.name)
        }
        return Text(String(localized: "Tag"))
    }

    private var selectedTagColor: Color? {
        guard let tag = selectedTag, !tag.isDeleted else { return nil }
        return tag.color
    }

    private func menuChip(label: Text, tint: Color?) -> some View {
        HStack(spacing: 4) {
            label
                .font(.subheadline)
                .fontWeight(.medium)
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(tint.map { AnyShapeStyle($0.opacity(0.25)) } ?? AnyShapeStyle(.cardBackground)))
        .foregroundStyle(tint ?? .secondary)
    }
}

#Preview {
    @Previewable @State var category: ExpenseCategory? = nil
    @Previewable @State var tag: ExpenseTag? = nil
    StatsFilterBar(selectedCategory: $category, selectedTag: $tag)
        .modelContainer(previewAppContainer)
}
